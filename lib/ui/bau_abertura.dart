import 'dart:math';

import 'package:flutter/material.dart';

import '../core/wardrobe.dart';
import '../main.dart';
import 'capi.dart';
import 'palette.dart';
import 'typography.dart';
import 'widgets.dart';

/// Opening the daily chest, with some suspense: Capi (wearing the player's
/// look) walks up to the chest, it shakes harder and harder with light
/// leaking out, the lid bursts open in a flash and the prize rises on Capi.
/// A tap skips to the opening. The chest is free and shows its possible
/// prizes beforehand (nothing paid is random).
Future<void> showBauAbertura(
  BuildContext context,
  AppServices services, {
  required Cosmetic? item,
  required int estrelas,
}) => showGeneralDialog(
  context: context,
  barrierDismissible: false,
  barrierColor: const Color(0xF2070A20),
  transitionDuration: const Duration(milliseconds: 250),
  pageBuilder: (_, _, _) =>
      _BauAbertura(services: services, item: item, estrelas: estrelas),
);

class _BauAbertura extends StatefulWidget {
  const _BauAbertura({
    required this.services,
    required this.item,
    required this.estrelas,
  });

  final AppServices services;
  final Cosmetic? item;
  final int estrelas;

  @override
  State<_BauAbertura> createState() => _BauAberturaState();
}

class _BauAberturaState extends State<_BauAbertura>
    with TickerProviderStateMixin {
  /// 0 → 1: Capi walks in (0–0.3), the chest shakes (0.3–1).
  late final AnimationController _suspense = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward().whenComplete(_abrir);

  /// 0 → 1: the lid flies, the flash, the prize rises.
  late final AnimationController _revela = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  /// Slow turn of the light rays, forever.
  late final AnimationController _raios = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  bool _aberto = false;

  void _abrir() {
    if (_aberto || !mounted) return;
    _aberto = true;
    _suspense.stop();
    widget.services.feedback.praise(4);
    _revela.forward();
    setState(() {});
  }

  @override
  void dispose() {
    _suspense.dispose();
    _revela.dispose();
    _raios.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final look = CapiLook.of(widget.services.store);
    final item = widget.item;
    final cor = item?.raridade.color ?? Palette.accent;

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Semantics(
          button: !_aberto,
          label: _aberto ? null : 'Abrir o baú',
          onTap: _aberto ? null : _abrir,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _abrir,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_suspense, _revela, _raios]),
                    builder: (context, _) {
                      final s = _suspense.value;
                      final r = Curves.easeOut.transform(_revela.value);
                      return LayoutBuilder(
                        builder: (context, box) {
                          final w = min(box.maxWidth, 420.0);
                          final chest = w * 0.42;
                          final center = Offset(
                            box.maxWidth / 2,
                            box.maxHeight * 0.52,
                          );
                          // Capi walks in from the left, then stands by the chest.
                          final walk = Curves.easeOutCubic.transform(
                            (s / 0.3).clamp(0.0, 1.0),
                          );
                          // Capi stops beside the chest, always on screen.
                          final alvo = max(
                            8.0,
                            center.dx - chest * 0.5 - chest * 0.8 * 0.55,
                          );
                          final capiX = -w * 0.3 + (alvo + w * 0.3) * walk;
                          final hop = _aberto
                              ? 0.0
                              : (sin(s * 40) * 4 * (s < 0.3 ? 1 : 0)).abs();
                          // The shake grows towards the opening.
                          final shake = _aberto
                              ? 0.0
                              : pow(((s - 0.3) / 0.7).clamp(0, 1), 2) * 0.12;
                          final tilt = sin(s * 90) * shake;

                          return Stack(
                            children: [
                              // Light rays, only once open.
                              if (_aberto)
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _Raios(
                                      center: center.translate(0, -chest * 0.3),
                                      cor: cor,
                                      giro: _raios.value * 2 * pi,
                                      forca: r,
                                    ),
                                  ),
                                ),
                              // The chest.
                              Positioned(
                                left: center.dx - chest / 2,
                                top: center.dy - chest / 2,
                                width: chest,
                                height: chest,
                                child: Transform.rotate(
                                  angle: tilt,
                                  alignment: Alignment.bottomCenter,
                                  child: CustomPaint(
                                    painter: _Bau(
                                      tampa: _aberto ? r : 0,
                                      brilho: _aberto
                                          ? 1
                                          : ((s - 0.3) / 0.7).clamp(0.0, 1.0),
                                      cor: cor,
                                    ),
                                  ),
                                ),
                              ),
                              // Capi, cheering once it opens.
                              Positioned(
                                left: capiX,
                                top: center.dy - chest * 0.35 - hop,
                                width: chest * 0.8,
                                height: chest * 0.8,
                                child: Opacity(
                                  opacity: _aberto
                                      ? (1 - r).clamp(0.0, 1.0)
                                      : 1,
                                  child: Capi(
                                    size: chest * 0.8,
                                    mood: _aberto
                                        ? CapiMood.cheer
                                        : CapiMood.point,
                                    look: look,
                                  ),
                                ),
                              ),
                              // The prize rises out of the chest.
                              if (_aberto)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  top: center.dy - chest * (0.4 + 1.25 * r),
                                  child: Opacity(
                                    opacity: r,
                                    child: Transform.scale(
                                      scale:
                                          0.4 +
                                          0.6 *
                                              Curves.elasticOut.transform(
                                                _revela.value,
                                              ),
                                      child: Center(
                                        child: SizedBox.square(
                                          dimension: chest * 1.1,
                                          child: CustomPaint(
                                            painter: CapiPainter(
                                              mood: CapiMood.cheer,
                                              t: _raios.value * 4 % 1,
                                              hat: item == null
                                                  ? look.hat
                                                  : look.wearing(item).hat,
                                              look: item == null
                                                  ? look
                                                  : look.wearing(item),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              // Flash at the moment it opens.
                              if (_aberto && _revela.value < 0.35)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: ColoredBox(
                                      color: Colors.white.withValues(
                                        alpha:
                                            (1 - _revela.value / 0.35) * 0.85,
                                      ),
                                    ),
                                  ),
                                ),
                              // Title and result.
                              Positioned(
                                left: 16,
                                right: 16,
                                top: box.maxHeight * 0.08,
                                child: Text(
                                  _aberto ? 'Baú aberto!' : 'Baú do Capi',
                                  textAlign: TextAlign.center,
                                  style: displayText(30, color: Palette.text),
                                ),
                              ),
                              if (!_aberto)
                                Positioned(
                                  left: 16,
                                  right: 16,
                                  bottom: box.maxHeight * 0.1,
                                  child: Text(
                                    'Toque para abrir!',
                                    textAlign: TextAlign.center,
                                    style: bodyText(15, color: Palette.textDim),
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                // The result, outside the per-frame animation so its
                // button stays still (and easy to tap).
                if (_aberto)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.sizeOf(context).height * 0.05,
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _revela,
                        curve: const Interval(0.55, 1),
                      ),
                      child: _Resultado(
                        item: item,
                        estrelas: widget.estrelas,
                        onOk: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Resultado extends StatelessWidget {
  const _Resultado({
    required this.item,
    required this.estrelas,
    required this.onOk,
  });

  final Cosmetic? item;
  final int estrelas;
  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    final it = item;
    final texto = it == null
        ? '+$estrelas estrelas! Você já tem todos os itens do baú.'
        : 'Novo item: ${it.label} (${it.raridade.label}) e +$estrelas estrelas!';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          container: true,
          liveRegion: true,
          label: texto,
          excludeSemantics: true,
          child: Column(
            children: [
              if (it != null) ...[
                Text(
                  it.label,
                  textAlign: TextAlign.center,
                  style: displayText(24, color: Palette.text),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: it.raridade.color.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: it.raridade.color),
                  ),
                  child: Text(
                    it.raridade.label,
                    style: displayText(13, color: it.raridade.color),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                '+$estrelas estrelas',
                style: displayText(18, color: Palette.accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ChunkyButton(label: 'Maravilha!', onTap: onOk),
      ],
    );
  }
}

/// A wooden chest with gold trim; [tampa] (0–1) swings the lid open and
/// [brilho] makes light leak from the gap.
class _Bau extends CustomPainter {
  _Bau({required this.tampa, required this.brilho, required this.cor});

  final double tampa;
  final double brilho;
  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    // Shadow.
    canvas.drawOval(
      const Rect.fromLTWH(14, 88, 72, 8),
      Paint()
        ..color = const Color(0x66000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    // Light from inside.
    if (brilho > 0) {
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(50, 48),
          width: 90 * brilho,
          height: 30 * brilho,
        ),
        Paint()
          ..color = cor.withValues(alpha: 0.55 * brilho)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
    // Body.
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(14, 48, 72, 42),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB0703A), Color(0xFF7A4520)],
        ).createShader(body.outerRect),
    );
    for (final y in [60.0, 74.0]) {
      canvas.drawLine(
        Offset(16, y),
        Offset(84, y),
        Paint()
          ..color = const Color(0x55000000)
          ..strokeWidth = 1,
      );
    }
    final gold = Paint()..color = const Color(0xFFFFC94D);
    for (final x in [14.0, 80.0]) {
      canvas.drawRect(Rect.fromLTWH(x, 48, 6, 42), gold);
    }
    // Lock.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(44, 50, 12, 14),
        const Radius.circular(3),
      ),
      gold,
    );
    canvas.drawCircle(
      const Offset(50, 56),
      2,
      Paint()..color = const Color(0xFF5A3410),
    );

    // Lid, swinging back on its hinge (top back edge).
    canvas.save();
    canvas.translate(50, 48 - tampa * 22);
    canvas.rotate(-tampa * 0.2);
    // Swung back: we see its inside, a little shorter, behind the box.
    canvas.scale(1, 1 - tampa * 0.25);
    final lid = Path()
      ..moveTo(-38, 0)
      ..lineTo(-38, -10)
      ..quadraticBezierTo(0, -30, 38, -10)
      ..lineTo(38, 0)
      ..close();
    canvas.drawPath(
      lid,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC9884A), Color(0xFF8E5326)],
        ).createShader(const Rect.fromLTWH(-38, -30, 76, 30)),
    );
    for (final x in [-38.0, 32.0]) {
      canvas.drawRect(Rect.fromLTWH(x, -22, 6, 22), gold);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Bau old) =>
      old.tampa != tampa || old.brilho != brilho || old.cor != cor;
}

/// Turning light rays behind the prize.
class _Raios extends CustomPainter {
  _Raios({
    required this.center,
    required this.cor,
    required this.giro,
    required this.forca,
  });

  final Offset center;
  final Color cor;
  final double giro;
  final double forca;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.longestSide * 0.8;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          cor.withValues(alpha: 0.55 * forca),
          cor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    for (var i = 0; i < 12; i++) {
      final a = giro + i * pi / 6;
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(center.dx + cos(a - 0.09) * r, center.dy + sin(a - 0.09) * r)
          ..lineTo(center.dx + cos(a + 0.09) * r, center.dy + sin(a + 0.09) * r)
          ..close(),
        paint,
      );
    }
    canvas.drawCircle(
      center,
      60 * forca,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35 * forca)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
  }

  @override
  bool shouldRepaint(_Raios old) => true;
}
