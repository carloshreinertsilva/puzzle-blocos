/// The windows that may open by themselves when the menu opens, most
/// important first (the menu goes through them in this order). At most
/// [FilaAbertura.limitePadrao] of them open each time; the others wait for
/// the next time the menu opens (each one keeps its own condition, so
/// nothing is lost: it is only later).
enum DialogoAbertura {
  /// A friend's invite from the Play Store (read once, on the first run).
  conviteRecebido,

  /// The daily gift.
  presente,

  /// What is new in this version.
  novidades,

  /// A cloud save more advanced than this phone's.
  nuvem,

  /// Friends who answered the player's challenges.
  resultadosDuelo,

  /// The starter pack's difference for those who bought it before.
  bonusFundador,

  /// The cheap first purchase.
  ofertaBoasVindas,

  /// The store's update screen. Never held back: a version too old to
  /// play must be updated.
  atualizacao(obrigatorio: true),

  /// Sign in to Play Games.
  playGames;

  const DialogoAbertura({this.obrigatorio = false});

  /// Opens whatever the limit says.
  final bool obrigatorio;
}

/// Keeps count of the windows opened while the menu opens.
class FilaAbertura {
  FilaAbertura({this.limite = FilaAbertura.limitePadrao});

  /// Windows per opening of the menu (besides the mandatory ones).
  static const limitePadrao = 2;

  final int limite;
  int _mostrados = 0;

  /// Windows opened so far (the mandatory ones don't count).
  int get mostrados => _mostrados;

  /// Whether [d] may still open now.
  bool cabe(DialogoAbertura d) => d.obrigatorio || _mostrados < limite;

  /// [d] opened.
  void mostrou(DialogoAbertura d) {
    if (!d.obrigatorio) _mostrados++;
  }

  /// Of the windows that want to open, the ones that do, in order of
  /// importance: the mandatory ones and then the first [limite].
  static List<DialogoAbertura> escolher(
    Iterable<DialogoAbertura> querem, {
    int limite = limitePadrao,
  }) {
    final fila = FilaAbertura(limite: limite);
    final ordem = querem.toSet().toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final abrem = <DialogoAbertura>[];
    for (final d in ordem) {
      if (!fila.cabe(d)) continue;
      fila.mostrou(d);
      abrem.add(d);
    }
    return abrem;
  }
}
