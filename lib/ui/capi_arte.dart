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

/// A pose painting and where Capi's head is in it (source pixels: head
/// centre x, eye line y, head width; the image's full size). Must match
/// POSES in tool/capi_arte.py.
class PoseArte {
  const PoseArte(this.nome, this.cx, this.ey, this.hw, this.w, this.h);
  final String nome;
  final double cx;
  final double ey;
  final double hw;
  final double w;
  final double h;

  static const _feliz = PoseArte('feliz', 590, 270, 780, 1172, 1515);
  static const _comemora = PoseArte('comemora', 644, 300, 818, 1282, 1517);

  static const todas = {
    CapiMood.happy: _feliz,
    CapiMood.cheer: _comemora,
    CapiMood.worried: PoseArte('preocupado', 477, 274, 785, 959, 1516),
    CapiMood.sad: PoseArte('triste', 587, 229, 779, 1170, 1476),
    CapiMood.point: PoseArte('aponta', 589, 270, 788, 1354, 1517),
    // Arms up, the piece he carries over his head.
    CapiMood.carry: _comemora,
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

/// Where a wardrobe item sits on Capi, in head widths from the head centre
/// (x) and the eye line (y), and which point of the item goes there
/// ([fx], [fy], fractions of its size). Measured on the "feliz" pose.
class ItemArte {
  const ItemArte(
    this.largura,
    this.dx,
    this.dy, {
    this.fx = 0.5,
    this.fy = 0.5,
    this.atras = false,
  });

  /// Width, in head widths.
  final double largura;
  final double dx;
  final double dy;
  final double fx;
  final double fy;

  /// Behind the body (wings, cape, backpack).
  final bool atras;

  static String asset(String id) => 'assets/capi/itens/$id.webp';

  static const todos = {
    // Hats (ids as in CapiHat).
    'helmet': ItemArte(0.80, 0, -0.100, fy: 0.80),
    'fundador': ItemArte(0.80, 0, -0.100, fy: 0.80),
    'straw': ItemArte(1.05, 0, -0.126, fy: 0.72),
    'party': ItemArte(0.42, 0.154, -0.190, fy: 0.92),
    'touca': ItemArte(0.80, 0, -0.068, fy: 0.88),
    'chef': ItemArte(0.60, 0, -0.138, fy: 0.92),
    'pirate': ItemArte(0.95, 0, -0.126, fy: 0.82),
    'junino': ItemArte(1.05, 0, -0.126, fy: 0.72),
    'wizard': ItemArte(0.80, 0, -0.126, fy: 0.85),
    'crown': ItemArte(0.62, 0, -0.151, fy: 0.85),
    'vip': ItemArte(0.70, 0, -0.138, fy: 0.88),
    'coroa_estrelas': ItemArte(0.65, 0, -0.151, fy: 0.85),
    // Face.
    'oculos_sol': ItemArte(0.80, 0.015, 0, fy: 0.45),
    'oculos_coracao': ItemArte(0.80, 0.015, 0, fy: 0.42),
    'mascara_heroi': ItemArte(0.80, 0.015, 0, fy: 0.45),
    'monoculo': ItemArte(0.32, 0.288, -0.004, fy: 0.30),
    'bigode': ItemArte(0.55, 0, 0.323, fy: 0.40),
    // Neck.
    'cachecol': ItemArte(0.85, 0, 0.605, fy: 0.12),
    'gravata': ItemArte(0.36, 0, 0.656),
    'lenco': ItemArte(0.62, 0, 0.592, fy: 0.10),
    'colar_flores': ItemArte(0.85, 0, 0.541, fy: 0.12),
    // Back (and the swim ring around the waist).
    'asinhas': ItemArte(1.70, 0, 0.631, atras: true),
    'capa_real': ItemArte(1.25, 0, 0.426, fy: 0.05, atras: true),
    'mochila': ItemArte(1.05, 0, 0.477, fy: 0.10, atras: true),
    'boia': ItemArte(1.30, 0, 1.092),
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

  // Units per source pixel: the head is 46 units wide.
  final s = 46 / pose.hw;
  final left = 50 - pose.cx * s;
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
      if (arte == null || arte.atras != atras) continue;
      final img = CapiArte.imagem(ItemArte.asset(id));
      if (img == null) continue;
      final w = arte.largura * pose.hw * s;
      final h = w * img.height / img.width;
      final ax = left + (pose.cx + arte.dx * pose.hw) * s;
      final ay = top + (pose.ey + arte.dy * pose.hw) * s;
      _desenhar(
        canvas,
        img,
        Rect.fromLTWH(ax - arte.fx * w, ay - arte.fy * h, w, h),
      );
    }
  }

  itens(true);
  _desenhar(canvas, corpo, Rect.fromLTWH(left, top, pose.w * s, pose.h * s));
  itens(false);
  canvas.restore();
  return true;
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
