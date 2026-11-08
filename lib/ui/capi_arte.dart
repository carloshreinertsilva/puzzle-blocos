import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/hats.dart';
import 'capi.dart';

/// Capi's painted art (assets/capi/, made by tool/capi_arte.py from the
/// Gemini paintings in art/capi/fontes/): one image per pose and fur, one
/// per wardrobe item, and the pups.
///
/// Images load on first use (the painters fall back to the code-drawn Capi
/// for that frame) and stay cached. Turned on by main(); tests keep the
/// code-drawn Capi.
abstract final class CapiArte {
  static bool ativa = false;

  static final _imagens = <String, ui.Image>{};

  /// Bumped when an image arrives, so still drawings repaint with it.
  static final versao = ValueNotifier(0);
  static final _pedidas = <String>{};

  /// The image at [asset], or null while it loads (or if it is missing).
  static ui.Image? imagem(String asset) {
    if (!ativa) return null;
    final pronta = _imagens[asset];
    if (pronta != null || !_pedidas.add(asset)) return pronta;
    unawaited(_carregar(asset));
    return null;
  }

  static Future<void> _carregar(String asset) async {
    try {
      final dados = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(dados.buffer.asUint8List());
      _imagens[asset] = (await codec.getNextFrame()).image;
      versao.value++;
    } catch (e) {
      debugPrint('Capi: $asset: $e');
    }
  }

  /// Loads what the menu shows first, before it is needed.
  static Future<void> preparar(String pelagem, Iterable<String?> itens) async {
    if (!ativa) return;
    for (final p in PoseArte.todas.values.toSet()) {
      imagem(p.asset(pelagem));
    }
    for (final i in itens) {
      if (i != null) imagem(ItemArte.asset(i));
    }
    imagem(filhote);
  }

  static const filhote = 'assets/capi/filhote.webp';
  static const filhoteDormindo = 'assets/capi/filhote_dormindo.webp';
}

/// A pose painting and where Capi's eyes are in it (source pixels: the
/// midpoint of the pupils and the distance between them; the image's full
/// size). Items and the body scale are measured from the eyes.
class PoseArte {
  const PoseArte(this.nome, this.ex, this.ey, this.d, this.w, this.h);
  final String nome;
  final double ex;
  final double ey;
  final double d;
  final double w;
  final double h;

  static const _feliz = PoseArte('feliz', 699.5, 379.5, 609, 1400, 1640);

  static const todas = {
    CapiMood.happy: _feliz,
    CapiMood.cheer: PoseArte('comemora', 450, 172.5, 289, 895, 936),
    CapiMood.worried: PoseArte('preocupado', 547.5, 395.5, 609, 1098, 1649),
    CapiMood.sad: PoseArte('triste', 279.5, 186, 299.5, 560, 812),
    CapiMood.point: PoseArte('aponta', 335.5, 208.5, 308.5, 767, 837),
    // Arms up, the piece he carries over his head.
    CapiMood.carry: PoseArte('carrega', 780, 376, 609, 1562, 1633),
  };

  /// The fur colours the art is made in (anything else: caramel).
  static const pelagens = {
    'caramelo',
    'chocolate',
    'neve',
    'dourado',
    'galaxia',
    'arco_iris',
  };

  String asset(String pelagem) {
    final p = pelagens.contains(pelagem) ? pelagem : 'caramelo';
    return 'assets/capi/poses/${nome}_$p.webp';
  }
}

/// Where a wardrobe item sits on Capi, in eye distances from the midpoint
/// of his eyes, and which point of the item goes there ([fx], [fy],
/// fractions of its size). Hats rest on the head between the ears, like
/// the helmet in the Gemini painting of Capi wearing it.
class ItemArte {
  const ItemArte(
    this.largura,
    this.dx,
    this.dy, {
    this.fx = 0.5,
    this.fy = 0.5,
    this.atras = false,
    this.volta,
  });

  /// Width, in eye distances.
  final double largura;
  final double dx;
  final double dy;
  final double fx;
  final double fy;

  /// Behind the body (wings, cape, backpack).
  final bool atras;

  /// For what goes around the neck (scarf, lei): the part of the image, as
  /// fractions of its size, that passes behind the neck. The whole item is
  /// drawn behind the body (its sides show), then again in front without
  /// that part.
  final Rect? volta;

  static String asset(String id) => 'assets/capi/itens/$id.webp';

  static const todos = {
    // Hats (ids as in CapiHat): the bottom of the hat on the head, the brim
    // just above the eyes, like the helmet in the icon.
    'helmet': ItemArte(1.78, 0, -0.17, fy: 1),
    'fundador': ItemArte(1.78, 0, -0.17, fy: 1),
    'straw': ItemArte(2.15, 0, -0.14, fy: 1),
    'junino': ItemArte(2.2, 0, -0.14, fy: 1),
    'pirate': ItemArte(1.95, 0, -0.2, fy: 1),
    'touca': ItemArte(1.62, 0, -0.1, fy: 1),
    'chef': ItemArte(1.42, 0, -0.3, fy: 1),
    'wizard': ItemArte(1.95, 0, -0.2, fy: 1),
    'vip': ItemArte(1.35, 0, -0.36, fy: 1),
    'crown': ItemArte(1.15, 0, -0.44, fy: 1),
    'coroa_estrelas': ItemArte(1.22, 0, -0.44, fy: 1),
    'party': ItemArte(0.78, 0.22, -0.46, fy: 1),
    // Face.
    'oculos_sol': ItemArte(1.72, 0, 0.0),
    'oculos_coracao': ItemArte(1.78, 0, 0.0),
    'mascara_heroi': ItemArte(1.74, 0, -0.02),
    'monoculo': ItemArte(0.62, 0.5, 0.0, fx: 0.45, fy: 0.43),
    'bigode': ItemArte(1.02, 0, 0.5, fy: 0.42),
    // Neck.
    'cachecol': ItemArte(
      1.6,
      0,
      1.14,
      fy: 0.22,
      volta: Rect.fromLTRB(0.1, 0, 0.9, 0.24),
    ),
    'gravata': ItemArte(0.72, 0, 1.05),
    'lenco': ItemArte(
      1.32,
      0,
      1.1,
      fy: 0.14,
      volta: Rect.fromLTRB(0.15, 0, 0.85, 0.22),
    ),
    'colar_flores': ItemArte(
      1.58,
      0,
      1.12,
      fy: 0.18,
      volta: Rect.fromLTRB(0.15, 0, 0.85, 0.3),
    ),
    // Back (and the swim ring around the waist).
    'asinhas': ItemArte(3.2, 0, 1.15, atras: true),
    'capa_real': ItemArte(2.6, 0, 2.05, fy: 1, atras: true),
    'mochila': ItemArte(2.4, 0, 0.85, atras: true),
    'boia': ItemArte(2.7, 0, 1.6, fy: 0.62),
  };
}

/// Draws the painted Capi on the 100x100 grid CapiPainter uses: feet at
/// y 96, head centred on x 50. False when the art isn't ready yet.
bool pintarCapiArte(
  Canvas canvas, {
  required CapiMood mood,
  required double t,
  required CapiHat hat,
  required String pelagem,
  required List<String?> outros,
}) {
  final pose = PoseArte.todas[mood]!;
  final corpo = CapiArte.imagem(pose.asset(pelagem));
  if (corpo == null) return false;

  // Units per source pixel: the eyes are 26.9 units apart (the head about
  // 46 units wide), centred on x 50.
  final s = 26.9 / pose.d;
  final left = 50 - pose.ex * s;
  final top = 96 - pose.h * s;
  final bob = _seno(t) * 1.2;
  final breath = 1 + _seno(t + 0.19) * 0.012;

  // Ground shadow.
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(50, 95.5), width: 46, height: 6),
    Paint()
      ..color = const Color(0x40000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
  );

  canvas.save();
  // Breathing from the feet, and the idle bob.
  canvas.translate(50, 96);
  canvas.scale(1, breath);
  canvas.translate(-50, -96 + bob * 0.5);

  final ids = [hat.id, ...outros];
  void itens(bool atras) {
    for (final id in ids) {
      if (id == null) continue;
      final arte = ItemArte.todos[id];
      if (arte == null) continue;
      final volta = arte.volta;
      if (arte.atras != atras && !(volta != null && atras)) continue;
      final img = CapiArte.imagem(ItemArte.asset(id));
      if (img == null) continue;
      final w = arte.largura * pose.d * s;
      final h = w * img.height / img.width;
      final ax = left + (pose.ex + arte.dx * pose.d) * s;
      final ay = top + (pose.ey + arte.dy * pose.d) * s;
      final onde = Rect.fromLTWH(ax - arte.fx * w, ay - arte.fy * h, w, h);
      if (volta != null && !atras) {
        // In front: all but the part that goes behind the neck.
        final escondida = Rect.fromLTRB(
          onde.left + volta.left * w,
          onde.top + volta.top * h,
          onde.left + volta.right * w,
          onde.top + volta.bottom * h,
        );
        canvas.save();
        canvas.clipPath(
          Path.combine(
            PathOperation.difference,
            Path()..addRect(onde),
            Path()..addRect(escondida),
          ),
        );
        _desenhar(canvas, img, onde);
        canvas.restore();
      } else {
        _desenhar(canvas, img, onde);
      }
    }
  }

  itens(true);
  _desenhar(canvas, corpo, Rect.fromLTWH(left, top, pose.w * s, pose.h * s));
  if (outros.contains('mochila')) {
    // Seen from the front, the backpack hides behind him: its straps show.
    _alcas(canvas, Offset(left + pose.ex * s, top + pose.ey * s), pose.d * s);
  }
  itens(false);
  canvas.restore();
  return true;
}

/// The backpack's straps over the shoulders, from the eyes' midpoint
/// [olhos] and the eye distance [d] (grid units).
void _alcas(Canvas canvas, Offset olhos, double d) {
  for (final lado in [-1.0, 1.0]) {
    final de = olhos + Offset(lado * 0.58 * d, 0.86 * d);
    final ate = olhos + Offset(lado * 0.52 * d, 1.62 * d);
    final meio = Offset.lerp(de, ate, 0.5)! + Offset(lado * 0.05 * d, 0);
    final alca = Path()
      ..moveTo(de.dx, de.dy)
      ..quadraticBezierTo(meio.dx, meio.dy, ate.dx, ate.dy);
    canvas.drawPath(
      alca,
      Paint()
        ..color = const Color(0xFF1F4A2A)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 0.11 * d,
    );
    canvas.drawPath(
      alca,
      Paint()
        ..color = const Color(0xFF3F8A50)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 0.07 * d,
    );
    // The buckle.
    final fivela = Offset.lerp(de, ate, 0.62)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: fivela, width: 0.13 * d, height: 0.08 * d),
        Radius.circular(0.02 * d),
      ),
      Paint()..color = const Color(0xFF2B2B2B),
    );
  }
}

/// A pup, standing (or curled up asleep), feet at the bottom of [size].
bool pintarFilhoteArte(Canvas canvas, Size size, {bool dormindo = false}) {
  final img = CapiArte.imagem(
    dormindo ? CapiArte.filhoteDormindo : CapiArte.filhote,
  );
  if (img == null) return false;
  final h = size.height * (dormindo ? 0.62 : 0.95);
  final w = h * img.width / img.height;
  _desenhar(
    canvas,
    img,
    Rect.fromLTWH((size.width - w) / 2, size.height - h, w, h),
  );
  return true;
}

double _seno(double t) => sin(t * 2 * pi);

void _desenhar(Canvas canvas, ui.Image img, Rect onde) {
  canvas.drawImageRect(
    img,
    Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
    onde,
    Paint()..filterQuality = FilterQuality.medium,
  );
}
