import '../l10n/idioma.dart';

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
    this.id,
    this.nome,
  });

  static const host = 'capiblocks.vercel.app';

  final int semente;
  final int meta;
  final bool blitz;

  /// The challenge on the server (`&d=`), so the result goes back to whoever
  /// sent it; null for a plain link.
  final String? id;

  /// The name of whoever sent it (`&n=`), shown during the match.
  final String? nome;

  DueloConvite com({String? id, String? nome}) => DueloConvite(
    semente: semente,
    meta: meta,
    blitz: blitz,
    id: id ?? this.id,
    nome: nome ?? this.nome,
  );

  Uri get link => Uri.https(host, '/duelo', {
    's': '$semente',
    'p': '$meta',
    if (blitz) 'm': 'blitz',
    'd': ?id,
    'n': ?nome,
  });

  /// What goes into WhatsApp & co.
  String get mensagem => tr(
    'Te desafio no CapiBlocks! Fiz {meta} pontos neste tabuleiro. '
    'Consegue passar? {link}',
    {'meta': meta, 'link': link},
  );

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
    final id = q['d'];
    final nome = q['n']?.trim();
    return DueloConvite(
      semente: semente,
      meta: int.tryParse(q['p'] ?? '') ?? 1000,
      blitz: q['m'] == 'blitz',
      id: id != null && RegExp(r'^[A-Za-z0-9]{1,40}$').hasMatch(id) ? id : null,
      nome: nome == null || nome.isEmpty
          ? null
          : nome.substring(0, nome.length.clamp(0, 16)),
    );
  }
}
