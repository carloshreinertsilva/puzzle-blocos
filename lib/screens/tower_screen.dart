import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../services/musica.dart';
import '../l10n/idioma.dart';
import '../main.dart';
import '../testing/test_bridge.dart';
import '../tower/tower_controller.dart';
import '../ui/menu_widgets.dart';
import '../ui/palette.dart';
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
      _controller.reset();
    });
  }

  void _exit() {
    widget.services.feedback.click();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151928),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final currentFloors = _controller.blocks.length - 1;

            return Stack(
              children: [
                // 1. World Canvas (clickable to place block)
                Positioned.fill(
                  child: Semantics(
                    button: true,
                    label: tr('Colocar Bloco'),
                    onTap: _onTap,
                    child: GestureDetector(
                      onTap: _onTap,
                      behavior: HitTestBehavior.opaque,
                      child: CustomPaint(
                        painter: TowerWorldPainter(controller: _controller),
                      ),
                    ),
                  ),
                ),

                // 2. Top HUD Bar
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        label: tr('Voltar'),
                        onTap: _exit,
                      ),
                      const SizedBox(width: 12),
                      StatChip(
                        icon: Icons.layers_rounded,
                        color: Palette.accent,
                        value: '$currentFloors',
                      ),
                      const SizedBox(width: 8),
                      StatChip(
                        icon: Icons.emoji_events_rounded,
                        color: Palette.accent,
                        value: '${_controller.bestHeight}',
                      ),
                      const Spacer(),
                      StatChip(
                        icon: Icons.star_rounded,
                        color: Palette.accent,
                        value: '${widget.services.store.stars}',
                      ),
                    ],
                  ),
                ),

                // 3. Combo Indicator
                if (_controller.combo > 1 && !_controller.gameOver)
                  Positioned(
                    top: 76,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66F59E0B),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          tr('Perfeito! x{n}', {'n': _controller.combo}),
                          style: displayText(18, color: Colors.white),
                        ),
                      ),
                    ),
                  ),

                // 4. Game Over Outcome Card
                if (_controller.gameOver)
                  Positioned.fill(
                    child: Container(
                      color: const Color(0x99000000),
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: CardPanel(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const TowerIcon(size: 72),
                                const SizedBox(height: 12),
                                OutlinedTitle(tr('Fim da Subida!')),
                                const SizedBox(height: 8),
                                Text(
                                  trN(
                                    currentFloors,
                                    'Você construiu {n} andar!',
                                    'Você construiu {n} andares!',
                                  ),
                                  style: bodyText(18, color: Colors.white),
                                ),
                                if (_controller.isNewBest) ...[
                                  const SizedBox(height: 8),
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
                                if (_controller.starsGained > 0) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    trN(
                                      _controller.starsGained,
                                      '+{n} estrela!',
                                      '+{n} estrelas!',
                                    ),
                                    style: displayText(
                                      16,
                                      color: const Color(0xFFFDE047),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                ChunkyButton(
                                  label: tr('Subir de Novo'),
                                  icon: Icons.refresh_rounded,
                                  onTap: _retry,
                                ),
                                const SizedBox(height: 12),
                                ChunkyButton(
                                  label: tr('Voltar ao Menu'),
                                  icon: Icons.home_rounded,
                                  onTap: _exit,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
