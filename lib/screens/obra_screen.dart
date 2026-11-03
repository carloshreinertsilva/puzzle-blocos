import 'dart:math';

import 'package:flutter/material.dart';

import '../ads/ad_service.dart';
import '../core/blueprint.dart';
import '../core/board.dart';
import '../core/shapes.dart';
import '../core/village.dart';
import '../game/obra_controller.dart';
import '../main.dart';
import '../services/analytics.dart';
import '../testing/test_bridge.dart';
import '../ui/block_painter.dart';
import '../ui/capi.dart';
import '../ui/dica_paga.dart';
import '../ui/palette.dart';
import '../ui/typography.dart';
import '../ui/widgets.dart';
import '../village/scene.dart';

/// A construction puzzle: drag every piece into the blueprint so it is
/// filled exactly. Two uses:
/// * a village item ([item] set): pops `true` once built, so the village
///   can raise it (and take the stars);
/// * the Obras mode ([item] null): numbered obras one after another, each
///   paying up to three stars the first time.
class ObraScreen extends StatefulWidget {
  const ObraScreen({super.key, required this.services, this.item});
  final AppServices services;
  final VillageItem? item;

  @override
  State<ObraScreen> createState() => _ObraScreenState();
}

class _ObraScreenState extends State<ObraScreen>
    with SingleTickerProviderStateMixin {
  late ObraController _obra;
  late int _number;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();
  final _boardKey = GlobalKey();
  final _pieceKeys = <int, GlobalKey>{};
  String? _previousScreen;

  /// Where the dragged piece would go: (piece, row, col, fits).
  (int, int, int, bool)? _preview;
  bool _showCard = false;
  int _starsGained = 0;
  double _boardCell = 30;

  bool get _village => widget.item != null;

  @override
  void initState() {
    super.initState();
    _number = widget.services.store.obraLevel;
    _load();
    if (kTestBridge) {
      _previousScreen = TestBridge.instance.screen;
      TestBridge.instance
        ..screen = 'obra'
        ..obraDrag = _dragPathFor;
    }
  }

  void _load() {
    final item = widget.item;
    final bp = item == null
        ? Blueprints.level(_number)
        : Blueprints.forItem(item.id, item.name, Village.items.indexOf(item));
    _obra = ObraController(bp)..addListener(_changed);
    _pieceKeys.clear();
    _showCard = false;
    _preview = null;
    if (kTestBridge) TestBridge.instance.obra = _obra;
  }

  @override
  void dispose() {
    if (kTestBridge) {
      final bridge = TestBridge.instance;
      if (bridge.screen == 'obra') bridge.screen = _previousScreen ?? 'home';
      if (bridge.obra == _obra) {
        bridge
          ..obra = null
          ..obraDrag = null;
      }
    }
    _obra.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _changed() {
    if (_obra.solved && !_showCard) _finish();
    setState(() {});
  }

  Future<void> _finish() async {
    final store = widget.services.store;
    Analytics.event('obra_end', {
      'obra': _number,
      'stars': _obra.stars,
      'village': _village ? 1 : 0,
    });
    if (!_village) {
      final before = store.obraStars(_number);
      final now = _obra.stars;
      _starsGained = max(0, now - before);
      if (now > before) await store.setObraStars(_number, now);
      await store.addStars(_starsGained);
      if (store.obraLevel == _number) await store.setObraLevel(_number + 1);
    }
    widget.services.feedback.win();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _showCard = true);
  }

  void _next() {
    widget.services.feedback.click();
    _obra.removeListener(_changed);
    _obra.dispose();
    setState(() {
      _number = widget.services.store.obraLevel;
      _load();
    });
  }

  (int, int) _cellAt(Offset global) {
    final box = _boardKey.currentContext!.findRenderObject() as RenderBox;
    final local = box.globalToLocal(global);
    return ((local.dy / _boardCell).round(), (local.dx / _boardCell).round());
  }

  /// Where the finger sits on a dragged piece: under it, centered, so the
  /// piece stays visible above the finger.
  Offset _anchor(Shape s) =>
      Offset(s.cols * _boardCell / 2, s.rows * _boardCell + _boardCell * 0.9);

  /// For browser tests: a pointer path that drops [piece] on its hint (or
  /// solution) spot.
  Map<String, Object?>? _dragPathFor(int piece) {
    final from = _pieceKeys[piece]?.currentContext?.findRenderObject();
    final board = _boardKey.currentContext?.findRenderObject();
    if (from is! RenderBox || board is! RenderBox) return null;
    final (r, c) = _obra.blueprint.solution[piece];
    final start = from.localToGlobal(from.size.center(Offset.zero));
    final target =
        board.localToGlobal(Offset(c * _boardCell, r * _boardCell)) +
        _anchor(_obra.blueprint.pieces[piece]);
    return {
      'from': {'x': start.dx, 'y': start.dy},
      'to': {'x': target.dx, 'y': target.dy},
    };
  }

  /// The first hint of each obra is free; the next ones cost stars or a
  /// video, so the drawing can't be finished on hints alone.
  Future<void> _dica() async {
    widget.services.feedback.click();
    if (!_obra.nextHintPaid) {
      _obra.showHint();
      return;
    }
    final pago = await pagarDica(
      context,
      widget.services,
      RewardPlacement.obraHint,
      motivo: 'A dica grátis desta obra já foi.',
    );
    if (pago == null || !mounted) return;
    Analytics.event('obra_dica', {'obra': _number, 'pagamento': pago});
    _obra.showHint();
  }

  @override
  Widget build(BuildContext context) {
    final bp = _obra.blueprint;
    return Scaffold(
      body: DecoratedBox(
        decoration: backgroundGradient,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                    child: Row(
                      children: [
                        RoundIconButton(
                          icon: Icons.arrow_back_rounded,
                          label: 'Voltar',
                          onTap: () => Navigator.of(context).pop(false),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                _village ? 'Obra da vila' : 'Obra $_number',
                                style: displayText(15, color: Palette.textDim),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: OutlinedTitle(bp.name, size: 26),
                              ),
                            ],
                          ),
                        ),
                        RoundIconButton(
                          icon: Icons.lightbulb_rounded,
                          label: 'Dica',
                          onTap: _dica,
                        ),
                        const SizedBox(width: 8),
                        RoundIconButton(
                          icon: Icons.refresh_rounded,
                          label: 'Recomeçar',
                          onTap: () {
                            widget.services.feedback.click();
                            _obra.restart();
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: LayoutBuilder(builder: _body)),
                ],
              ),
              if (_showCard)
                Positioned.fill(
                  child: Container(
                    color: const Color(0x99080A20),
                    alignment: Alignment.center,
                    child: _card(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, BoxConstraints box) {
    final width = min(box.maxWidth, 440.0);
    final side = min(width - 32, box.maxHeight * 0.47);
    _boardCell = side / Board.size;
    final trayCell = min(_boardCell * 0.55, 28.0);
    return Center(
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            const SizedBox(height: 6),
            _board(side),
            const SizedBox(height: 14),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final i in _obra.unplaced) _trayPiece(i, trayCell),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
              child: CapiSays(
                text: _obra.line,
                mood: _obra.solved ? CapiMood.cheer : CapiMood.point,
                capiSize: 64,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows where [piece] would land with its top-left corner at [topLeft]
  /// (global), or nothing while it is away from the board.
  void _movePreview(int piece, Offset topLeft) {
    final s = _obra.blueprint.pieces[piece];
    final (r, c) = _cellAt(topLeft);
    final near = r > -s.rows && c > -s.cols && r < Board.size && c < Board.size;
    final next = near ? (piece, r, c, _obra.canPlace(piece, r, c)) : null;
    if (next != _preview) setState(() => _preview = next);
  }

  /// Drops [piece] where it is drawn. Uses the piece's position, not the
  /// finger's: the finger sits below the piece, so on the bottom rows it is
  /// already off the board.
  void _drop(int piece, Offset topLeft) {
    final (r, c) = _cellAt(topLeft);
    setState(() => _preview = null);
    if (_obra.place(piece, r, c)) {
      widget.services.feedback.place();
    } else {
      widget.services.feedback.pick();
    }
  }

  Widget _board(double side) => Builder(
    builder: (context) => Semantics(
      label: 'Planta da obra: ${_obra.unplaced.length} peças para encaixar',
      child: GestureDetector(
        onTapUp: (d) {
          final r = (d.localPosition.dy / _boardCell).floor();
          final c = (d.localPosition.dx / _boardCell).floor();
          final piece = _obra.pieceAt(r * Board.size + c);
          if (piece != null) {
            widget.services.feedback.pick();
            _obra.remove(piece);
          }
        },
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) => CustomPaint(
            key: _boardKey,
            size: Size.square(side),
            painter: _BlueprintPainter(
              obra: _obra,
              preview: _preview,
              pulse: _pulse.value,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _trayPiece(int i, double cell) {
    final s = _obra.blueprint.pieces[i];
    final color = _obra.blueprint.colors[i];
    final hinted = _obra.hint?.$1 == i;
    final key = _pieceKeys.putIfAbsent(i, GlobalKey.new);
    Widget view(double c) => CustomPaint(
      size: Size(s.cols * c, s.rows * c),
      painter: _PiecePainter(s, color),
    );
    return Draggable<int>(
      key: key,
      data: i,
      dragAnchorStrategy: (_, _, _) => _anchor(s),
      feedback: view(_boardCell),
      childWhenDragging: Opacity(
        opacity: 0.25,
        child: _slot(view(cell), false),
      ),
      onDragStarted: () => widget.services.feedback.pick(),
      onDragUpdate: (d) => _movePreview(i, d.globalPosition - _anchor(s)),
      onDragEnd: (d) => _drop(i, d.offset),
      child: Semantics(
        label: 'Peça ${i + 1}',
        child: _slot(view(cell), hinted),
      ),
    );
  }

  Widget _slot(Widget piece, bool glow) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Palette.panel.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: glow ? Palette.accent : Palette.panelEdge,
        width: glow ? 3 : 1.5,
      ),
    ),
    child: piece,
  );

  Widget _card() {
    final item = widget.item;
    return CardPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item != null)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.elasticOut,
              builder: (context, v, child) =>
                  Transform.scale(scale: v, child: child),
              child: VillageItemIcon(item: item, size: 140),
            )
          else
            const Capi(size: 84, mood: CapiMood.cheer),
          OutlinedTitle(
            item != null ? 'Obra pronta!' : 'Obra $_number concluída!',
            size: 30,
          ),
          const SizedBox(height: 10),
          if (item == null) ...[
            StarRow(
              filled: [for (var i = 0; i < 3; i++) i < _obra.stars],
              animate: true,
            ),
            const SizedBox(height: 8),
            Text(
              _starsGained > 0
                  ? '+$_starsGained ${_starsGained == 1 ? 'estrela' : 'estrelas'}'
                  : _obra.stars < 3
                  ? 'Sem desfazer nem dica vale 3 estrelas!'
                  : 'Perfeita de novo!',
              style: bodyText(16, color: Palette.textDim, weight: 500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ChunkyButton(
              label: 'Próxima obra',
              icon: Icons.arrow_forward_rounded,
              big: true,
              onTap: _next,
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Menu',
                style: displayText(18, color: Palette.textDim),
              ),
            ),
          ] else ...[
            Text(
              'Agora é só levantar ${item.name.toLowerCase()} na vila.',
              style: bodyText(16, color: Palette.textDim, weight: 500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ChunkyButton(
              label: 'Construir na vila',
              icon: Icons.construction_rounded,
              color: Palette.good,
              textColor: const Color(0xFF0B3B16),
              big: true,
              onTap: () => Navigator.of(context).pop(true),
            ),
          ],
        ],
      ),
    );
  }
}

class _PiecePainter extends CustomPainter {
  _PiecePainter(this.shape, this.color);
  final Shape shape;
  final int color;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / shape.cols;
    for (final (r, c) in shape.cells) {
      BlockPainter.block(
        canvas,
        Rect.fromLTWH(c * cell, r * cell, cell, cell),
        Palette.blocks[color],
      );
    }
  }

  @override
  bool shouldRepaint(_PiecePainter old) =>
      old.shape != shape || old.color != color;
}

/// The blueprint: blue drafting paper with the drawing outlined in white,
/// the pieces already in it, the drop preview and Capi's hint.
class _BlueprintPainter extends CustomPainter {
  _BlueprintPainter({
    required this.obra,
    required this.preview,
    required this.pulse,
  });

  final ObraController obra;
  final (int, int, int, bool)? preview;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / Board.size;
    final bp = obra.blueprint;
    final paper = RRect.fromRectAndRadius(
      (Offset.zero & size).inflate(cell * 0.2),
      Radius.circular(cell * 0.35),
    );
    canvas.drawRRect(
      paper.shift(Offset(0, cell * 0.12)),
      Paint()..color = const Color(0x66000000),
    );
    canvas.drawRRect(
      paper,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [Color(0xFF2A62B0), Color(0xFF173C78)],
        ).createShader(paper.outerRect),
    );
    final grid = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1;
    for (var i = 1; i < Board.size; i++) {
      canvas.drawLine(Offset(i * cell, 0), Offset(i * cell, size.height), grid);
      canvas.drawLine(Offset(0, i * cell), Offset(size.width, i * cell), grid);
    }

    Rect at(int r, int c) => Rect.fromLTWH(c * cell, r * cell, cell, cell);

    // The drawing: pale cells, outlined where it meets the paper.
    final fill = Paint()..color = const Color(0x40CDE8FF);
    for (final i in bp.cells) {
      canvas.drawRect(at(i ~/ Board.size, i % Board.size), fill);
    }
    final edge = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = max(2, cell * 0.08)
      ..strokeCap = StrokeCap.round;
    bool inside(int r, int c) =>
        r >= 0 &&
        c >= 0 &&
        r < Board.size &&
        c < Board.size &&
        bp.cells.contains(r * Board.size + c);
    for (final i in bp.cells) {
      final r = i ~/ Board.size, c = i % Board.size;
      final x = c * cell, y = r * cell;
      if (!inside(r - 1, c)) {
        canvas.drawLine(Offset(x, y), Offset(x + cell, y), edge);
      }
      if (!inside(r + 1, c)) {
        canvas.drawLine(Offset(x, y + cell), Offset(x + cell, y + cell), edge);
      }
      if (!inside(r, c - 1)) {
        canvas.drawLine(Offset(x, y), Offset(x, y + cell), edge);
      }
      if (!inside(r, c + 1)) {
        canvas.drawLine(Offset(x + cell, y), Offset(x + cell, y + cell), edge);
      }
    }

    // Pieces already placed. When the drawing is complete they bounce in a
    // wave.
    for (var i = 0; i < bp.pieces.length; i++) {
      if (obra.placed[i] case (final r0, final c0)) {
        for (final (dr, dc) in bp.pieces[i].cells) {
          var rect = at(r0 + dr, c0 + dc);
          if (obra.solved) {
            final wave = sin((pulse - (r0 + dr + c0 + dc) * 0.06) * 2 * pi);
            rect = rect.translate(0, -max(0.0, wave) * cell * 0.15);
          }
          BlockPainter.block(canvas, rect, Palette.blocks[bp.colors[i]]);
        }
      }
    }

    // Capi's hint: a glowing ghost of the piece where it goes.
    if (obra.hint case (final i, final r0, final c0)) {
      final glow = 0.55 + 0.35 * sin(pulse * 2 * pi);
      for (final (dr, dc) in bp.pieces[i].cells) {
        final rect = RRect.fromRectAndRadius(
          at(r0 + dr, c0 + dc).deflate(cell * 0.08),
          Radius.circular(cell * 0.18),
        );
        canvas.drawRRect(
          rect,
          Paint()
            ..color = const Color(0xFFFFF3B0).withValues(alpha: glow * 0.5),
        );
        canvas.drawRRect(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(2, cell * 0.07)
            ..color = Palette.accent.withValues(alpha: glow),
        );
      }
    }

    if (preview case (final i, final r0, final c0, final ok)) {
      final s = bp.pieces[i];
      for (final (dr, dc) in s.cells) {
        final r = r0 + dr, c = c0 + dc;
        if (r < 0 || c < 0 || r >= Board.size || c >= Board.size) continue;
        final rect = at(r, c);
        if (ok) {
          canvas.saveLayer(rect, Paint()..color = const Color(0x88FFFFFF));
          BlockPainter.block(canvas, rect, Palette.blocks[bp.colors[i]]);
          canvas.restore();
        } else {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              rect.deflate(cell * 0.08),
              Radius.circular(cell * 0.18),
            ),
            Paint()..color = Palette.danger.withValues(alpha: 0.45),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_BlueprintPainter old) => true;
}
