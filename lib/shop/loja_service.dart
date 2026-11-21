import 'package:flutter/foundation.dart';

import '../services/progress_store.dart';
import 'loja_stub.dart' if (dart.library.io) 'loja_play.dart' as impl;
import 'produtos.dart';

enum ResultadoCompra { ok, cancelada, pendente, erro, indisponivel }

/// Sells [Produto]s and delivers them into the [ProgressStore]
/// ([Entrega]). Google Play on Android, the App Store on iPhone; a simulator
/// in browser tests and web debug; nothing elsewhere (the shop button hides).
abstract class LojaService extends ChangeNotifier {
  LojaService(this.store);

  final ProgressStore store;

  /// The products came from the store: prices known, purchases go through.
  bool get disponivel;

  /// This device has a store, even while it has not answered yet. The shop
  /// button shows whenever this is true, so App Review (and a player with a
  /// bad connection at the opening) always finds the purchases.
  bool get existe => disponivel;

  /// Asking the store for the products right now.
  bool get carregando => false;

  /// Starts listening for purchases, including ones that finished while
  /// the game was closed (a pending payment approved later). Called again,
  /// asks the store for the products once more if they did not come.
  Future<void> iniciar();

  /// The store's price, in the player's currency, once known.
  String preco(Produto produto) => produto.precoBase;

  Future<ResultadoCompra> comprar(Produto produto);

  /// Brings back one-time purchases (a new phone, the app reinstalled).
  Future<void> restaurar();

  /// Google Play on Android when the store answers; null elsewhere.
  static LojaService? play(ProgressStore store) => impl.criarLojaPlay(store);
}

/// No shop (the web, iOS for now).
class SemLoja extends LojaService {
  SemLoja(super.store);

  @override
  bool get disponivel => false;

  @override
  Future<void> iniciar() async {}

  @override
  Future<ResultadoCompra> comprar(Produto produto) async =>
      ResultadoCompra.indisponivel;

  @override
  Future<void> restaurar() async {}
}

/// Browser tests and web debug: every purchase goes through at once.
class LojaSimulada extends LojaService {
  LojaSimulada(super.store);

  var _compras = 0;

  @override
  bool get disponivel => true;

  @override
  Future<void> iniciar() async {}

  @override
  Future<ResultadoCompra> comprar(Produto produto) async {
    await Entrega.aplicar(store, produto, compraId: 'simulada-${_compras++}');
    notifyListeners();
    return ResultadoCompra.ok;
  }

  @override
  Future<void> restaurar() async {}
}
