/// A challenge link: the same board (seed) and the score to beat.
///
/// New links are `https://capiblocks.vercel.app/duelo?s=<seed>&p=<points>`
/// (`&m=blitz` for Blitz): the `/duelo` path lets Android open them in the
/// app (App Links). Old links (`/?duelo=<seed>&p=<points>`) still work.
class DueloConvite {
  const DueloConvite({
    required this.semente,
    required this.meta,
    this.blitz = false,
  });

  static const host = 'capiblocks.vercel.app';

  final int semente;
  final int meta;
  final bool blitz;

  Uri get link => Uri.https(host, '/duelo', {
    's': '$semente',
    'p': '$meta',
    if (blitz) 'm': 'blitz',
  });

  /// What goes into WhatsApp & co.
  String get mensagem =>
      'Te desafio no CapiBlocks! Fiz $meta pontos neste tabuleiro. '
      'Consegue passar? $link';

  /// Reads a challenge from a page address or an Android link; null when
  /// [uri] is not one.
  static DueloConvite? ler(Uri uri) {
    final q = uri.queryParameters;
    final caminho = uri.path.endsWith('/')
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;
    final semente = int.tryParse(
      (caminho == '/duelo' ? q['s'] : null) ?? q['duelo'] ?? '',
    );
    if (semente == null) return null;
    return DueloConvite(
      semente: semente,
      meta: int.tryParse(q['p'] ?? '') ?? 1000,
      blitz: q['m'] == 'blitz',
    );
  }
}
