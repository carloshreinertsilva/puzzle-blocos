import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../ui/blitz_duel_painter.dart';

import '../ads/ad_service.dart';
import '../core/descoberta.dart';
import '../core/duelos.dart';
import '../core/game_session.dart';
import '../core/ranking.dart';
import '../services/avisos.dart';
import '../services/duelos_servidor.dart';
import '../ui/nome_dialog.dart';
import '../ui/placar_duelos.dart';
import '../services/musica.dart';
import '../services/analytics.dart';
import '../services/duelo_link.dart';
import '../core/missions.dart';
import '../l10n/idioma.dart';
import '../game/game_controller.dart';
import '../game/puzzle_game.dart';
import '../main.dart';
import '../testing/test_bridge.dart';
import '../ui/level_text.dart';
import '../ui/capi.dart';
import '../ui/dica_paga.dart';
import '../ui/dobrar_estrelas.dart';
import '../ui/palette.dart';
import '../ui/posicao_ranking.dart';
import '../ui/typography.dart';
import '../core/board.dart';
import '../services/progress_store.dart';
import '../ui/tool_painter.dart';
import '../ui/widgets.dart';
import '../ui/premio.dart';
import '../ui/regras_duelo.dart';
import '../core/level.dart';
import 'loja_sheet.dart';
import 'passe_sheet.dart';

/// "Dobrar com vídeo" at most this many times a day, so watching every
/// video doesn't double the whole star economy.

/// A level, the daily challenge or an endless run. The play area stays
/// clean: a slim HUD on top, the board and the tray. No banners; cards only
/// appear before or after an attempt.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.services,
    required this.mode,
    this.onDone,
    this.replayLevel,
    this.duelSeed,
    this.duelTargetScore,
    this.duelRivalName,
    this.dueloId,
    this.revanche,
  });
  final AppServices services;
  final GameMode mode;
  final int? duelSeed;
  final int? duelTargetScore;
  final String? duelRivalName;

  /// A friend's challenge on the server: the result goes back to them.
  final String? dueloId;

  /// The player's own challenge, which this friend beat: played again on
  /// the same board against the friend's score. Beating it challenges the
  /// friend back (they are told on their phone).
  final ResultadoDuelo? revanche;

  /// An earlier level, played again for its missing stars.
  final int? replayLevel;

  /// Set while onboarding (the tutorial, then the first levels with no
  /// menu): called when this stage is over. There is no way back to a menu
  /// in the meantime.
  final VoidCallback? onDone;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController controller = GameController(
    store: widget.services.store,
    feedback: widget.services.feedback,
    mode: widget.mode,
    replayLevel: widget.replayLevel,
    duelSeed: widget.duelSeed,
    duelTargetScore: widget.duelTargetScore,
    duelRivalName: widget.duelRivalName,
  );
  PuzzleGame? game;
  bool _busy = false;

  /// The tutorial's top bar holds Capi and his speech bubble.
  double get hudHeight => widget.mode == GameMode.tutorial ? 132 : 104;

  bool get _onboarding => widget.onDone != null;

  /// A friend's challenge opens on a card that says who sent it and the
  /// score to beat; the board (and the Blitz clock) waits for "Topar".
  late bool _abertura =
      controller.isChallenge && !_onboarding && widget.revanche == null;

  void _toparDesafio() {
    widget.services.feedback.click();
    Analytics.event('duel_intro', {'aceitou': true});
    setState(() => _abertura = false);
    controller.setPaused(false);
  }

  void _recusarDesafio() {
    Analytics.event('duel_intro', {'aceitou': false});
    _exit();
  }

  /// The score with the friend who sent the challenge, matched by the name
  /// in the link (the link carries no id of theirs).
  PlacarAmigo? _placarComQuemDesafiou() {
    final nome = widget.duelRivalName?.trim().toLowerCase();
    if (nome == null || nome.isEmpty) return null;
    for (final p in Duelos.placar(widget.services.store)) {
      if (p.nome.trim().toLowerCase() == nome) return p;
    }
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    game ??= PuzzleGame(
      controller: controller,
      topInset: MediaQuery.paddingOf(context).top + hudHeight,
      bottomInset: MediaQuery.paddingOf(context).bottom,
    );
  }

  /// The level's three star challenges, shown for a moment when it starts
  /// (and again on a tap on the stars at the top).
  bool _desafios = false;
  Timer? _desafiosTimer;
  GameSession? _desafiosDe;

  /// The stars button at the top: the challenges card grows out of it and
  /// shrinks back into it.
  final _estrelasKey = GlobalKey();

  bool get _comDesafios => widget.mode == GameMode.levels && !_onboarding;

  /// The result card whose video offers were already counted.
  GameSession? _ofertasDe;
  bool _ofertasVistas = false;

  /// Counts the video offers on the result card, once each time it shows.
  void _registrarOfertas() {
    final s = controller.session;
    if (!controller.showOutcome) {
      _ofertasVistas = false;
      return;
    }
    if (_ofertasVistas && identical(_ofertasDe, s)) return;
    _ofertasVistas = true;
    _ofertasDe = s;
    final ads = widget.services.ads;
    final dados = {
      'mode': controller.mode.name,
      'level': controller.level.number,
      'progress': controller.progressPercent,
    };
    if (s.status == SessionStatus.lost &&
        controller.canRevive &&
        !controller.isChallenge &&
        !controller.isDuel &&
        !controller.isBlitz) {
      ads.offered(RewardPlacement.revive, dados);
    }
  }

  /// The result card on screen that can double its stars with a video
  /// (its mode, for the statistics), or null.
  String? get _modoDobrar {
    if (!controller.showOutcome ||
        controller.isChallenge ||
        controller.isDuel) {
      return null;
    }
    final won = controller.session.status == SessionStatus.won;
    if (controller.isBlitz) return 'blitz';
    if (won && controller.level.isDaily) return 'daily';
    if (won && controller.mode == GameMode.levels) return 'levels';
    if (!won && controller.endless) return 'endless';
    return null;
  }

  /// Whether this result's stars can still be doubled with a video: once
  /// per run (a revived or extended run does not double again) and within
  /// the day's limit.
  bool get _podeDobrar =>
      !_dobradoNaPartida &&
      _modoDobrar != null &&
      DobrarEstrelas.pode(widget.services, controller.starsGained);

  /// Whether the doubling offer on the card on screen was counted.
  bool _ofertaDobrarVista = false;

  /// Counts the doubling offer once each time it shows (the Blitz stars
  /// come a moment after its card, so this is checked on every change).
  void _registrarOfertaDobrar() {
    if (!controller.showOutcome) {
      _ofertaDobrarVista = false;
      _dobradasAgora = null;
      return;
    }
    if (_ofertaDobrarVista || !_podeDobrar) return;
    _ofertaDobrarVista = true;
    DobrarEstrelas.oferecer(widget.services, {
      'mode': _modoDobrar!,
      'level': controller.level.number,
      'stars': controller.starsGained,
    });
  }

  /// The match whose result already went back to the friend.
  GameSession? _respondidoDe;
  bool _nomePedido = false;

  /// Shown on the end card once the friend's challenge was answered.
  PlacarAmigo? _placarDuelo;
  bool _duelEnviado = false;

  /// A friend's challenge (with an id on the server) ended: the score goes
  /// back to them, once per attempt (the best one counts).
  void _responderDuelo() {
    final id = widget.dueloId;
    if (id == null || !controller.showOutcome) return;
    if (identical(_respondidoDe, controller.session)) return;
    _respondidoDe = controller.session;
    unawaited(_enviarDuelo(id, controller.session.score));
  }

  Future<void> _enviarDuelo(String id, int pontos) async {
    final store = widget.services.store;
    if (store.rankingNome == null &&
        !_nomePedido &&
        DuelosServidor.atual != null) {
      _nomePedido = true;
      await _pedirNomeDuelo(
        tr(
          '{rival} vai ver o seu resultado com esse nome. É o mesmo nome do '
          'ranking. Pode ser um apelido: não use nome completo nem dados '
          'pessoais.',
          {'rival': widget.duelRivalName ?? tr('Amigo')},
        ),
      );
      if (!mounted) return;
    }
    final r = await DuelosSync.responder(store, id, pontos);
    if (r == null || !mounted) return;
    // A challenge back from this friend comes as a notification.
    unawaited(Avisos.pedirParaDuelos());
    setState(() {
      _duelEnviado = true;
      _placarDuelo = Duelos.contra(store, r.rival);
    });
  }

  Future<void> _pedirNomeDuelo(String texto) async {
    final nome = await showDialog<String>(
      context: context,
      builder: (_) => NomeDialog(titulo: tr('Seu nome no duelo'), texto: texto),
    );
    if (nome != null) await widget.services.store.setRankingNome(nome);
  }

  /// The challenge back went to the friend.
  bool _revancheEnviada = false;
  bool _revancheEnviando = false;

  /// A rematch on the player's own challenge was won: the friend gets the
  /// board back, with the new score to beat.
  void _devolverRevanche() {
    final r = widget.revanche;
    final seed = widget.duelSeed;
    if (r == null || seed == null) return;
    if (!controller.showOutcome || !controller.duelWon) return;
    if (_revancheEnviada || _revancheEnviando) return;
    _revancheEnviando = true;
    unawaited(() async {
      final ok = await DuelosSync.revanche(
        widget.services.store,
        r: r,
        semente: seed,
        blitz: controller.isBlitz,
        pontos: controller.session.score,
      );
      _revancheEnviando = false;
      if (!mounted) return;
      Analytics.event('duel_rematch_sent', {'ok': ok ? 1 : 0});
      if (ok) setState(() => _revancheEnviada = true);
    }());
  }

  void _aoMudar() {
    _registrarOfertas();
    _registrarOfertaDobrar();
    _responderDuelo();
    _devolverRevanche();
    if (!_comDesafios || !controller.playing) return;
    if (identical(_desafiosDe, controller.session)) return;
    _desafiosDe = controller.session;
    // As the level's title ("Fase 12 / Quebre as pedras") fades out.
    _desafiosTimer?.cancel();
    _desafiosTimer = Timer(const Duration(milliseconds: 1500), _verDesafios);
  }

  void _verDesafios() {
    if (!mounted) return;
    _desafiosTimer?.cancel();
    setState(() => _desafios = true);
    // Short: it is read at a glance, and the stars button brings it back.
    _desafiosTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _desafios = false);
    });
  }

  @override
  void initState() {
    super.initState();
    if (_abertura) controller.paused = true;
    controller.addListener(_aoMudar);
    WidgetsBinding.instance.addPostFrameCallback((_) => _aoMudar());
    widget.services.feedback.musica.entrarNoJogo(
      controller.isBlitz ? Trilha.blitz : Trilha.fases,
    );
    // A challenge can be sent from the end of these: signed in by then.
    if (controller.isDuel || controller.isBlitz || controller.isChallenge) {
      unawaited(DuelosSync.preparar());
    }
    if (kTestBridge) {
      TestBridge.instance
        ..screen = 'game'
        ..controller = controller
        ..praises.clear();
    }
  }

  @override
  void dispose() {
    widget.services.feedback.musica.sairDoJogo();
    _desafiosTimer?.cancel();
    controller.removeListener(_aoMudar);
    if (kTestBridge && TestBridge.instance.controller == controller) {
      TestBridge.instance
        ..screen = 'home'
        ..controller = null;
    }
    controller.dispose();
    super.dispose();
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    try {
      await action();
    } finally {
      _busy = false;
    }
  }

  /// Whether this run's stars were already doubled with a video, and how
  /// many the card on screen got (null: none, or another card).
  bool _dobradoNaPartida = false;
  int? _dobradasAgora;

  Future<void> _dobrarEstrelas() => _guard(() async {
    final modo = _modoDobrar;
    final ganhas = controller.starsGained;
    if (modo == null || !_podeDobrar) return;
    final ok = await DobrarEstrelas.dobrar(
      context,
      widget.services,
      ganhas,
      modo: modo,
    );
    if (!ok || !mounted) return;
    setState(() {
      _dobradoNaPartida = true;
      _dobradasAgora = ganhas;
    });
  });

  /// The doubling offer (or what it gave) for the card on screen.
  Widget _botaoDobrar({double espaco = 10}) => BotaoDobrar(
    estrelas: controller.starsGained,
    dobradas: _dobradasAgora,
    onDobrar: _podeDobrar ? _dobrarEstrelas : null,
    espaco: espaco,
  );

  Future<void> _next() => _guard(() async {
    _dobradoNaPartida = false;
    widget.services.feedback.click();
    await widget.services.ads.betweenLevels(context, controller.level.number);
    controller.restart();
  });

  Future<void> _revive() => _guard(() async {
    final ok = await widget.services.ads.rewarded(
      context,
      RewardPlacement.revive,
    );
    if (!ok) return;
    controller.revive();
    widget.services.feedback.praise(2);
    if (mounted) {
      mostrarPremio(
        context,
        tr('Segunda chance liberada!'),
        icon: Icons.favorite_rounded,
      );
    }
  });

  /// Blitz over: a video buys a few more seconds of the same run (on the
  /// web, with no videos, it is simply offered).
  Future<void> _blitzExtraTime() => _guard(() async {
    if (!controller.canBlitzExtraTime) return;
    if (widget.services.ads.hasVideoAds) {
      final ok = await widget.services.ads.rewarded(
        context,
        RewardPlacement.blitzTime,
      );
      if (!ok || !mounted) return;
    }
    controller.addBlitzExtraTime();
    widget.services.feedback.praise(2);
    if (mounted) {
      mostrarPremio(
        context,
        tr('+{n} segundos!', {'n': GameController.blitzExtraSeconds}),
        icon: Icons.timer_rounded,
      );
    }
  });

  /// The hint lamp: this game's free hint first, then a paid one.
  void _pedirDica() {
    if (!controller.playing || controller.activeToolMode != null) return;
    if (controller.showFreeHint()) {
      widget.services.feedback.click();
      Analytics.event('fase_dica', {
        'level': controller.level.number,
        'pagamento': 'gratis',
      });
      return;
    }
    _dicaPaga();
  }

  Future<void> _dicaPaga() => _guard(() async {
    widget.services.feedback.click();
    final pago = await pagarDica(
      context,
      widget.services,
      RewardPlacement.gameHint,
      motivo: tr('A dica grátis desta fase já foi.'),
    );
    if (pago == null || !mounted) return;
    Analytics.event('fase_dica', {
      'level': controller.level.number,
      'pagamento': pago,
    });
    controller.showPaidHint();
  });

  /// The level's star challenges, for a moment at the start: they never
  /// block a touch.
  Widget _desafiosCard() {
    final show =
        _desafios &&
        controller.playing &&
        !controller.showOutcome &&
        controller.intros.isEmpty;
    final n = controller.level.number;
    final bits = controller.liveStarBits;
    return Positioned(
      left: 16,
      right: 16,
      top: MediaQuery.paddingOf(context).top + hudHeight + 6,
      child: IgnorePointer(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          transitionBuilder: (child, animation) => _RumoAsEstrelas(
            animation: animation,
            estrelas: _estrelasKey,
            child: child,
          ),
          child: !show
              ? const SizedBox.shrink()
              : Center(
                  child: Semantics(
                    container: true,
                    liveRegion: true,
                    label: tr('Desafios da fase: {lista}', {
                      'lista': [
                        for (final m in Mission.values) Missions.text(m, n),
                      ].join(', '),
                    }),
                    excludeSemantics: true,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                        decoration: BoxDecoration(
                          color: Palette.panel.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Palette.accent, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Color(0x66000000), blurRadius: 10),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tr('3 estrelas nesta fase'),
                              style: displayText(17, color: Palette.accent),
                            ),
                            const SizedBox(height: 4),
                            for (final m in Mission.values)
                              _MissionLine(
                                text: Missions.text(m, n),
                                done: Missions.has(bits, m),
                                star: true,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  void _openToolsSheet() {
    widget.services.feedback.click();
    if (!controller.toolsAllowed) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'No Duelo não vale usar ferramentas: vence quem joga melhor, '
                'não quem tem mais ferramentas.',
              ),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ToolsSheet(
        controller: controller,
        store: widget.services.store,
        onUseTool: (tool) {
          Navigator.of(context).pop();
          controller.selectTool(tool);
        },
        videoRewards: widget.services.ads.hasVideoAds,
        onRewardTool: (tool) async {
          final ok = await widget.services.ads.rewarded(
            context,
            RewardPlacement.forTool(tool),
          );
          if (ok) {
            await widget.services.store.addTool(tool, 1);
            widget.services.feedback.praise(2);
            if (mounted) {
              mostrarPremio(
                this.context,
                tr('+1 {ferramenta} pelo vídeo!', {'ferramenta': tool.label}),
                icon: Icons.handyman_rounded,
              );
              setState(() {});
            }
          }
        },
        onBuyTool: (tool) async {
          final ok = await widget.services.store.buyToolWithStars(tool);
          if (ok) {
            widget.services.feedback.click();
            if (mounted) setState(() {});
          } else {
            widget.services.feedback.lose();
          }
        },
      ),
    );
  }

  Widget _buildToolModeOverlay() {
    final mode = controller.activeToolMode;
    final g = game;
    if (mode == null || !controller.playing || g == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        if ((mode == CapiTool.hammer || mode == CapiTool.shovel) &&
            g.boardRect != Rect.zero)
          Positioned.fromRect(
            rect: g.boardRect,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: Board.size,
              ),
              itemCount: Board.size * Board.size,
              itemBuilder: (context, idx) {
                final r = idx ~/ Board.size;
                final c = idx % Board.size;
                final cell = controller.session.board.at(r, c);
                final canTarget = mode == CapiTool.hammer
                    ? cell.isFilled
                    : true;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (mode == CapiTool.hammer) {
                      controller.executeHammer(r, c);
                    } else if (mode == CapiTool.shovel) {
                      controller.executeShovel(r, c);
                    }
                  },
                  child: Semantics(
                    button: true,
                    label: mode == CapiTool.hammer
                        ? tr('Quebrar célula {r} {c}', {'r': r, 'c': c})
                        : tr('Limpar área 3x3 {r} {c}', {'r': r, 'c': c}),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: canTarget
                              ? (mode == CapiTool.hammer
                                    ? const Color(0x66FFD95A)
                                    : const Color(0x66339AF0))
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        if (mode == CapiTool.rotate)
          for (var i = 0; i < 3; i++)
            if (i < g.trays.length)
              Positioned(
                left: g.trays[i].position.x,
                top: g.trays[i].position.y,
                width: g.trays[i].size.x,
                height: g.trays[i].size.y,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => controller.executeRotate(i),
                  child: Semantics(
                    button: true,
                    label: tr('Girar peça {n}', {'n': i}),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + hudHeight + 4,
          left: 14,
          right: 14,
          child: _ActiveToolBanner(
            tool: mode,
            onCancel: controller.cancelToolMode,
          ),
        ),
      ],
    );
  }

  void _retry() {
    _dobradoNaPartida = false;
    widget.services.feedback.click();
    controller.restart();
  }

  /// Fingers on the board right now, seen straight from Flutter (not
  /// through Flame's drag events, which is what can go missing).
  final _dedos = <int>{};

  void _dedoDesceu(PointerDownEvent e) {
    // A fresh touch with no other finger down: any drag still going is
    // left over from a lift the game never heard about.
    if (_dedos.isEmpty) _destravar('toque');
    _dedos.add(e.pointer);
  }

  void _dedoSubiu(PointerEvent e) {
    _dedos.remove(e.pointer);
    if (_dedos.isNotEmpty) return;
    // Flame ends the drag right after this listener, in the same event:
    // check once it had its turn.
    scheduleMicrotask(() {
      if (mounted && _dedos.isEmpty) _destravar('soltou');
    });
  }

  void _destravar(String quando) {
    if (game?.soltarArrastoPreso() ?? false) {
      Analytics.event('drag_stuck', {
        'quando': quando,
        'mode': controller.mode.name,
        'level': controller.level.number,
      });
    }
  }

  void _exit() {
    widget.services.feedback.click();
    Navigator.of(context).pop();
  }

  /// A shortcut on the end-of-level card: the Passe and the shop open over
  /// the card; a game mode goes back to the menu, which opens it.
  Future<void> _atalho(Atalho a) => _guard(() async {
    widget.services.feedback.click();
    Analytics.event('fim_fase_atalho', {
      'destino': a.name,
      'level': controller.level.number,
    });
    switch (a) {
      case Atalho.passe:
        await showPasse(context, widget.services);
      case Atalho.loja:
        await showLoja(context, widget.services);
      default:
        Navigator.of(context).pop(a);
        return;
    }
    if (mounted) setState(() {});
  });

  /// On the phone: the share sheet (WhatsApp & co.). On the web: copies
  /// the link.
  Future<void> _shareDuelLink(int score) async {
    widget.services.feedback.click();
    final store = widget.services.store;
    if (store.rankingNome == null &&
        !_nomePedido &&
        DuelosServidor.atual != null) {
      _nomePedido = true;
      await _pedirNomeDuelo(
        tr(
          'Seu amigo vê esse nome no desafio, e você fica sabendo se ele '
          'passou a sua pontuação. É o mesmo nome do ranking. Pode ser um '
          'apelido: não use nome completo nem dados pessoais.',
        ),
      );
      if (!mounted) return;
    }
    final simples = DueloConvite(
      semente:
          controller.level.seed ??
          (DateTime.now().millisecondsSinceEpoch % 1000000),
      meta: score,
      blitz: controller.isBlitz,
    );
    // With an id on the server, the friend's result comes back.
    final convite = DuelosSync.criar(store, simples) ?? simples;
    Analytics.event('duel_share', {
      'mode': controller.mode.name,
      'retorno': convite.id != null ? 1 : 0,
    });
    if (!kIsWeb) {
      try {
        await SharePlus.instance.share(
          ShareParams(
            text: convite.mensagem,
            subject: tr('Desafio no CapiBlocks'),
          ),
        );
        // The friend's answer comes back as a notification.
        if (convite.id != null) unawaited(Avisos.pedirParaDuelos());
        return;
      } catch (_) {
        // No share sheet: copy instead.
      }
    }
    await Clipboard.setData(ClipboardData(text: convite.mensagem));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('Desafio copiado! Cole no WhatsApp para um amigo.')),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// The end of a duel: against a friend's score when it came from a
  /// challenge link, else the score just set, ready to send.
  Widget _duelCard(int score) {
    if (!controller.isChallenge) {
      return _DuelMarkCard(
        score: score,
        onShareDuel: () => _shareDuelLink(score),
        onRetry: _retry,
        onExit: _exit,
      );
    }
    return _DuelOutcomeCard(
      won: controller.duelWon,
      score: score,
      rivalScore: controller.duelTargetScore ?? 1000,
      rivalName: controller.duelRivalName ?? tr('Rival'),
      starsGained: controller.starsGained,
      enviado: _duelEnviado || _revancheEnviada,
      aviso: _revancheEnviada
          ? tr('{rival} recebeu o desafio de volta.', {
              'rival': controller.duelRivalName ?? tr('Rival'),
            })
          : null,
      revanche: widget.revanche != null,
      placar:
          _placarDuelo ??
          (widget.revanche == null
              ? null
              : Duelos.contra(widget.services.store, widget.revanche!.rival)),
      onRetry: _retry,
      onExit: _exit,
      onShareDuel: () => _shareDuelLink(score),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: backgroundGradient,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: _dedoDesceu,
              onPointerUp: _dedoSubiu,
              onPointerCancel: _dedoSubiu,
              child: GameWidget(game: game!),
            ),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) => _buildToolModeOverlay(),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: SizedBox(
                  height: hudHeight,
                  child: ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) => controller.tutorial
                        ? _TutorialBar(
                            controller: controller,
                            onSkip: controller.skipTutorial,
                          )
                        : _Hud(
                            controller: controller,
                            onPause: () => controller.setPaused(true),
                            onTools: _openToolsSheet,
                            onDica: _pedirDica,
                            onDesafios: _comDesafios ? _verDesafios : null,
                            estrelasKey: _estrelasKey,
                          ),
                  ),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) => _CapiPopUp(controller: controller),
            ),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) => _desafiosCard(),
            ),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) => _overlay(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overlay() {
    Widget? card;
    final s = controller.session;
    if (_abertura) {
      card = _DuelIntroCard(
        key: const ValueKey('duel-intro'),
        rivalName: widget.duelRivalName,
        target: controller.duelTargetScore ?? 1000,
        blitz: controller.isBlitz,
        placar: _placarComQuemDesafiou(),
        onAccept: _toparDesafio,
        onDecline: _recusarDesafio,
      );
    } else if (controller.tutorialFinished) {
      card = Padding(
        key: const ValueKey('tutorial-done'),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: CapiSays(
            text: controller.capiLine,
            mood: CapiMood.cheer,
            capiSize: 110,
            action: tr('Bora!'),
            onAction: widget.onDone,
          ),
        ),
      );
    } else if (controller.intros.isNotEmpty) {
      card = _IntroCard(
        key: ValueKey(controller.intros.first),
        intro: controller.intros.first,
        onOk: () {
          widget.services.feedback.click();
          controller.dismissIntro();
        },
      );
    } else if (controller.paused) {
      card = _PauseCard(
        level: controller.mode == GameMode.levels
            ? controller.level.number
            : null,
        starBits: controller.previousStarBits,
        onResume: () => controller.setPaused(false),
        onRestart: () {
          controller.setPaused(false);
          _retry();
        },
        onExit: _onboarding ? null : _exit,
      );
    } else if (controller.showOutcome && s.status == SessionStatus.won) {
      if (controller.isChallenge || controller.isDuel) {
        card = _duelCard(s.score);
      } else if (controller.isBlitz) {
        card = _BlitzWinCard(
          score: s.score,
          best: controller.bestScore,
          newBest: controller.newBest,
          starsGained: controller.starsGained,
          onExtraTime: controller.canBlitzExtraTime ? _blitzExtraTime : null,
          videoExtra: widget.services.ads.hasVideoAds,
          dobrar: _botaoDobrar(),
          ranking: PosicaoNoRanking(
            key: ValueKey(s),
            store: widget.services.store,
            quadro: Quadro.blitz,
          ),
          onRetry: _retry,
          onExit: _exit,
          onShareDuel: () => _shareDuelLink(s.score),
        );
      } else {
        card = controller.level.isDaily
            ? _DailyWinCard(
                score: s.score,
                starsGained: controller.starsGained,
                streak: widget.services.store.dailyStreak(controller.today),
                dobrar: _botaoDobrar(),
                onExit: _exit,
              )
            : _WinCard(
                level: controller.level.number,
                score: s.score,
                starBits: controller.starBits | controller.previousStarBits,
                newBits: controller.starBits & ~controller.previousStarBits,
                starsGained: controller.starsGained,
                dobrar: _botaoDobrar(),
                replay: controller.isReplay,
                // Not on the first levels, played back to back: the menu
                // (and everything on it) comes after them.
                liberados: _onboarding || controller.isReplay
                    ? const []
                    : Descoberta.liberadosAoVencer(controller.level.number),
                passe: _onboarding
                    ? null
                    : Descoberta.passe(widget.services.store, DateTime.now()),
                cofrinho: _onboarding || !widget.services.loja.existe
                    ? null
                    : Descoberta.cofrinho(widget.services.store),
                onAtalho: _atalho,
                onNext: _next,
                onRetry: _retry,
                onExit: _onboarding ? null : _exit,
              );
      }
    } else if (controller.showOutcome && s.status == SessionStatus.lost) {
      if (controller.isChallenge || controller.isDuel) {
        card = _duelCard(s.score);
      } else if (controller.isBlitz) {
        card = _BlitzWinCard(
          score: s.score,
          best: controller.bestScore,
          newBest: controller.newBest,
          starsGained: controller.starsGained,
          onExtraTime: controller.canBlitzExtraTime ? _blitzExtraTime : null,
          videoExtra: widget.services.ads.hasVideoAds,
          dobrar: _botaoDobrar(),
          ranking: PosicaoNoRanking(
            key: ValueKey(s),
            store: widget.services.store,
            quadro: Quadro.blitz,
          ),
          onRetry: _retry,
          onExit: _exit,
          onShareDuel: () => _shareDuelLink(s.score),
        );
      } else {
        card = _LoseCard(
          endless: controller.endless,
          starsGained: controller.endless ? controller.starsGained : 0,
          score: s.score,
          best: controller.bestScore,
          newBest: controller.newBest,
          canRevive: controller.canRevive,
          videoRevive: widget.services.ads.hasVideoAds,
          dobrar: controller.endless ? _botaoDobrar(espaco: 8) : null,
          ranking: controller.endless
              ? PosicaoNoRanking(
                  key: ValueKey(s),
                  store: widget.services.store,
                  quadro: Quadro.infinito,
                )
              : null,
          onRevive: _revive,
          onRetry: _retry,
          onExit: _onboarding ? null : _exit,
        );
      }
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(
            begin: 0.85,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
          child: child,
        ),
      ),
      child: card == null
          ? const SizedBox.shrink()
          : Container(
              key: card.key ?? ValueKey(card.runtimeType),
              color: const Color(0x99080A20),
              alignment: Alignment.center,
              child: card,
            ),
    );
  }
}

/// The tutorial's top bar: Capi talking, and a way to skip.
/// Capi pops up from the bottom corner for a moment: cheering big moves,
/// worried when the board fills up, pointing at a hint when the player is
/// stuck. Never blocks touches.
/// The hint lamp, always on the HUD. After a while without a move it
/// pulses, and a little later it opens to ask "want a hint?". It grows
/// inside the HUD, so it never covers the board or the pieces.
class _Lampada extends StatefulWidget {
  const _Lampada({
    required this.pulsando,
    required this.aberta,
    required this.onTap,
  });
  final bool pulsando;
  final bool aberta;
  final VoidCallback onTap;

  @override
  State<_Lampada> createState() => _LampadaState();
}

class _LampadaState extends State<_Lampada>
    with SingleTickerProviderStateMixin {
  late final _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  bool get _chamando => widget.pulsando || widget.aberta;

  @override
  void initState() {
    super.initState();
    if (_chamando) _pulso.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Lampada old) {
    super.didUpdateWidget(old);
    if (_chamando && !_pulso.isAnimating) {
      _pulso.repeat(reverse: true);
    } else if (!_chamando && _pulso.isAnimating) {
      _pulso
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const tinta = Color(0xFF3A2200);
    final cor = _chamando ? tinta : Palette.text;
    return Semantics(
      button: true,
      label: tr('Dica'),
      excludeSemantics: true,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulso,
        builder: (context, child) => Transform.scale(
          scale: 1 + 0.1 * Curves.easeInOut.transform(_pulso.value),
          child: child,
        ),
        child: Material(
          color: _chamando
              ? Palette.accent
              : Palette.panel.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 44,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 44,
                      child: Icon(
                        Icons.lightbulb_rounded,
                        color: cor,
                        size: 24,
                      ),
                    ),
                    if (widget.aberta)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(
                          tr('Quer dica?'),
                          style: displayText(15, color: tinta),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CapiPopUp extends StatelessWidget {
  const _CapiPopUp({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final reaction = controller.capiReaction;
    // A hint is shown on the board by Capi carrying the piece.
    final visible =
        reaction != null &&
        reaction != CapiReaction.hint &&
        !controller.showOutcome &&
        !controller.paused &&
        controller.intros.isEmpty;
    final mood = switch (reaction) {
      CapiReaction.cheer => CapiMood.cheer,
      CapiReaction.worried => CapiMood.worried,
      _ => CapiMood.point,
    };
    return Positioned(
      left: 8,
      right: 8,
      bottom: MediaQuery.paddingOf(context).bottom + 4,
      child: IgnorePointer(
        // Faded out as well as slid down: on phones with a tall bottom bar
        // (iPhone), the slide alone left the top of his helmet showing.
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: Duration(milliseconds: visible ? 120 : 380),
          child: AnimatedSlide(
            offset: visible ? Offset.zero : const Offset(0, 1.3),
            duration: const Duration(milliseconds: 380),
            curve: visible ? Curves.easeOutBack : Curves.easeIn,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: CapiSays(
                  key: ValueKey(controller.capiSeq),
                  text: controller.capiSays,
                  mood: mood,
                  capiSize: 70,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorialBar extends StatelessWidget {
  const _TutorialBar({required this.controller, required this.onSkip});
  final GameController controller;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final finished = controller.tutorialFinished;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Column(
        children: [
          SizedBox(
            height: 22,
            child: finished
                ? null
                : Align(
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      button: true,
                      label: tr('Pular tutorial'),
                      excludeSemantics: true,
                      onTap: onSkip,
                      child: GestureDetector(
                        onTap: onSkip,
                        child: Text(
                          tr('Pular'),
                          style: displayText(16, color: Palette.textDim),
                        ),
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              // The closing line shows in the middle of the screen.
              child: finished
                  ? null
                  : CapiSays(
                      text: controller.capiLine,
                      mood: controller.capiCheer
                          ? CapiMood.cheer
                          : CapiMood.happy,
                      capiSize: 84,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({
    required this.controller,
    required this.onPause,
    required this.onTools,
    required this.onDica,
    this.onDesafios,
    this.estrelasKey,
  });
  final GameController controller;
  final VoidCallback onPause;
  final VoidCallback onTools;
  final VoidCallback onDica;

  /// Levels mode: the three star challenges sit by the goals.
  final VoidCallback? onDesafios;
  final Key? estrelasKey;

  @override
  Widget build(BuildContext context) {
    final s = controller.session;
    final level = controller.level;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Column(
        children: [
          Row(
            children: [
              RoundIconButton(
                icon: Icons.pause_rounded,
                label: tr('Pausar'),
                onTap: onPause,
              ),
              Expanded(
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            levelTitle(level),
                            style: displayText(17, color: Palette.textDim),
                          ),
                          if (level.isHard) ...[
                            const SizedBox(width: 8),
                            _Tag(tr('DIFÍCIL'), Palette.danger),
                          ],
                        ],
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _AnimatedScore(score: s.score),
                          if (level.isEndless || controller.isBlitz) ...[
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.emoji_events_rounded,
                              color: Palette.accent,
                              size: 18,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              formatInt(controller.bestScore),
                              style: displayText(15, color: Palette.textDim),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _Lampada(
                pulsando: controller.hintNudge,
                aberta: controller.hintOffer,
                onTap: onDica,
              ),
              const SizedBox(width: 8),
              RoundIconButton(
                icon: Icons.construction_rounded,
                label: tr('Ferramentas'),
                onTap: onTools,
              ),
            ],
          ),
          if (controller.isBlitz) ...[
            const SizedBox(height: 4),
            // Its "+3s" animates for a second after each clear: kept on its
            // own layer so the rest of the screen is not repainted with it.
            RepaintBoundary(
              child: _BlitzTimerChip(
                secondsLeft: controller.blitzSecondsLeft,
                bonus: controller.blitzLastBonus,
                bonusTick: controller.blitzBonusTick,
              ),
            ),
          ],
          if (controller.isChallenge) ...[
            const SizedBox(height: 4),
            _DuelTargetChip(
              score: s.score,
              target: controller.duelTargetScore ?? 1000,
              rivalName: controller.duelRivalName ?? tr('Rival'),
              won: controller.duelWon,
              faltam: s.piecesLeft,
            ),
          ] else if (controller.isDuel) ...[
            const SizedBox(height: 4),
            _PecasRestantes(faltam: s.piecesLeft ?? 0, comDica: true),
          ] else if (!level.isEndless && !controller.isBlitz) ...[
            const SizedBox(height: 6),
            _Goals(
              session: s,
              stars: onDesafios == null
                  ? null
                  : _StarStrip(
                      key: estrelasKey,
                      bits: controller.liveStarBits,
                      onTap: onDesafios!,
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActiveToolBanner extends StatelessWidget {
  const _ActiveToolBanner({required this.tool, required this.onCancel});
  final CapiTool tool;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xF0181F42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Palette.accent, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ToolIcon(tool: tool, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${tool.label}: ${tool.actionPrompt}',
              style: displayText(14, color: Palette.accent),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: tr('Cancelar'),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onCancel,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tr('Cancelar'),
                  style: displayText(13, color: Colors.white70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolsSheet extends StatefulWidget {
  const _ToolsSheet({
    required this.controller,
    required this.store,
    required this.onUseTool,
    required this.onRewardTool,
    required this.onBuyTool,
    this.videoRewards = true,
  });
  final GameController controller;

  /// Offer a free tool for a video (only when real video ads exist).
  final bool videoRewards;
  final ProgressStore store;
  final void Function(CapiTool tool) onUseTool;
  final void Function(CapiTool tool) onRewardTool;
  final void Function(CapiTool tool) onBuyTool;

  @override
  State<_ToolsSheet> createState() => _ToolsSheetState();
}

class _ToolsSheetState extends State<_ToolsSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141938),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0x44FFFFFF), width: 1.5)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const ToolboxIcon(size: 32),
                const SizedBox(width: 10),
                Text(
                  tr('Ferramentas do Capi'),
                  style: displayText(20, color: Palette.text),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x33FFD95A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x66FFD95A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Palette.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.store.stars}',
                        style: displayText(16, color: Palette.accent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: tr('Fechar'),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Palette.textDim,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final tool in CapiTool.values) ...[
              _buildToolCard(tool),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(CapiTool tool) {
    final count = widget.store.toolCount(tool);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2548),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Row(
        children: [
          ToolIcon(tool: tool, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tool.label,
                      style: displayText(16, color: Palette.text),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: count > 0
                            ? const Color(0x33FFD95A)
                            : const Color(0x22FFFFFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'x$count',
                        style: displayText(
                          13,
                          color: count > 0 ? Palette.accent : Palette.textDim,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  tool.description,
                  style: bodyText(12, color: Palette.textDim),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (count > 0)
            Semantics(
              button: true,
              label: tr('Usar {ferramenta}', {'ferramenta': tool.label}),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.accent,
                  foregroundColor: const Color(0xFF3A2414),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => widget.onUseTool(tool),
                child: Text(tr('USAR'), style: displayText(14)),
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.videoRewards) ...[
                  Semantics(
                    button: true,
                    label: tr('Ganhar {ferramenta} com anúncio', {
                      'ferramenta': tool.label,
                    }),
                    child: InkWell(
                      onTap: () async {
                        widget.onRewardTool(tool);
                        setState(() {});
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x3322B8CF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x6622B8CF)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.play_arrow_rounded,
                              color: Color(0xFF22B8CF),
                              size: 16,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              tr('Grátis'),
                              style: const TextStyle(
                                color: Color(0xFF22B8CF),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Semantics(
                  button: true,
                  label: tr('Comprar {ferramenta}', {'ferramenta': tool.label}),
                  child: InkWell(
                    onTap: () async {
                      widget.onBuyTool(tool);
                      setState(() {});
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x33FFD95A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x66FFD95A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Palette.accent,
                            size: 16,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${tool.starCost}',
                            style: const TextStyle(
                              color: Palette.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(text, style: displayText(12, color: Colors.white)),
  );
}

class _AnimatedScore extends StatelessWidget {
  const _AnimatedScore({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: score.toDouble()),
    duration: const Duration(milliseconds: 450),
    curve: Curves.easeOutCubic,
    builder: (context, v, _) => Text(
      formatInt(v.round()),
      style: displayText(38, shadows: textDrop).copyWith(height: 1.05),
    ),
  );
}

class _Goals extends StatelessWidget {
  const _Goals({required this.session, this.stars});
  final GameSession session;
  final Widget? stars;

  @override
  Widget build(BuildContext context) {
    final level = session.level;
    final chips = <Widget>[
      if (level.targetScore > 0)
        _GoalChip(
          icon: const Icon(Icons.star_rounded, color: Palette.accent, size: 20),
          progress: session.score / level.targetScore,
          label: formatInt(level.targetScore),
        ),
      if (level.hasRockGoal)
        _GoalChip(
          icon: const MiniGlyph(MiniIcon.rock, size: 18),
          progress: session.rocksBroken / session.rocksAtStart,
          label: '${session.rocksLeft}',
        ),
      if (level.hasPupGoal)
        _GoalChip(
          icon: const MiniGlyph(MiniIcon.pup, size: 20),
          progress: 1 - session.pupsLeft / level.pupCount,
          label: '${level.pupCount - session.pupsLeft}/${level.pupCount}',
        ),
      if (level.gemsTarget > 0)
        _GoalChip(
          icon: const MiniGlyph(MiniIcon.gem, size: 18),
          progress: session.gems / level.gemsTarget,
          label:
              '${session.gems.clamp(0, level.gemsTarget)}/${level.gemsTarget}',
        ),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final c in chips)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c),
        if (stars case final st?)
          Padding(padding: const EdgeInsets.only(left: 6), child: st),
      ],
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({
    required this.icon,
    required this.progress,
    required this.label,
  });
  final Widget icon;
  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    final done = progress >= 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: Palette.panel.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 6),
          SizedBox(
            width: 52,
            height: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: progress.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 400),
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  backgroundColor: Palette.emptyCell,
                  color: done ? Palette.good : Palette.accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          done
              ? const Icon(
                  Icons.check_circle_rounded,
                  color: Palette.good,
                  size: 18,
                )
              : Text(label, style: displayText(15)),
        ],
      ),
    );
  }
}

TextStyle get _bodyStyle => bodyText(16, color: Palette.textDim, weight: 500);

class _IntroCard extends StatelessWidget {
  const _IntroCard({super.key, required this.intro, required this.onOk});
  final Intro intro;
  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    final (Widget icon, String title, String text) = switch (intro) {
      Intro.rocks => (
        const MiniGlyph(MiniIcon.rock, size: 56),
        tr('Pedras'),
        tr(
          'Complete a linha ou a coluna de uma pedra para quebrá-la. '
          'Quebre todas para vencer a fase.',
        ),
      ),
      Intro.toughRocks => (
        const MiniGlyph(MiniIcon.toughRock, size: 56),
        tr('Pedras reforçadas'),
        tr(
          'As pedras com rebites precisam de duas limpezas: '
          'a primeira só racha.',
        ),
      ),
      Intro.gems => (
        const MiniGlyph(MiniIcon.gem, size: 56),
        tr('Gemas'),
        tr(
          'Algumas peças trazem gemas. Limpe a linha onde elas estão '
          'para coletar.',
        ),
      ),
      Intro.pups => (
        const MiniGlyph(MiniIcon.pup, size: 60),
        tr('Filhotes!'),
        tr(
          'Uns filhotes de capivara ficaram presos nos blocos! Limpe a linha '
          'ou a coluna de cada um para soltar. Eles vão morar na vila.',
        ),
      ),
      Intro.doubleGoal => (
        const Icon(Icons.flag_rounded, color: Palette.accent, size: 56),
        tr('Duas metas'),
        tr(
          'Agora algumas fases pedem duas coisas ao mesmo tempo. '
          'Fique de olho nas metas no topo da tela.',
        ),
      ),
    };
    return CardPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tr('NOVIDADE!'), style: displayText(16, color: Palette.accent)),
          const SizedBox(height: 12),
          icon,
          const SizedBox(height: 12),
          OutlinedTitle(title, size: 30),
          const SizedBox(height: 10),
          Text(text, style: _bodyStyle, textAlign: TextAlign.center),
          const SizedBox(height: 22),
          ChunkyButton(label: tr('Entendi!'), big: true, onTap: onOk),
        ],
      ),
    );
  }
}

class _WinCard extends StatelessWidget {
  const _WinCard({
    required this.level,
    required this.score,
    required this.starBits,
    required this.newBits,
    required this.starsGained,
    required this.replay,
    required this.onNext,
    required this.onRetry,
    required this.onExit,
    this.dobrar,
    this.liberados = const [],
    this.passe,
    this.cofrinho,
    this.onAtalho,
  });
  final int level;

  /// Game modes this win opened, each with a button that goes to it.
  final List<Atalho> liberados;

  /// Where the player stands on the Passe do Capi, and the piggy bank once
  /// it is worth breaking: one tappable line each.
  final LinhaPasse? passe;
  final String? cofrinho;
  final void Function(Atalho)? onAtalho;

  bool get _comAtalhos =>
      liberados.isNotEmpty || passe != null || cofrinho != null;

  /// Watch a video to get this win's stars again ([BotaoDobrar]).
  final Widget? dobrar;
  final int score;

  /// Missions done on this level so far, and the ones this win added.
  final int starBits;
  final int newBits;
  final int starsGained;

  /// An earlier level played again: no "next level" from here.
  final bool replay;
  final VoidCallback onNext;
  final VoidCallback onRetry;

  /// Back to the menu (not while the first levels are on rails).
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) => CardPanel(
    // With the shortcuts the card can be taller than a small phone.
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Capi(size: _comAtalhos ? 60 : 84, mood: CapiMood.cheer),
          OutlinedTitle(tr('Fase {n} concluída!', {'n': level}), size: 30),
          const SizedBox(height: 10),
          StarRow(
            filled: [for (var i = 0; i < 3; i++) i < Missions.count(starBits)],
            animate: true,
          ),
          const SizedBox(height: 10),
          for (final m in Mission.values)
            _MissionLine(
              text: Missions.text(m, level),
              done: Missions.has(starBits, m),
              isNew: Missions.has(newBits, m),
            ),
          const SizedBox(height: 6),
          Text(
            starsGained > 0
                ? trN(
                    starsGained,
                    '+{n} estrela · {pontos} pontos',
                    '+{n} estrelas · {pontos} pontos',
                    {'pontos': formatInt(score)},
                  )
                : tr('{pontos} pontos', {'pontos': formatInt(score)}),
            style: _bodyStyle,
          ),
          ?dobrar,
          if (liberados.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ModosLiberados(modos: liberados, onAtalho: onAtalho),
          ],
          if (passe != null) ...[
            const SizedBox(height: 8),
            _AtalhoLinha(
              icon: Icons.military_tech_rounded,
              cor: const Color(0xFFD0A2F7),
              texto: passe!.texto,
              destaque: passe!.prontas > 0,
              onTap: () => onAtalho?.call(Atalho.passe),
            ),
          ],
          if (cofrinho != null) ...[
            const SizedBox(height: 8),
            _AtalhoLinha(
              icon: Icons.savings_rounded,
              cor: Palette.accent,
              texto: cofrinho!,
              destaque: true,
              onTap: () => onAtalho?.call(Atalho.loja),
            ),
          ],
          const SizedBox(height: 18),
          if (replay) ...[
            ChunkyButton(
              label: tr('Jogar de novo'),
              icon: Icons.refresh_rounded,
              big: true,
              onTap: onRetry,
            ),
            TextButton(
              onPressed: onExit,
              child: Text(
                tr('Menu'),
                style: displayText(18, color: Palette.textDim),
              ),
            ),
          ] else ...[
            ChunkyButton(
              label: tr('Próxima fase'),
              icon: Icons.arrow_forward_rounded,
              big: true,
              onTap: onNext,
            ),
            if (onExit != null)
              TextButton(
                onPressed: onExit,
                child: Text(
                  tr('Menu'),
                  style: displayText(18, color: Palette.textDim),
                ),
              ),
          ],
        ],
      ),
    ),
  );
}

IconData _iconeDoAtalho(Atalho a) => switch (a) {
  Atalho.infinito => Icons.all_inclusive_rounded,
  Atalho.obras => Icons.architecture_rounded,
  Atalho.desafioDiario => Icons.calendar_today_rounded,
  Atalho.blitz => Icons.bolt_rounded,
  Atalho.duelo => Icons.sports_kabaddi_rounded,
  Atalho.torre => Icons.layers_rounded,
  Atalho.passe => Icons.military_tech_rounded,
  Atalho.loja => Icons.storefront_rounded,
};

/// "Modo novo liberado!" on the end-of-level card, with a button for each
/// mode this win opened.
class _ModosLiberados extends StatelessWidget {
  const _ModosLiberados({required this.modos, required this.onAtalho});
  final List<Atalho> modos;
  final void Function(Atalho)? onAtalho;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
    decoration: BoxDecoration(
      color: const Color(0x22FFC94D),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Palette.accent, width: 1.5),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_open_rounded,
              color: Palette.accent,
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  modos.length == 1
                      ? tr('Modo novo liberado!')
                      : tr('Modos novos liberados!'),
                  style: displayText(16, color: Palette.accent),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final (i, a) in modos.indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _AtalhoLinha(
                  icon: _iconeDoAtalho(a),
                  cor: Palette.accent,
                  texto: a.nome,
                  rotulo: tr('Conhecer: {modo}', {'modo': a.nome}),
                  destaque: true,
                  onTap: () => onAtalho?.call(a),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

/// One tappable line on the end-of-level card: an icon, what is waiting
/// there and an arrow.
class _AtalhoLinha extends StatelessWidget {
  const _AtalhoLinha({
    required this.icon,
    required this.cor,
    required this.texto,
    required this.onTap,
    this.rotulo,
    this.destaque = false,
  });
  final IconData icon;
  final Color cor;
  final String texto;

  /// What a screen reader says, when it is more than [texto].
  final String? rotulo;

  /// Something is ready there now: brighter.
  final bool destaque;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: rotulo ?? texto,
    excludeSemantics: true,
    onTap: onTap,
    child: Material(
      color: destaque ? const Color(0x33FFFFFF) : const Color(0x1AFFFFFF),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          // 44: the smallest comfortable tap target.
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                Icon(icon, color: cor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    texto,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: bodyText(
                      13,
                      color: destaque ? Palette.text : Palette.textDim,
                      weight: 600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Palette.textDim,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// One of the level's three missions, ticked when done.
class _MissionLine extends StatelessWidget {
  const _MissionLine({
    required this.text,
    required this.done,
    this.isNew = false,
    this.star = false,
  });
  final String text;
  final bool done;
  final bool isNew;

  /// Shows a star instead of a check (before the challenge is won).
  final bool star;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(
          star
              ? (done ? Icons.star_rounded : Icons.star_outline_rounded)
              : done
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked,
          size: 20,
          color: done
              ? (star ? Palette.accent : Palette.good)
              : Palette.textDim,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: bodyText(
              15,
              color: done ? Palette.text : Palette.textDim,
              weight: 500,
            ),
          ),
        ),
        if (isNew) _Tag(tr('NOVA'), Palette.accentDeep),
      ],
    ),
  );
}

class _DailyWinCard extends StatelessWidget {
  const _DailyWinCard({
    required this.score,
    required this.starsGained,
    required this.streak,
    required this.onExit,
    this.dobrar,
  });
  final int score;
  final int starsGained;
  final int streak;
  final VoidCallback onExit;

  /// Double the stars with a video ([BotaoDobrar]).
  final Widget? dobrar;

  @override
  Widget build(BuildContext context) => CabeNaAltura(
    child: CardPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Palette.accentDeep,
            size: 72,
          ),
          OutlinedTitle(tr('Desafio do dia\nconcluído!'), size: 32),
          const SizedBox(height: 8),
          Text(
            streak > 1
                ? tr('{n} dias seguidos!', {'n': streak})
                : tr('Volte amanhã para outro!'),
            style: displayText(20, color: Palette.accent),
          ),
          const SizedBox(height: 4),
          if (starsGained > 0) ...[
            StarRow(filled: const [true, true, true], size: 34, animate: true),
            const SizedBox(height: 4),
            Text(
              tr('+{n} estrelas · {pontos} pontos', {
                'n': starsGained,
                'pontos': formatInt(score),
              }),
              style: _bodyStyle,
            ),
          ] else
            Text(
              tr('{pontos} pontos', {'pontos': formatInt(score)}),
              style: _bodyStyle,
            ),
          ?dobrar,
          const SizedBox(height: 24),
          ChunkyButton(
            label: tr('Voltar ao menu'),
            icon: Icons.home_rounded,
            big: true,
            onTap: onExit,
          ),
        ],
      ),
    ),
  );
}

class _LoseCard extends StatelessWidget {
  const _LoseCard({
    required this.endless,
    required this.starsGained,
    required this.score,
    required this.best,
    required this.newBest,
    required this.canRevive,
    required this.onRevive,
    required this.onRetry,
    required this.onExit,
    this.videoRevive = true,
    this.ranking,
    this.dobrar,
  });

  /// The player's place on the week's board, under the score.
  final Widget? ranking;

  /// Endless: double the run's stars with a video ([BotaoDobrar]).
  final Widget? dobrar;

  final bool endless;

  /// The second chance costs a short video (false: it is simply offered).
  final bool videoRevive;

  /// Endless only: stars this run earned (one per 2,500 points).
  final int starsGained;
  final int score;
  final int best;
  final bool newBest;
  final bool canRevive;
  final VoidCallback onRevive;
  final VoidCallback onRetry;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) => CabeNaAltura(
    child: CardPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Capi(size: 84, mood: newBest ? CapiMood.cheer : CapiMood.sad),
          OutlinedTitle(
            newBest ? tr('Novo recorde!') : tr('Sem espaço!'),
            size: 36,
            colors: newBest
                ? const [Color(0xFFFFFFFF), Color(0xFFFFD43B)]
                : const [Color(0xFFFFFFFF), Color(0xFFFFB3B3)],
          ),
          const SizedBox(height: 8),
          if (starsGained > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Palette.accent,
                    size: 24,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+$starsGained',
                    style: displayText(20, color: Palette.accent),
                  ),
                ],
              ),
            ),
          Text(
            endless
                ? tr('{pontos} pontos · recorde {recorde}', {
                    'pontos': formatInt(score),
                    'recorde': formatInt(best),
                  })
                : tr('Quase lá! Quer mais uma chance?'),
            style: _bodyStyle,
            textAlign: TextAlign.center,
          ),
          ?ranking,
          ?dobrar,
          const SizedBox(height: 24),
          if (canRevive) ...[
            ChunkyButton(
              label: tr('Continuar'),
              icon: videoRevive
                  ? Icons.smart_display_rounded
                  : Icons.play_arrow_rounded,
              color: Palette.good,
              textColor: const Color(0xFF0B3B16),
              big: true,
              onTap: onRevive,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 14),
              child: Text(
                videoRevive
                    ? tr('Assista a um vídeo curto')
                    : tr('Uma chance extra por partida'),
                style: bodyText(13, color: Palette.textDim, weight: 500),
              ),
            ),
          ],
          ChunkyButton(
            label: tr('Jogar de novo'),
            icon: Icons.refresh_rounded,
            color: canRevive ? Palette.panelEdge : Palette.accent,
            textColor: canRevive ? Palette.text : const Color(0xFF3A2200),
            onTap: onRetry,
          ),
          if (onExit != null)
            TextButton(
              onPressed: onExit,
              child: Text(
                tr('Menu'),
                style: displayText(18, color: Palette.textDim),
              ),
            ),
        ],
      ),
    ),
  );
}

class _PauseCard extends StatelessWidget {
  const _PauseCard({
    required this.level,
    required this.starBits,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
  });

  /// Levels mode: the level, whose missions are listed.
  final int? level;
  final int starBits;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) => CardPanel(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedTitle(tr('Pausa'), size: 38),
        if (level case final n?) ...[
          const SizedBox(height: 12),
          Text(
            tr('Desafios da fase'),
            style: displayText(17, color: Palette.accent),
          ),
          const SizedBox(height: 4),
          for (final m in Mission.values)
            _MissionLine(
              text: Missions.text(m, n),
              done: Missions.has(starBits, m),
            ),
        ],
        const SizedBox(height: 24),
        ChunkyButton(
          label: tr('Continuar'),
          icon: Icons.play_arrow_rounded,
          big: true,
          onTap: onResume,
        ),
        const SizedBox(height: 12),
        ChunkyButton(
          label: tr('Reiniciar'),
          icon: Icons.refresh_rounded,
          color: Palette.panelEdge,
          textColor: Palette.text,
          onTap: onRestart,
        ),
        if (onExit != null)
          TextButton(
            onPressed: onExit,
            child: Text(
              tr('Menu'),
              style: displayText(18, color: Palette.textDim),
            ),
          ),
      ],
    ),
  );
}

/// The Blitz clock. When a clear adds time it flashes green and a "+3s"
/// pops out of it, so the player sees what the big move earned.
class _BlitzTimerChip extends StatefulWidget {
  const _BlitzTimerChip({
    required this.secondsLeft,
    this.bonus = 0,
    this.bonusTick = 0,
  });
  final int secondsLeft;

  /// Seconds the last bonus added; [bonusTick] changes with each one.
  final int bonus;
  final int bonusTick;

  @override
  State<_BlitzTimerChip> createState() => _BlitzTimerChipState();
}

class _BlitzTimerChipState extends State<_BlitzTimerChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    value: 1,
  );

  @override
  void didUpdateWidget(_BlitzTimerChip old) {
    super.didUpdateWidget(old);
    if (widget.bonusTick != old.bonusTick && widget.bonus > 0) {
      _anim.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urgent = widget.secondsLeft <= 10;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final t = _anim.value;
        final flash = 1 - t;
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Color.lerp(
                  urgent ? const Color(0x55FA5252) : const Color(0x442A3356),
                  const Color(0x5540C057),
                  flash,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color.lerp(
                    urgent ? const Color(0xFFFA5252) : const Color(0x66FFD43B),
                    Palette.good,
                    flash,
                  )!,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BlitzIcon(size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.secondsLeft}s',
                    style: displayText(
                      16,
                      color: flash > 0.3
                          ? const Color(0xFF8CE99A)
                          : urgent
                          ? const Color(0xFFFF8787)
                          : Palette.accent,
                    ),
                  ),
                ],
              ),
            ),
            if (t < 1)
              Positioned(
                right: -40 - 24 * t,
                top: -2 - 10 * t,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: (1 - t * t).clamp(0.0, 1.0),
                    child: Text(
                      '+${widget.bonus}s',
                      style: displayText(
                        20,
                        color: const Color(0xFF8CE99A),
                        shadows: const [
                          Shadow(
                            color: Color(0xFF0B3B16),
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DuelTargetChip extends StatelessWidget {
  const _DuelTargetChip({
    required this.score,
    required this.target,
    required this.rivalName,
    required this.won,
    this.faltam,
  });
  final int score;
  final int target;
  final String rivalName;
  final bool won;

  /// Pieces left in a classic duel (null in a Blitz one).
  final int? faltam;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: won ? const Color(0x4451CF66) : const Color(0x442A3356),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: won ? const Color(0xFF51CF66) : const Color(0x66339AF0),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DuelIcon(size: 20),
            const SizedBox(width: 8),
            Text(
              won
                  ? tr('SUPEROU {rival}!', {'rival': rivalName.toUpperCase()})
                  : tr('Meta do {rival}: {meta}', {
                      'rival': rivalName,
                      'meta': formatInt(target),
                    }),
              style: displayText(
                14,
                color: won ? const Color(0xFF8CE99A) : Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            if (faltam case final n?)
              _PecasNoChip(faltam: n)
            else
              Text(
                '(${formatInt(score)}/${formatInt(target)})',
                style: displayText(12, color: Palette.textDim),
              ),
          ],
        ),
      ),
    );
  }
}

/// The pieces left, at the end of a friend's duel chip (the score is right
/// above it, so this is what the chip has room for).
class _PecasNoChip extends StatelessWidget {
  const _PecasNoChip({required this.faltam});
  final int faltam;

  @override
  Widget build(BuildContext context) {
    final cor = faltam <= 3 ? Palette.danger : const Color(0xFF74C0FC);
    return Semantics(
      label: faltam == 0
          ? tr('Acabaram as peças')
          : trN(faltam, 'Falta 1 peça', 'Faltam {n} peças'),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 1.5, height: 16, color: const Color(0x66FFFFFF)),
            const SizedBox(width: 8),
            Icon(Icons.extension_rounded, color: cor, size: 16),
            const SizedBox(width: 3),
            Text(
              trN(faltam, '1 peça', '{n} peças'),
              style: displayText(14, color: cor),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlitzWinCard extends StatelessWidget {
  /// The place on the week's board, under the score.
  final Widget? ranking;

  const _BlitzWinCard({
    this.ranking,
    required this.score,
    required this.best,
    required this.newBest,
    required this.starsGained,
    required this.onRetry,
    required this.onExit,
    required this.onShareDuel,
    this.onExtraTime,
    this.videoExtra = true,
    this.dobrar,
  });

  /// Double the run's stars with a video ([BotaoDobrar]).
  final Widget? dobrar;

  final int score;
  final int best;
  final bool newBest;
  final int starsGained;

  /// More seconds for the same run (null: already used, or not offered).
  final VoidCallback? onExtraTime;

  /// The extra seconds cost a short video (false: simply offered).
  final bool videoExtra;
  final VoidCallback onRetry;
  final VoidCallback onExit;
  final VoidCallback onShareDuel;

  @override
  Widget build(BuildContext context) {
    return CabeNaAltura(
      child: CardPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BlitzIcon(size: 72),
            const SizedBox(height: 8),
            OutlinedTitle(
              newBest ? tr('Novo Recorde Blitz!') : tr('Fim do Blitz!'),
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              tr('{pontos} pontos', {'pontos': formatInt(score)}),
              style: displayText(26, color: Palette.accent),
            ),
            if (newBest) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x33FFD95A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Palette.accent),
                ),
                child: Text(
                  tr('MELHOR PLACAR BLITZ!'),
                  style: displayText(12, color: Palette.accent),
                ),
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                tr('Recorde: {pontos} pontos', {'pontos': formatInt(best)}),
                style: bodyText(14, color: Palette.textDim),
              ),
            ],
            ?ranking,
            if (starsGained > 0) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Palette.accent,
                    size: 22,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tr('+{n} estrelas', {'n': starsGained}),
                    style: displayText(16, color: Palette.accent),
                  ),
                ],
              ),
            ],
            ?dobrar,
            const SizedBox(height: 20),
            if (onExtraTime case final extra?) ...[
              ChunkyButton(
                label: tr('+{n} segundos', {
                  'n': GameController.blitzExtraSeconds,
                }),
                icon: videoExtra
                    ? Icons.smart_display_rounded
                    : Icons.timer_rounded,
                color: Palette.good,
                textColor: const Color(0xFF0B3B16),
                big: true,
                onTap: extra,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 14),
                child: Text(
                  videoExtra
                      ? tr('Assista a um vídeo e continue')
                      : tr('Uma vez por partida'),
                  style: bodyText(13, color: Palette.textDim, weight: 500),
                ),
              ),
            ],
            ChunkyButton(
              label: tr('Jogar de novo'),
              icon: Icons.refresh_rounded,
              big: onExtraTime == null,
              color: onExtraTime == null ? Palette.accent : Palette.panelEdge,
              textColor: onExtraTime == null
                  ? const Color(0xFF3A2200)
                  : Palette.text,
              onTap: onRetry,
            ),
            const SizedBox(height: 10),
            ChunkyButton(
              label: tr('Desafiar Amigo'),
              icon: Icons.share_rounded,
              color: const Color(0xFF339AF0),
              textColor: Colors.white,
              onTap: onShareDuel,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onExit,
              child: Text(
                tr('Menu'),
                style: displayText(16, color: Palette.textDim),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Under the score in a duel started from the menu: there is no one to beat
/// yet, so it says what the match is for.
/// How many pieces a Duel has left, with a "make your mark" nudge in a
/// duel started from the menu. Turns red for the last tray.
class _PecasRestantes extends StatelessWidget {
  const _PecasRestantes({required this.faltam, this.comDica = false});
  final int faltam;
  final bool comDica;

  @override
  Widget build(BuildContext context) {
    final fim = faltam <= 3;
    final cor = fim ? Palette.danger : const Color(0xFF339AF0);
    final texto = faltam == 0
        ? tr('Acabaram as peças')
        : trN(faltam, 'Falta 1 peça', 'Faltam {n} peças');
    return Semantics(
      container: true,
      label: tr('{texto} de {total}', {
        'texto': texto,
        'total': LevelConfig.duelPieces,
      }),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0x442A3356),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cor.withValues(alpha: 0.7), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (comDica) ...[
                const DuelIcon(size: 20),
                const SizedBox(width: 8),
              ] else ...[
                Icon(Icons.extension_rounded, color: cor, size: 18),
                const SizedBox(width: 6),
              ],
              Text(
                texto,
                style: displayText(14, color: fim ? cor : Colors.white),
              ),
              const SizedBox(width: 6),
              Text(
                '(${LevelConfig.duelPieces - faltam}/${LevelConfig.duelPieces})',
                style: displayText(12, color: Palette.textDim),
              ),
              if (comDica) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    tr('Faça sua marca!'),
                    style: displayText(13, color: Palette.textDim),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The end of a duel started from the menu: the score just set, and the
/// button that sends this board to a friend.
class _DuelMarkCard extends StatelessWidget {
  const _DuelMarkCard({
    required this.score,
    required this.onShareDuel,
    required this.onRetry,
    required this.onExit,
  });

  final int score;
  final VoidCallback onShareDuel;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return CardPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DuelIcon(size: 72),
          const SizedBox(height: 8),
          OutlinedTitle(tr('Sua marca'), size: 30),
          const SizedBox(height: 4),
          Text(
            tr('{pontos} pontos', {'pontos': formatInt(score)}),
            style: displayText(26, color: Palette.accent),
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              'Mande este tabuleiro para um amigo: ele joga as mesmas {n} '
              'peças e tenta passar você.',
              {'n': LevelConfig.duelPieces},
            ),
            style: bodyText(15, color: Palette.textDim),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ChunkyButton(
            label: tr('Desafiar Amigo'),
            icon: Icons.share_rounded,
            big: true,
            color: const Color(0xFF339AF0),
            textColor: Colors.white,
            onTap: onShareDuel,
          ),
          const SizedBox(height: 10),
          ChunkyButton(
            label: tr('Jogar de novo'),
            icon: Icons.refresh_rounded,
            onTap: onRetry,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onExit,
            child: Text(
              tr('Menu'),
              style: displayText(16, color: Palette.textDim),
            ),
          ),
        ],
      ),
    );
  }
}

/// The end of a friend's challenge: both scores side by side, who won, and
/// the way back at them (send the challenge back, or a rematch on the same
/// board).
/// Before a friend's challenge: who sent it, the score to beat and, when
/// there were duels with them before, the score so far.
class _DuelIntroCard extends StatelessWidget {
  const _DuelIntroCard({
    super.key,
    required this.rivalName,
    required this.target,
    required this.blitz,
    required this.onAccept,
    required this.onDecline,
    this.placar,
  });

  /// Null (or the "Amigo" stand-in) when the link carried no name.
  final String? rivalName;
  final int target;
  final bool blitz;
  final PlacarAmigo? placar;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final nome = rivalName?.trim();
    final semNome = nome == null || nome.isEmpty || nome == tr('Amigo');
    final quem = semNome
        ? tr('Um amigo te desafiou no CapiBlocks.')
        : tr('{rival} te desafiou no CapiBlocks.', {'rival': nome});
    final meta = formatInt(target);
    final p = placar;
    return CardPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          blitz ? const BlitzIcon(size: 64) : const DuelIcon(size: 64),
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: OutlinedTitle(
              tr('Você foi desafiado!'),
              size: 30,
              colors: const [Color(0xFFFFFFFF), Color(0xFFFFD43B)],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            quem,
            style: bodyText(16, color: Palette.text),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Semantics(
            container: true,
            label: tr('Pontuação a bater: {meta}', {'meta': meta}),
            child: ExcludeSemantics(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x33FFD43B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFFD43B),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      tr('Pontuação a bater'),
                      style: bodyText(13, color: Palette.textDim),
                    ),
                    Text(
                      meta,
                      style: displayText(34, color: const Color(0xFFFFE066)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          RegrasDuelo(blitz: blitz, rival: semNome ? null : nome),
          if (p != null && p.duelos > 0) ...[
            const SizedBox(height: 10),
            Text(
              tr('Placar: {placar}', {'placar': textoPlacar(p)}),
              style: displayText(15, color: Palette.text),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),
          ChunkyButton(
            label: tr('Topar o desafio'),
            icon: Icons.play_arrow_rounded,
            big: true,
            onTap: onAccept,
          ),
          TextButton(
            onPressed: onDecline,
            child: Text(
              tr('Agora não'),
              style: displayText(18, color: Palette.textDim),
            ),
          ),
        ],
      ),
    );
  }
}

class _DuelOutcomeCard extends StatelessWidget {
  const _DuelOutcomeCard({
    required this.won,
    required this.score,
    required this.rivalScore,
    required this.rivalName,
    required this.starsGained,
    required this.onRetry,
    required this.onExit,
    required this.onShareDuel,
    this.enviado = false,
    this.aviso,
    this.revanche = false,
    this.placar,
  });

  final bool won;

  /// What the friend was told, when not the plain "will know your result".
  final String? aviso;

  /// A rematch on the player's own challenge: winning sends it back by
  /// itself, so there is no link to share.
  final bool revanche;
  final int score;
  final int rivalScore;
  final String rivalName;
  final int starsGained;

  /// The result went back to the friend who sent the challenge.
  final bool enviado;

  /// Every duel with this friend so far.
  final PlacarAmigo? placar;
  final VoidCallback onRetry;
  final VoidCallback onExit;
  final VoidCallback onShareDuel;

  Widget _placar(String quem, int pontos, bool vencedor) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: vencedor ? const Color(0x3351CF66) : const Color(0x332A3356),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: vencedor ? const Color(0xFF51CF66) : const Color(0x55FFFFFF),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            quem,
            style: bodyText(13, color: Palette.textDim),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            formatInt(pontos),
            style: displayText(
              22,
              color: vencedor ? const Color(0xFF8CE99A) : Colors.white,
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return CardPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DuelIcon(size: 64),
          const SizedBox(height: 8),
          OutlinedTitle(
            won
                ? tr('Você venceu!')
                : tr('{rival} venceu desta vez', {'rival': rivalName}),
            size: 30,
            colors: won
                ? const [Color(0xFFFFFFFF), Color(0xFFFFD43B)]
                : const [Color(0xFFFFFFFF), Color(0xFFFFB3B3)],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _placar(tr('Você'), score, won),
              const SizedBox(width: 8),
              Text('×', style: displayText(20, color: Palette.textDim)),
              const SizedBox(width: 8),
              _placar(rivalName, rivalScore, !won),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            won
                ? tr(
                    'Devolva o desafio: agora é a vez de {rival} passar você.',
                    {'rival': rivalName},
                  )
                : tr(
                    'Faltaram {n} pontos. Mesmo tabuleiro, mais uma tentativa?',
                    {'n': formatInt(rivalScore - score)},
                  ),
            style: bodyText(15, color: Palette.textDim),
            textAlign: TextAlign.center,
          ),
          if (enviado) ...[
            const SizedBox(height: 10),
            PlacarDoAmigo(
              placar: placar,
              aviso:
                  aviso ??
                  tr('{rival} vai saber do seu resultado.', {
                    'rival': rivalName,
                  }),
            ),
          ],
          if (won && starsGained > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Palette.accent, size: 24),
                const SizedBox(width: 4),
                Text(
                  tr('+{n} estrelas', {'n': starsGained}),
                  style: displayText(18, color: Palette.accent),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          if (won && revanche) ...[
            ChunkyButton(
              label: tr('Jogar de novo'),
              icon: Icons.refresh_rounded,
              big: true,
              onTap: onRetry,
            ),
          ] else if (won) ...[
            ChunkyButton(
              label: tr('Devolver o Desafio'),
              icon: Icons.share_rounded,
              big: true,
              color: const Color(0xFF339AF0),
              textColor: Colors.white,
              onTap: onShareDuel,
            ),
            const SizedBox(height: 10),
            ChunkyButton(
              label: tr('Jogar de novo'),
              icon: Icons.refresh_rounded,
              onTap: onRetry,
            ),
          ] else ...[
            ChunkyButton(
              label: tr('Revanche'),
              icon: Icons.refresh_rounded,
              big: true,
              onTap: onRetry,
            ),
            const SizedBox(height: 10),
            ChunkyButton(
              label: tr('Desafiar Amigo'),
              icon: Icons.share_rounded,
              color: const Color(0xFF339AF0),
              textColor: Colors.white,
              onTap: onShareDuel,
            ),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: onExit,
            child: Text(
              tr('Menu'),
              style: displayText(16, color: Palette.textDim),
            ),
          ),
        ],
      ),
    );
  }
}

/// The level's three stars at the top: lit as each challenge is met (the
/// "no second chance" one stays lit until the second chance is used). A tap
/// shows what each one asks.
class _StarStrip extends StatelessWidget {
  const _StarStrip({super.key, required this.bits, required this.onTap});
  final int bits;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: tr('Estrelas da fase: {n} de {total}, ver os desafios', {
      'n': Missions.count(bits),
      'total': Mission.values.length,
    }),
    excludeSemantics: true,
    onTap: onTap,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0x442A3356),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x66FFD43B), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in Mission.values)
              Icon(
                Missions.has(bits, m)
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 20,
                color: Missions.has(bits, m) ? Palette.accent : Palette.textDim,
              ),
          ],
        ),
      ),
    ),
  );
}

/// The challenges card grows out of the stars button at the top and
/// shrinks back into it.
class _RumoAsEstrelas extends StatelessWidget {
  const _RumoAsEstrelas({
    required this.animation,
    required this.estrelas,
    required this.child,
  });

  final Animation<double> animation;
  final GlobalKey estrelas;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final v = Curves.easeInOutCubic.transform(animation.value);
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.08 + 0.92 * v,
            alignment: _alvo(context),
            child: child,
          ),
        );
      },
    );
  }

  /// Where the stars button is, seen from the card (the card is already
  /// laid out once it shrinks away; before that, up and to the right).
  Alignment _alvo(BuildContext context) {
    const padrao = Alignment(0.4, -1.4);
    final alvo = estrelas.currentContext?.findRenderObject();
    final eu = context.findRenderObject();
    if (alvo is! RenderBox || eu is! RenderBox) return padrao;
    if (!alvo.hasSize || !eu.hasSize || !alvo.attached || !eu.attached) {
      return padrao;
    }
    final centro = eu.globalToLocal(
      alvo.localToGlobal(alvo.size.center(Offset.zero)),
    );
    final w = eu.size.width, h = eu.size.height;
    if (w <= 0 || h <= 0) return padrao;
    return Alignment(centro.dx / w * 2 - 1, centro.dy / h * 2 - 1);
  }
}
