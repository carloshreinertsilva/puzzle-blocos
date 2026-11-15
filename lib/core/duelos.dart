import 'dart:convert';

import '../services/progress_store.dart';

/// One duel between the player and a friend: who it was, and both scores.
/// [meu] when the player sent the challenge (and the friend answered it);
/// otherwise the player answered the friend's.
class ResultadoDuelo {
  const ResultadoDuelo({
    required this.duelo,
    required this.rival,
    required this.nome,
    required this.eu,
    required this.ele,
    required this.meu,
    this.visto = true,
    this.em = 0,
  });

  /// The duel's id on the server.
  final String duelo;

  /// The friend's id on the server (one per phone).
  final String rival;
  final String nome;
  final int eu;
  final int ele;
  final bool meu;

  /// False while the player hasn't been told (a friend answered their
  /// challenge since the game was last open).
  final bool visto;

  /// When it was last updated (milliseconds since 1970).
  final int em;

  String get chave => '$duelo|$rival';
  bool get venci => eu > ele;
  bool get perdi => eu < ele;

  ResultadoDuelo copiar({bool? visto}) => ResultadoDuelo(
    duelo: duelo,
    rival: rival,
    nome: nome,
    eu: eu,
    ele: ele,
    meu: meu,
    visto: visto ?? this.visto,
    em: em,
  );

  Map<String, Object> toJson() => {
    'd': duelo,
    'r': rival,
    'n': nome,
    'eu': eu,
    'ele': ele,
    'meu': meu,
    'v': visto,
    'em': em,
  };

  static ResultadoDuelo? ler(Object? j) {
    if (j is! Map) return null;
    final duelo = j['d'], rival = j['r'], nome = j['n'];
    final eu = j['eu'], ele = j['ele'];
    if (duelo is! String || rival is! String || nome is! String) return null;
    if (eu is! num || ele is! num) return null;
    return ResultadoDuelo(
      duelo: duelo,
      rival: rival,
      nome: nome,
      eu: eu.toInt(),
      ele: ele.toInt(),
      meu: j['meu'] == true,
      visto: j['v'] != false,
      em: (j['em'] as num?)?.toInt() ?? 0,
    );
  }
}

/// The score against one friend over every duel.
class PlacarAmigo {
  const PlacarAmigo({
    required this.rival,
    required this.nome,
    required this.vitorias,
    required this.derrotas,
    required this.empates,
    required this.em,
  });
  final String rival;
  final String nome;
  final int vitorias;
  final int derrotas;
  final int empates;

  /// The latest duel with this friend.
  final int em;

  int get duelos => vitorias + derrotas + empates;
}

/// The duels' scoreboard, kept on the phone (and in the cloud save). The
/// server only carries each duel and its answers
/// (services/duelos_servidor.dart); this file decides what they mean.
abstract final class Duelos {
  /// Older results are dropped past this many.
  static const maximo = 300;

  static List<ResultadoDuelo> todos(ProgressStore store) {
    final json = store.duelosResultados;
    if (json == null) return [];
    try {
      final lista = jsonDecode(json);
      if (lista is! List) return [];
      return [for (final j in lista) ?ResultadoDuelo.ler(j)];
    } catch (_) {
      return [];
    }
  }

  static Future<void> _salvar(
    ProgressStore store,
    List<ResultadoDuelo> lista,
  ) async {
    lista.sort((a, b) => b.em.compareTo(a.em));
    final guardar = lista.take(maximo).map((r) => r.toJson()).toList();
    await store.setDuelosResultados(jsonEncode(guardar));
  }

  /// Keeps [r] (replacing an earlier answer to the same duel by the same
  /// friend). A friend's answer to the player's challenge stays unseen
  /// until [marcarVistos]. Returns whether anything changed.
  static Future<bool> registrar(ProgressStore store, ResultadoDuelo r) async {
    final lista = todos(store);
    final i = lista.indexWhere((x) => x.chave == r.chave);
    if (i >= 0) {
      final antes = lista[i];
      if (antes.eu == r.eu && antes.ele == r.ele && antes.nome == r.nome) {
        return false;
      }
      lista[i] = r.copiar(visto: r.meu ? false : true);
    } else {
      lista.add(r.copiar(visto: r.meu ? false : true));
    }
    await _salvar(store, lista);
    return true;
  }

  /// Friends' answers to the player's challenges not told yet, newest
  /// first.
  static List<ResultadoDuelo> novos(ProgressStore store) =>
      todos(store).where((r) => !r.visto).toList();

  static Future<void> marcarVistos(ProgressStore store) async {
    final lista = todos(store);
    if (lista.every((r) => r.visto)) return;
    await _salvar(store, [for (final r in lista) r.copiar(visto: true)]);
  }

  /// One line per friend, the latest duel first.
  static List<PlacarAmigo> placar(ProgressStore store) {
    final porAmigo = <String, List<ResultadoDuelo>>{};
    for (final r in todos(store)) {
      (porAmigo[r.rival] ??= []).add(r);
    }
    final linhas = [
      for (final MapEntry(key: rival, value: rs) in porAmigo.entries)
        PlacarAmigo(
          rival: rival,
          // todos() is newest first: the name the friend uses now.
          nome: rs.first.nome,
          vitorias: rs.where((r) => r.venci).length,
          derrotas: rs.where((r) => r.perdi).length,
          empates: rs.where((r) => r.eu == r.ele).length,
          em: rs.first.em,
        ),
    ];
    linhas.sort((a, b) => b.em.compareTo(a.em));
    return linhas;
  }

  /// The score against one friend, or null before the first duel.
  static PlacarAmigo? contra(ProgressStore store, String rival) {
    for (final p in placar(store)) {
      if (p.rival == rival) return p;
    }
    return null;
  }
}
