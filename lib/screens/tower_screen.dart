import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../ads/ad_service.dart';
import '../core/ranking.dart';
import '../services/analytics.dart';
import '../services/musica.dart';
import '../l10n/idioma.dart';
import '../main.dart';
import '../testing/test_bridge.dart';
import '../tower/roleta.dart';
import '../tower/tower_controller.dart';
import '../ui/capi.dart';
import '../ui/dobrar_estrelas.dart';
import '../ui/menu_widgets.dart';
import '../ui/palette.dart';
import '../ui/posicao_ranking.dart';
import '../ui/premio.dart';
import '../ui/tower_painter.dart';
import '../ui/typography.dart';
import '../ui/widgets.dart';

/// Screen for Capi's Tower stacking game (Step 4).
class TowerScreen extends StatefulWidget {
  const TowerScreen({super.key, required this.services});
  final AppServices services;

  @override
  State<TowerScreen> createState() => _TowerScreenState();
}

class _TowerScreenState extends State<TowerScreen>
    with SingleTickerProviderStateMixin {
  late final TowerController _controller = TowerController(
    store: widget.services.store,
    feedback: widget.services.feedback,
  );

  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  bool _continuing = false;

  @override
  void initState() {
    super.initState();
    TestBridge.instance.screen = 'tower';
    widget.services.feedback.musica.entrarNoJogo(Trilha.fases);
    TestBridge.instance.tower = _controller;

    _ticker = createTicker((elapsed) {
      if (_lastTick == Duration.zero) {
        _lastTick = elapsed;
        return;
      }
      final dt = (elapsed - _lastTick).inMicroseconds / 1000000.0;
      _lastTick = elapsed;
      _controller.tick(dt.clamp(0.001, 0.05));
    })..start();
  }

  @override
  void dispose() {
    widget.services.feedback.musica.sairDoJogo();
    _ticker.dispose();
    if (TestBridge.instance.tower == _controller) {
      TestBridge.instance.tower = null;
      TestBridge.instance.screen = 'home';
    }
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_controller.gameOver) return;
    _controller.place();
  }

  void _retry() {
    widget.services.feedback.click();
    setState(() {
      _lastTick = Duration.zero;
      _ofertaContada = false;
      _ofertaDobrarContada = false;
      _dobradoNaSubida = false;
      _dobradasAgora = null;
      _controller.reset();
    });
  }

  /// The climb's one second chance, after a video. The tap stops the bonus
  /// wheel: where its needle lands is how much the top block grows once the
  /// video was watched to the end. Without that, nothing happens and the
  /// wheel spins again.
  Future<void> _continue() async {
    final c = _controller;
    if (_continuing || !c.canContinue) return;
    final fator = c.stopWheel();
    Analytics.event('tower_wheel', {
      'multiplicador': fator,
      'height': c.floors,
    });
    setState(() => _continuing = true);
    final ok = await widget.services.ads.rewarded(
      context,
      RewardPlacement.revive,
    );
    if (!mounted) return;
    final antes = c.blocks.last;
    setState(() {
      _continuing = false;
      if (ok) {
        _lastTick = Duration.zero;
        _ofertaDobrarContada = false;
        _dobradasAgora = null;
        c.continueClimb(fator);
      } else {
        c.releaseWheel();
      }
    });
    final depois = c.blocks.last;
    if (ok && (depois.dx > antes.dx || depois.dy > antes.dy)) {
      mostrarPremio(
        context,
        tr('Bônus {valor}: bloco maior!', {'valor': _rotulo(fator)}),
        icon: Icons.open_in_full_rounded,
      );
    }
  }

  /// Whether this climb's stars were already doubled with a video (once a
  /// climb), and how many the card on screen got.
  bool _dobradoNaSubida = false;
  int? _dobradasAgora;
  bool _ofertaDobrarContada = false;
  bool _dobrando = false;

  bool get _podeDobrar =>
      !_dobradoNaSubida &&
      DobrarEstrelas.pode(widget.services, _controller.starsGained);

  Future<void> _dobrar() async {
    if (_dobrando || !_podeDobrar) return;
    _dobrando = true;
    final ganhas = _controller.starsGained;
    final ok = await DobrarEstrelas.dobrar(
      context,
      widget.services,
      ganhas,
      modo: 'tower',
    );
    _dobrando = false;
    if (!ok || !mounted) return;
    setState(() {
      _dobradoNaSubida = true;
      _dobradasAgora = ganhas;
    });
  }

  void _exit() {
    widget.services.feedback.click();
    Navigator.of(context).pop();
  }

  /// What the player is climbing toward right now: the record when it is
  /// the next thing up, or else the next zone.
  String? _goal() {
    final c = _controller;
    final floors = c.floors;
    final toRecord = c.recordToBeat > 0 && !c.recordBeaten
        ? c.recordToBeat + 1 - floors
        : null;
    final next = c.nextZone;
    final toZone = next == null ? null : next.floor - floors;
    if (toRecord != null && (toZone == null || toRecord <= toZone)) {
      return trN(
        toRecord,
        'Falta {n} andar para o recorde',
        'Faltam {n} andares para o recorde',
      );
    }
    if (toZone == null) return null;
    return trN(
      toZone,
      'Falta {n} andar para: {zona}',
      'Faltam {n} andares para: {zona}',
      {'zona': tr(next!.name)},
    );
  }

  static const _hudShadow = [
    Shadow(color: Color(0xCC1E1B4B), offset: Offset(0, 3), blurRadius: 0),
    Shadow(color: Color(0x991E1B4B), blurRadius: 8),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151928),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final c = _controller;
          final floors = c.floors;
          final goal = _goal();
          // The card waits for the camera to show the whole tower.
          final showCard = c.gameOver && c.time - c.overAt > 2.1;

          return Stack(
            children: [
              // 1. The world (a tap anywhere places the block)
              Positioned.fill(
                child: Semantics(
                  button: true,
                  label: tr('Colocar Bloco'),
                  onTap: _onTap,
                  child: GestureDetector(
                    onTap: _onTap,
                    behavior: HitTestBehavior.opaque,
                    child: CustomPaint(
                      painter: TowerWorldPainter(controller: c),
                    ),
                  ),
                ),
              ),

              // 2. Top bar
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        label: tr('Voltar'),
                        onTap: _exit,
                      ),
                      const Spacer(),
                      Semantics(
                        label: tr('Recorde {n}', {'n': c.bestHeight}),
                        excludeSemantics: true,
                        child: StatChip(
                          icon: Icons.emoji_events_rounded,
                          color: Palette.accent,
                          value: '${c.bestHeight}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatChip(
                        icon: Icons.star_rounded,
                        color: Palette.accent,
                        value: '${widget.services.store.stars}',
                      ),
                    ],
                  ),
                ),
              ),

              // 3. The floor count, big
              if (!c.gameOver)
                Positioned(
                  top: 14,
                  left: 72,
                  right: 150,
                  child: SafeArea(
                    bottom: false,
                    child: IgnorePointer(
                      child: Semantics(
                        label: trN(floors, '{n} andar', '{n} andares'),
                        excludeSemantics: true,
                        child: Text(
                          '$floors',
                          style: displayText(
                            46,
                            color: Colors.white,
                            shadows: _hudShadow,
                          ).copyWith(height: 1),
                        ),
                      ),
                    ),
                  ),
                ),

              // 4. The zone, the next goal and the streak of perfect floors
              if (!c.gameOver)
                Positioned(
                  top: 66,
                  left: 16,
                  right: 16,
                  child: SafeArea(
                    bottom: false,
                    child: IgnorePointer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(c.zone.name).toUpperCase(),
                            style: displayText(
                              15,
                              color: Colors.white,
                              shadows: _hudShadow,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (goal != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x991E1B4B),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                goal,
                                style: bodyText(13, color: Colors.white),
                              ),
                            ),
                          if (c.combo > 1) ...[
                            const SizedBox(height: 6),
                            _Sequencia(combo: c.combo, fever: c.fever),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

              // 5. How to play, until the first block lands
              if (floors == 0 && !c.gameOver)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 36,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.65 + 0.35 * ((c.time * 2.4) % 2 - 1).abs(),
                      child: Text(
                        tr('Toque para soltar o bloco'),
                        textAlign: TextAlign.center,
                        style: displayText(
                          20,
                          color: Colors.white,
                          shadows: _hudShadow,
                        ),
                      ),
                    ),
                  ),
                ),

              // 6. The end of the climb
              if (showCard)
                Positioned.fill(
                  child: Container(
                    color: const Color(0x73000000),
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.bottomCenter,
                    child: SafeArea(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: CabeNaAltura(child: _fim(floors)),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Whether this fall's "continue" offer was already counted.
  bool _ofertaContada = false;

  Widget _fim(int floors) {
    final c = _controller;
    final video = c.canContinue && widget.services.ads.hasVideoAds;
    if (video && !_ofertaContada) {
      _ofertaContada = true;
      widget.services.ads.offered(RewardPlacement.revive, {
        'mode': 'tower',
        'level': floors,
      });
    }
    final dobrar = _podeDobrar;
    if (dobrar && !_ofertaDobrarContada) {
      _ofertaDobrarContada = true;
      DobrarEstrelas.oferecer(widget.services, {
        'mode': 'tower',
        'level': floors,
        'stars': c.starsGained,
      });
    }
    return CardPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Capi(size: 68, mood: c.isNewBest ? CapiMood.cheer : CapiMood.sad),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: OutlinedTitle(tr('Fim da Subida!'), size: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trN(
                        floors,
                        'Você construiu {n} andar!',
                        'Você construiu {n} andares!',
                      ),
                      style: bodyText(16, color: Colors.white),
                    ),
                    if (c.isNewBest) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD43B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tr('NOVO RECORDE!'),
                          style: displayText(
                            14,
                            color: const Color(0xFF3A2200),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          PosicaoNoRanking(
            key: ValueKey(floors),
            store: widget.services.store,
            quadro: Quadro.torre,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Marca(
                icon: Icons.layers_rounded,
                valor: '$floors',
                nome: tr('Andares'),
              ),
              _Marca(
                icon: Icons.local_fire_department_rounded,
                valor: 'x${c.maxCombo}',
                nome: tr('Sequência'),
              ),
              _Marca(
                icon: Icons.flag_rounded,
                valor: tr(c.zone.name),
                nome: tr('Zona'),
              ),
            ],
          ),
          if (c.starsGained > 0) ...[
            const SizedBox(height: 10),
            Text(
              trN(c.starsGained, '+{n} estrela!', '+{n} estrelas!'),
              style: displayText(16, color: const Color(0xFFFDE047)),
            ),
          ],
          BotaoDobrar(
            estrelas: c.starsGained,
            dobradas: _dobradasAgora,
            onDobrar: dobrar ? _dobrar : null,
            espaco: 8,
          ),
          SizedBox(height: video ? 10 : 16),
          if (video) ...[
            _Roleta(
              angulo: c.wheelAngle,
              fator: c.wheelFactor,
              parada: c.wheelStoppedAt != null,
              rotulo: _rotulo,
              onTap: _continuing ? null : _continue,
            ),
            const SizedBox(height: 6),
            ChunkyButton(
              label: tr('Continuar'),
              semanticLabel: tr('Continuar a subida vendo um vídeo'),
              icon: Icons.play_circle_fill_rounded,
              color: Palette.good,
              textColor: const Color(0xFF0B3B1A),
              onTap: _continuing ? null : _continue,
            ),
            const SizedBox(height: 10),
          ],
          if (video)
            Row(
              children: [
                Expanded(
                  child: ChunkyButton(
                    label: tr('Subir de Novo'),
                    icon: Icons.refresh_rounded,
                    onTap: _retry,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 64,
                  child: ChunkyButton(
                    label: '',
                    semanticLabel: tr('Voltar ao Menu'),
                    icon: Icons.home_rounded,
                    color: Palette.panelEdge,
                    textColor: Colors.white,
                    onTap: _exit,
                  ),
                ),
              ],
            )
          else ...[
            ChunkyButton(
              label: tr('Subir de Novo'),
              icon: Icons.refresh_rounded,
              onTap: _retry,
            ),
            const SizedBox(height: 10),
            ChunkyButton(
              label: tr('Voltar ao Menu'),
              icon: Icons.home_rounded,
              color: Palette.panelEdge,
              textColor: Colors.white,
              onTap: _exit,
            ),
          ],
        ],
      ),
    );
  }

  /// "1,5x" ("1.5x" in English).
  static String _rotulo(double m) =>
      Roleta.rotulo(m, virgula: Lingua.idioma != Idioma.en);
}

/// The bonus wheel over "Continuar": a needle sweeps a half circle of
/// [Roleta.multiplicadores]; a tap (here or on the button) stops it.
class _Roleta extends StatelessWidget {
  const _Roleta({
    required this.angulo,
    required this.fator,
    required this.parada,
    required this.rotulo,
    required this.onTap,
  });
  final double angulo;
  final double fator;
  final bool parada;
  final String Function(double) rotulo;
  final VoidCallback? onTap;

  static const raio = 62.0;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: tr('Roleta do bônus do vídeo'),
    excludeSemantics: true,
    onTap: onTap,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: raio * 2 + 8,
            height: raio + 18,
            child: CustomPaint(
              painter: _RoletaPainter(
                angulo: angulo,
                parada: parada,
                rotulo: rotulo,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              parada
                  ? tr('Bônus: {valor}', {'valor': rotulo(fator)})
                  : tr('Pare a seta: o bloco cresce até 3x'),
              maxLines: 1,
              style: bodyText(
                13,
                color: parada ? Palette.accent : Palette.textDim,
                weight: 600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _RoletaPainter extends CustomPainter {
  _RoletaPainter({
    required this.angulo,
    required this.parada,
    required this.rotulo,
  });
  final double angulo;
  final bool parada;
  final String Function(double) rotulo;

  static const _cores = [
    Color(0xFF64748B),
    Color(0xFF14B8A6),
    Color(0xFFFFD43B),
    Color(0xFF8B5CF6),
    Color(0xFF64748B),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const r = _Roleta.raio;
    final centro = Offset(size.width / 2, size.height - 4);
    final rect = Rect.fromCircle(center: centro, radius: r);
    final escolhido = Roleta.setorEm(angulo / pi);
    for (var i = 0; i < Roleta.multiplicadores.length; i++) {
      final (a, b) = Roleta.limites(i);
      final cor = _cores[i];
      final destaque = parada && i == escolhido;
      canvas.drawArc(
        rect,
        pi + a * pi,
        (b - a) * pi,
        true,
        Paint()
          ..color = destaque
              ? Palette.lighten(cor, 0.25)
              : cor.withValues(alpha: parada ? 0.45 : 0.9),
      );
      canvas.drawArc(
        rect,
        pi + a * pi,
        (b - a) * pi,
        true,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Palette.panel,
      );
      // The label: inside its sector, or over the rim for the narrow 3x.
      final meio = (a + b) / 2 * pi;
      final estreito = b - a < 0.12;
      final dist = estreito ? r + 9 : r * 0.68;
      final p = centro + Offset(-cos(meio) * dist, -sin(meio) * dist);
      final texto = TextPainter(
        text: TextSpan(
          text: rotulo(Roleta.multiplicadores[i]),
          style: displayText(
            estreito ? 13 : 11,
            color: estreito ? Palette.accent : Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      texto.paint(canvas, p - Offset(texto.width / 2, texto.height / 2));
    }
    // The needle.
    final ponta =
        centro + Offset(-cos(angulo) * r * 0.95, -sin(angulo) * r * 0.95);
    canvas.drawLine(
      centro,
      ponta,
      Paint()
        ..color = const Color(0xFF1E1B4B)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      centro,
      ponta,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(centro, 7, Paint()..color = Colors.white);
    canvas.drawCircle(centro, 4, Paint()..color = const Color(0xFF1E1B4B));
  }

  @override
  bool shouldRepaint(_RoletaPainter old) =>
      old.angulo != angulo || old.parada != parada;
}

/// The run of perfect floors; from 3 on, Capi is "on fire".
class _Sequencia extends StatelessWidget {
  const _Sequencia({required this.combo, required this.fever});
  final int combo;
  final bool fever;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: fever
            ? const [Color(0xFFF59E0B), Color(0xFFEF4444)]
            : const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x551E1B4B),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          fever ? Icons.local_fire_department_rounded : Icons.bolt_rounded,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(
          fever
              ? tr('Em chamas! x{n}', {'n': combo})
              : tr('Perfeito! x{n}', {'n': combo}),
          style: displayText(15, color: Colors.white),
        ),
      ],
    ),
  );
}

/// One number of the climb, on the end card.
class _Marca extends StatelessWidget {
  const _Marca({required this.icon, required this.valor, required this.nome});
  final IconData icon;
  final String valor;
  final String nome;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Palette.accent, size: 20),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(valor, style: displayText(17, color: Colors.white)),
          ),
          Text(
            nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: bodyText(12, color: Palette.textDim),
          ),
        ],
      ),
    ),
  );
}
