import 'dart:math';

import 'package:flutter/material.dart';

import '../core/cartao_convite.dart';
import '../core/convites.dart';
import '../core/wardrobe.dart';
import '../l10n/idioma.dart';
import '../services/progress_store.dart';
import '../ui/block_painter.dart';
import '../ui/capi.dart';
import '../ui/palette.dart';
import '../ui/typography.dart';
import '../ui/widgets.dart';

/// Capi asking the player to bring friends (core/cartao_convite.dart): a
/// light card over the menu, with one of three pictures. True when the
/// player chose "Convidar"; "Agora não" or a tap outside give false.
Future<bool> mostrarCartaoConvite(
  BuildContext context,
  ProgressStore store,
  ArteConvite arte,
) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => CartaoConviteDialog(store: store, arte: arte),
  );
  return r == true;
}

class CartaoConviteDialog extends StatelessWidget {
  const CartaoConviteDialog({
    super.key,
    required this.store,
    required this.arte,
  });
  final ProgressStore store;
  final ArteConvite arte;

  String get _titulo => switch (arte) {
    ArteConvite.premios => tr('Convide e ganhe prêmios'),
    ArteConvite.presente => tr('Um presente para o seu amigo'),
    ArteConvite.vila => tr('Ajude a vila do Capi a crescer'),
  };

  String get _texto => switch (arte) {
    ArteConvite.premios => tr(
      'Ganhe {primeiro} já com o primeiro amigo e a {ultimo} com {n}. Conta '
      'quem chegar à fase {fase}.',
      {
        'primeiro': Convites.metas.first.texto,
        'ultimo': Convites.metas.last.texto,
        'n': Convites.metas.last.amigos,
        'fase': Convites.faseQueConta,
      },
    ),
    ArteConvite.presente => tr(
      'Quem entra pelo seu convite ganha {n} estrelas e o {item}.',
      {
        'n': Convites.presenteEstrelas,
        'item': Wardrobe.byId(Convites.itemPresente)!.label,
      },
    ),
    ArteConvite.vila => tr(
      'Chame um amigo para jogar. Quanto mais gente, mais animada fica a '
      'vila!',
    ),
  };

  @override
  Widget build(BuildContext context) {
    // The player's own fur, so the Capi in the picture is theirs.
    final pelagem = CapiLook.of(store).pelagem;
    return Center(
      child: SingleChildScrollView(
        child: Material(
          type: MaterialType.transparency,
          child: CardPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: switch (arte) {
                    ArteConvite.premios => _ArtePremios(pelagem),
                    ArteConvite.presente => _ArtePresente(pelagem),
                    ArteConvite.vila => _ArteVila(pelagem),
                  },
                ),
                const SizedBox(height: 14),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: OutlinedTitle(_titulo, size: 24),
                ),
                const SizedBox(height: 6),
                Text(
                  _texto,
                  textAlign: TextAlign.center,
                  style: bodyText(15, color: Palette.text),
                ),
                const SizedBox(height: 16),
                ChunkyButton(
                  big: true,
                  icon: Icons.share_rounded,
                  label: tr('Convidar'),
                  onTap: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: 10),
                ChunkyButton(
                  label: tr('Agora não'),
                  color: Palette.panelEdge,
                  textColor: Palette.text,
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The frame every picture shares: rounded, with its own background.
class _Moldura extends StatelessWidget {
  const _Moldura({
    required this.cores,
    required this.fundo,
    required this.child,
  });
  final List<Color> cores;
  final CustomPainter fundo;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Container(
      height: 168,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: cores,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: fundo),
          child,
        ],
      ),
    ),
  );
}

CapiLook _vestido(String pelagem, List<String> itens) {
  var look = CapiLook(pelagem: pelagem);
  for (final id in itens) {
    look = look.wearing(Wardrobe.byId(id)!);
  }
  return look;
}

/// 1. What whoever invites gets: Capi cheering with the crown and the sash
/// on, and the steps (friends → prize) beside him, on gold.
class _ArtePremios extends StatelessWidget {
  const _ArtePremios(this.pelagem);
  final String pelagem;

  @override
  Widget build(BuildContext context) {
    final itens = [for (final m in Convites.metas) ?m.item];
    return _Moldura(
      cores: const [Color(0xFFFFD66B), Color(0xFFFF8A3D)],
      fundo: const _Raios(),
      child: Row(
        children: [
          Expanded(
            flex: 11,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Capi(
                size: 150,
                mood: CapiMood.cheer,
                look: _vestido(pelagem, itens),
              ),
            ),
          ),
          Expanded(
            flex: 10,
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final m in Convites.metas) ...[
                    _Degrau(m),
                    const SizedBox(height: 5),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One reward step: the prize and how many friends bring it.
class _Degrau extends StatelessWidget {
  const _Degrau(this.meta);
  final MetaConvite meta;

  @override
  Widget build(BuildContext context) {
    final item = meta.item == null ? null : Wardrobe.byId(meta.item!);
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0x55301600),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item?.raridade.color ?? const Color(0xFFFFF3C4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 34,
            child: item == null
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFF3C4),
                        size: 36,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          '${meta.estrelas}',
                          style: displayText(
                            10,
                            color: const Color(0xFF8A3B00),
                          ),
                        ),
                      ),
                    ],
                  )
                : CustomPaint(painter: _ItemSozinho(item.id)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                trN(meta.amigos, '{n} amigo', '{n} amigos'),
                style: displayText(15, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 2. The friend's gift: the player's Capi pointing at a friend who wears
/// the friendship bow, the gift and its stars between them, on pink.
class _ArtePresente extends StatelessWidget {
  const _ArtePresente(this.pelagem);
  final String pelagem;

  @override
  Widget build(BuildContext context) {
    final amigo = pelagem == 'chocolate' ? 'neve' : 'chocolate';
    return _Moldura(
      cores: const [Color(0xFFFF9EC4), Color(0xFF9B5DE5)],
      fundo: const _Confete(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Capi(
              size: 118,
              mood: CapiMood.point,
              look: CapiLook(pelagem: pelagem),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x66300A40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Palette.accent,
                      size: 20,
                    ),
                    Text(
                      '+${Convites.presenteEstrelas}',
                      style: displayText(16, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const SizedBox(
                width: 62,
                height: 62,
                child: CustomPaint(painter: _Presente()),
              ),
            ],
          ),
          Expanded(
            child: Capi(
              size: 118,
              mood: CapiMood.happy,
              look: _vestido(amigo, [Convites.itemPresente]),
            ),
          ),
        ],
      ),
    );
  }
}

/// 3. Help the village grow: Capi carrying a game block over his head among
/// new friends, with hills and little houses behind, on a blue sky.
class _ArteVila extends StatelessWidget {
  const _ArteVila(this.pelagem);
  final String pelagem;

  @override
  Widget build(BuildContext context) => _Moldura(
    cores: const [Color(0xFF7FD3FF), Color(0xFFCDF3FF)],
    fundo: const _Colinas(),
    child: Stack(
      children: [
        Align(
          alignment: const Alignment(-0.82, 1),
          child: Capi(
            size: 82,
            mood: CapiMood.cheer,
            look: CapiLook(pelagem: pelagem == 'neve' ? 'dourado' : 'neve'),
          ),
        ),
        Align(
          alignment: const Alignment(0.82, 1),
          child: Capi(
            size: 82,
            mood: CapiMood.happy,
            look: CapiLook(
              pelagem: pelagem == 'arco_iris' ? 'galaxia' : 'arco_iris',
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox.square(
            dimension: 132,
            child: Stack(
              children: [
                // Behind him: his hands come in front of it.
                const Positioned.fill(child: CustomPaint(painter: _Bloco())),
                Capi(
                  size: 132,
                  mood: CapiMood.carry,
                  look: CapiLook(pelagem: pelagem),
                ),
              ],
            ),
          ),
        ),
        const Align(
          alignment: Alignment(0.3, -0.84),
          child: Icon(
            Icons.favorite_rounded,
            color: Color(0xFFFF6B8B),
            size: 26,
          ),
        ),
        const Align(
          alignment: Alignment(-0.45, -0.62),
          child: Icon(
            Icons.favorite_rounded,
            color: Color(0xFFFF8FA8),
            size: 18,
          ),
        ),
      ],
    ),
  );
}

/// Sun rays from behind Capi.
class _Raios extends CustomPainter {
  const _Raios();

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width * 0.27, size.height * 0.55);
    final r = size.longestSide;
    final p = Paint()..color = const Color(0x2EFFFFFF);
    const n = 12;
    for (var i = 0; i < n; i++) {
      final a = i * 2 * pi / n;
      final path = Path()
        ..moveTo(centro.dx, centro.dy)
        ..lineTo(centro.dx + r * cos(a - 0.11), centro.dy + r * sin(a - 0.11))
        ..lineTo(centro.dx + r * cos(a + 0.11), centro.dy + r * sin(a + 0.11))
        ..close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Confetti and little hearts.
class _Confete extends CustomPainter {
  const _Confete();

  static const _cores = [
    Color(0xAAFFFFFF),
    Color(0xAAFFE08A),
    Color(0xAA8CF0FF),
    Color(0xAAFFC2D8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(7);
    for (var i = 0; i < 26; i++) {
      final p = Paint()..color = _cores[i % _cores.length];
      final c = Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height * 0.8,
      );
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(rng.nextDouble() * pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, -2, 8, 4),
          const Radius.circular(1.5),
        ),
        p,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A sun, green hills and two little houses of the village.
class _Colinas extends CustomPainter {
  const _Colinas();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(
      Offset(w * 0.9, h * 0.17),
      16,
      Paint()..color = const Color(0xFFFFE066),
    );
    void casa(double x, double base, double lado, Color parede) {
      canvas.drawRect(
        Rect.fromLTWH(x, base - lado, lado, lado),
        Paint()..color = parede,
      );
      canvas.drawPath(
        Path()
          ..moveTo(x - 3, base - lado)
          ..lineTo(x + lado / 2, base - lado * 1.7)
          ..lineTo(x + lado + 3, base - lado)
          ..close(),
        Paint()..color = const Color(0xFFE8590C),
      );
    }

    final fundo = Paint()..color = const Color(0xFF8CD867);
    canvas.drawOval(Rect.fromLTWH(-w * 0.2, h * 0.5, w * 0.8, h * 0.7), fundo);
    canvas.drawOval(Rect.fromLTWH(w * 0.4, h * 0.47, w * 0.85, h * 0.7), fundo);
    // On the hills, clear of the three Capis in front.
    casa(w * 0.05, h * 0.52, 20, const Color(0xFFFFF4E0));
    casa(w * 0.72, h * 0.47, 22, const Color(0xFFFFE3B3));
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.82, w, h * 0.18),
      Paint()..color = const Color(0xFF5DBB4A),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A reward item by itself, drawn like Capi wears it (the same shapes as in
/// ui/capi.dart): the ambassador's sash or the friendship crown.
class _ItemSozinho extends CustomPainter {
  const _ItemSozinho(this.id);
  final String id;

  static final _linha = Paint()
    ..color = const Color(0xAA4A2A12)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..strokeJoin = StrokeJoin.round;

  static Paint _degrade(Rect r, List<Color> cores) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: cores,
    ).createShader(r);

  @override
  void paint(Canvas canvas, Size size) {
    // A 40x40 grid.
    canvas.scale(size.width / 40);
    if (id == 'faixa_embaixador') {
      final faixa = Path()
        ..moveTo(4, 4)
        ..lineTo(13, 4)
        ..lineTo(36, 30)
        ..lineTo(36, 38)
        ..lineTo(30, 38)
        ..lineTo(4, 11)
        ..close();
      const r = Rect.fromLTWH(4, 4, 32, 34);
      canvas.drawPath(
        faixa,
        _degrade(r, const [Color(0xFF74C0FC), Color(0xFF1864AB)]),
      );
      canvas.drawPath(faixa, _linha);
      final selo = Rect.fromCircle(center: const Offset(19, 20), radius: 8);
      canvas.drawOval(
        selo,
        _degrade(selo, const [Color(0xFFFFF3BF), Color(0xFFE0A100)]),
      );
      canvas.drawOval(selo, _linha);
      canvas.drawPath(
        _estrela(const Offset(19, 20), 5.4),
        Paint()..color = Colors.white,
      );
    } else {
      // The friendship crown: a gold band with hearts for points.
      final banda = RRect.fromRectAndRadius(
        const Rect.fromLTWH(3, 22, 34, 11),
        const Radius.circular(3),
      );
      canvas.drawRRect(
        banda,
        _degrade(banda.outerRect, const [Color(0xFFFFF3BF), Color(0xFFE0A100)]),
      );
      canvas.drawRRect(banda, _linha);
      for (final (x, y, r) in [
        (9.0, 17.0, 5.0),
        (20.0, 12.0, 7.0),
        (31.0, 17.0, 5.0),
      ]) {
        final c = _coracao(Offset(x, y), r);
        canvas.drawPath(c, Paint()..color = const Color(0xFFFF6B8A));
        canvas.drawPath(
          c,
          Paint()
            ..color = const Color(0xFFB0124A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
      for (final x in [11.0, 20.0, 29.0]) {
        canvas.drawCircle(Offset(x, 27.5), 2, Paint()..color = Colors.white);
      }
    }
  }

  static Path _estrela(Offset c, double r) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final a = -pi / 2 + i * pi / 5;
      final d = i.isEven ? r : r * 0.45;
      final pt = c + Offset(cos(a) * d, sin(a) * d);
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    return p..close();
  }

  static Path _coracao(Offset c, double r) => Path()
    ..moveTo(c.dx, c.dy + r * 0.9)
    ..cubicTo(
      c.dx - r * 1.4,
      c.dy - r * 0.1,
      c.dx - r * 0.7,
      c.dy - r * 1.1,
      c.dx,
      c.dy - r * 0.35,
    )
    ..cubicTo(
      c.dx + r * 0.7,
      c.dy - r * 1.1,
      c.dx + r * 1.4,
      c.dy - r * 0.1,
      c.dx,
      c.dy + r * 0.9,
    )
    ..close();

  @override
  bool shouldRepaint(covariant _ItemSozinho oldDelegate) =>
      oldDelegate.id != id;
}

/// A wrapped gift: box, lid and a gold ribbon with a bow, a soft shadow
/// underneath and a little shine, to sit with the painted Capis.
class _Presente extends CustomPainter {
  const _Presente();

  @override
  void paint(Canvas canvas, Size size) {
    // A 60x60 grid.
    canvas.scale(size.width / 60);
    canvas.drawOval(
      const Rect.fromLTWH(8, 52, 44, 7),
      Paint()
        ..color = const Color(0x55300A40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    final caixa = RRect.fromRectAndRadius(
      const Rect.fromLTWH(10, 27, 40, 28),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      caixa,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF6B8A), Color(0xFFD6336C)],
        ).createShader(caixa.outerRect),
    );
    final tampa = RRect.fromRectAndRadius(
      const Rect.fromLTWH(7, 19, 46, 11),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      tampa,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF8FAB), Color(0xFFE64980)],
        ).createShader(tampa.outerRect),
    );
    final fita = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFE066), Color(0xFFF59F00)],
      ).createShader(const Rect.fromLTWH(12, 6, 36, 49));
    canvas.drawRect(const Rect.fromLTWH(26, 19, 8, 36), fita);
    // The bow: two loops and a knot.
    for (final lado in [-1.0, 1.0]) {
      final laco = Path()
        ..moveTo(30, 19)
        ..cubicTo(30 + lado * 4, 6, 30 + lado * 18, 8, 30 + lado * 13, 17)
        ..cubicTo(30 + lado * 10, 20, 30 + lado * 4, 20, 30, 19)
        ..close();
      canvas.drawPath(laco, fita);
      canvas.drawPath(
        laco,
        Paint()
          ..color = const Color(0xFFC77700)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    canvas.drawCircle(
      const Offset(30, 19),
      3.6,
      Paint()..color = const Color(0xFFF59F00),
    );
    final contorno = Paint()
      ..color = const Color(0xAA6B0F2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(caixa, contorno);
    canvas.drawRRect(tampa, contorno);
    // Shine on the lid and the box.
    final brilho = Paint()..color = const Color(0x88FFFFFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 21, 12, 3),
        const Radius.circular(1.5),
      ),
      brilho,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(13, 31, 3, 14),
        const Radius.circular(1.5),
      ),
      brilho,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The block Capi carries over his head in the "carrega" pose: four game
/// cells resting on his raised hands (on CapiPainter's 100x100 grid the
/// painted hands are at about x 22 and 78, from y 24 down to 36).
class _Bloco extends CustomPainter {
  const _Bloco();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    // Four cells, wider than the helmet, so both ends show past it.
    const lado = 21.0;
    for (var i = 0; i < 4; i++) {
      BlockPainter.block(
        canvas,
        Rect.fromLTWH(8 + i * lado, 5, lado, lado),
        Palette.blocks[1 + i],
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
