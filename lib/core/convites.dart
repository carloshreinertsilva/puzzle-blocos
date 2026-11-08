import 'dart:math';

import '../l10n/idioma.dart';
import '../services/progress_store.dart';
import 'wardrobe.dart';

/// A reward step for whoever invites: given once [amigos] friends came in
/// with the player's code and reached [Convites.faseQueConta].
class MetaConvite {
  const MetaConvite(this.amigos, {this.estrelas = 0, this.item});
  final int amigos;
  final int estrelas;

  /// A wardrobe item id.
  final String? item;

  String get texto => item != null
      ? Wardrobe.byId(item!)!.label
      : trN(estrelas, '{n} estrela', '{n} estrelas');
}

/// Inviting friends. Each phone has a short code; a friend who comes in with
/// it (the link's code reaches the app through the Play Store on Android, or
/// is typed in) gets a welcome gift at once, and counts for whoever invited
/// once they reach [faseQueConta] (so installing and uninstalling earns
/// nothing). The count lives on the server (services/convites_servidor.dart);
/// this file is what the phone decides by itself.
abstract final class Convites {
  static const host = 'capiblocks.vercel.app';

  /// Stars for the friend who comes in with a code, plus [itemPresente].
  static const presenteEstrelas = 50;
  static const itemPresente = 'laco_amizade';

  /// A friend counts once they reach this level.
  static const faseQueConta = 5;

  static const metas = [
    MetaConvite(1, estrelas: 50),
    MetaConvite(3, item: 'faixa_embaixador'),
    MetaConvite(5, item: 'coroa_amizade'),
  ];

  /// With enough friends the player is a Capi Embaixador.
  static const amigosEmbaixador = 3;

  /// No 0/O or 1/I/L: easy to read out and to type.
  static const _letras = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static const tamanho = 6;

  static String gerarCodigo([Random? r]) {
    final rng = r ?? Random.secure();
    return List.generate(
      tamanho,
      (_) => _letras[rng.nextInt(_letras.length)],
    ).join();
  }

  /// [texto] as a code (spaces dropped, upper case), or null when it can't
  /// be one.
  static String? normalizar(String texto) {
    final c = texto.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    if (c.length != tamanho) return null;
    for (final ch in c.split('')) {
      if (!_letras.contains(ch)) return null;
    }
    return c;
  }

  static Uri link(String codigo) => Uri.https(host, '/convite', {'c': codigo});

  /// What goes into WhatsApp & co.
  static String mensagem(String codigo) => tr(
    'Vem jogar CapiBlocks comigo! Encaixe blocos, salve filhotes e '
    'construa a Vila do Capi. Entrando pelo meu convite você ganha '
    '{estrelas} estrelas e um presente: {link} (código {codigo})',
    {'estrelas': presenteEstrelas, 'link': link(codigo), 'codigo': codigo},
  );

  /// The code in an invite link (`/convite?c=...`), or null.
  static String? lerLink(Uri uri) {
    final caminho = uri.path.endsWith('/')
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;
    if (caminho != '/convite') return null;
    return normalizar(uri.queryParameters['c'] ?? '');
  }

  /// The code in the Play Store's install referrer (`convite=ABC234`, maybe
  /// among utm_ fields), or null.
  static String? lerReferrer(String? referrer) {
    if (referrer == null || referrer.isEmpty) return null;
    try {
      final campos = Uri.splitQueryString(referrer);
      return normalizar(campos['convite'] ?? '');
    } catch (_) {
      return null;
    }
  }

  /// This phone's code, made the first time it is needed.
  static Future<String> meuCodigo(ProgressStore store, [Random? r]) async {
    final atual = store.conviteCodigo;
    if (atual != null) return atual;
    final novo = gerarCodigo(r);
    await store.setConviteCodigo(novo);
    return novo;
  }

  /// Comes in with a friend's [codigo]: the welcome gift, once per phone
  /// (not with one's own code). False when it can't be used.
  static Future<bool> usar(ProgressStore store, String codigo) async {
    final c = normalizar(codigo);
    if (c == null || store.conviteUsado != null) return false;
    if (c == store.conviteCodigo) return false;
    await store.setConviteUsado(c);
    await store.addBoughtStars(presenteEstrelas);
    await store.unlockHat(itemPresente);
    await Wardrobe.awardCollections(store);
    return true;
  }

  /// Gives the reward steps reached with [amigos] friends, once each.
  /// Returns what was given.
  static Future<List<MetaConvite>> receberMetas(
    ProgressStore store,
    int amigos,
  ) async {
    await store.setConviteAmigos(max(store.conviteAmigos, amigos));
    final dadas = store.conviteMetasDadas;
    final novas = <MetaConvite>[];
    for (final m in metas) {
      if (m.amigos > amigos || dadas.contains(m.amigos)) continue;
      await store.addConviteMeta(m.amigos);
      if (m.estrelas > 0) await store.addBoughtStars(m.estrelas);
      if (m.item case final id?) await store.unlockHat(id);
      novas.add(m);
    }
    return novas;
  }

  static bool embaixador(ProgressStore store) =>
      store.conviteAmigos >= amigosEmbaixador;

  /// The next step to reach, or null when all are given.
  static MetaConvite? proxima(ProgressStore store) {
    for (final m in metas) {
      if (!store.conviteMetasDadas.contains(m.amigos)) return m;
    }
    return null;
  }
}
