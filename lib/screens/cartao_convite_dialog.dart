import 'dart:math';

import 'package:flutter/material.dart';

import '../core/cartao_convite.dart';
import '../core/convites.dart';
import '../core/wardrobe.dart';
import '../l10n/idioma.dart';
import '../services/progress_store.dart';
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
      'Com seus amigos você ganha {premios}. Cada amigo conta quando chega '
      'à fase {fase}.',
      {
        'premios': _lista([for (final m in Convites.metas) m.texto]),
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

  static String _lista(List<String> itens) => switch (itens.length) {
    0 => '',
    1 => itens.first,
    2 => tr('{a} e {b}', {'a': itens[0], 'b': itens[1]}),
    _ => tr('{a}, {b} e {c}', {
      'a': itens.sublist(0, itens.length - 2).join(', '),
      'b': itens[itens.length - 2],
      'c': itens.last,
    }),
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
                : CustomPaint(
                    painter: CapiPainter(
                      mood: CapiMood.happy,
                      t: 0,
                      hat: const CapiLook().wearing(item).hat,
                      look: const CapiLook().wearing(item),
                    ),
                  ),
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
              const SizedBox(height: 6),
              const Icon(
                Icons.card_giftcard_rounded,
                color: Colors.white,
                size: 48,
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

/// 3. Help the village grow: Capi carrying a block among new friends, with
/// hills and little houses behind, on a blue sky.
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
          child: Capi(
            size: 132,
            mood: CapiMood.carry,
            look: CapiLook(pelagem: pelagem),
          ),
        ),
        const Align(
          alignment: Alignment(0.42, -0.78),
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
      Offset(w * 0.86, h * 0.2),
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

    casa(w * 0.18, h * 0.62, 20, const Color(0xFFFFF4E0));
    casa(w * 0.70, h * 0.6, 24, const Color(0xFFFFE3B3));
    final fundo = Paint()..color = const Color(0xFF8CD867);
    canvas.drawOval(Rect.fromLTWH(-w * 0.2, h * 0.55, w * 0.8, h * 0.7), fundo);
    canvas.drawOval(Rect.fromLTWH(w * 0.4, h * 0.52, w * 0.85, h * 0.7), fundo);
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.82, w, h * 0.18),
      Paint()..color = const Color(0xFF5DBB4A),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
