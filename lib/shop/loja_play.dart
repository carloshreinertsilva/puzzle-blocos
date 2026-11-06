import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../services/analytics.dart';
import '../services/progress_store.dart';
import 'loja_service.dart';
import 'produtos.dart';

LojaService? criarLojaPlay(ProgressStore store) =>
    Platform.isAndroid || Platform.isIOS ? LojaPlay(store) : null;

/// Google Play Billing on Android, StoreKit on iPhone (both through
/// in_app_purchase, with the same product ids). Purchases are delivered from
/// the purchase stream, which also brings purchases finished while the game
/// was closed and the ones "Restaurar compras" brings back. Purchases are
/// checked by the store on the phone; there is no server of ours yet.
class LojaPlay extends LojaService {
  LojaPlay(super.store);

  final _iap = InAppPurchase.instance;
  final _detalhes = <String, ProductDetails>{};
  final _esperando = <String, Completer<ResultadoCompra>>{};
  StreamSubscription<List<PurchaseDetails>>? _assinatura;
  bool _disponivel = false;

  @override
  bool get disponivel => _disponivel;

  @override
  Future<void> iniciar() async {
    _assinatura ??= _iap.purchaseStream.listen(
      _recebidas,
      onError: (Object _) {},
    );
    try {
      if (!await _iap.isAvailable()) return;
      final resposta = await _iap.queryProductDetails({
        for (final p in Produto.values) p.id,
      });
      for (final d in resposta.productDetails) {
        _detalhes[d.id] = d;
      }
      _disponivel = _detalhes.isNotEmpty;
    } catch (_) {
      _disponivel = false;
    }
    notifyListeners();
  }

  @override
  String preco(Produto produto) =>
      _detalhes[produto.id]?.price ?? produto.precoBase;

  @override
  Future<ResultadoCompra> comprar(Produto produto) async {
    final detalhes = _detalhes[produto.id];
    if (detalhes == null) return ResultadoCompra.indisponivel;
    final espera = _esperando[produto.id] = Completer<ResultadoCompra>();
    final param = PurchaseParam(productDetails: detalhes);
    try {
      final iniciou = produto.consumivel
          ? await _iap.buyConsumable(purchaseParam: param)
          : await _iap.buyNonConsumable(purchaseParam: param);
      if (!iniciou) _terminar(produto.id, ResultadoCompra.erro);
    } catch (_) {
      _terminar(produto.id, ResultadoCompra.erro);
    }
    return espera.future;
  }

  @override
  Future<void> restaurar() => _iap.restorePurchases();

  Future<void> _recebidas(List<PurchaseDetails> compras) async {
    for (final compra in compras) {
      final produto = Produto.porId(compra.productID);
      switch (compra.status) {
        case PurchaseStatus.pending:
          _terminar(compra.productID, ResultadoCompra.pendente);
        case PurchaseStatus.purchased || PurchaseStatus.restored:
          if (produto != null) {
            await Entrega.aplicar(store, produto, compraId: compra.purchaseID);
            Analytics.event('compra', {
              'produto': produto.id,
              'restaurada': compra.status == PurchaseStatus.restored ? 1 : 0,
            });
          }
          _terminar(compra.productID, ResultadoCompra.ok);
        case PurchaseStatus.canceled:
          _terminar(compra.productID, ResultadoCompra.cancelada);
        case PurchaseStatus.error:
          _terminar(compra.productID, ResultadoCompra.erro);
      }
      // Tells Google Play it was delivered; otherwise it refunds the
      // purchase after a few days.
      if (compra.pendingCompletePurchase) {
        await _iap.completePurchase(compra);
      }
    }
    notifyListeners();
  }

  void _terminar(String id, ResultadoCompra resultado) {
    final espera = _esperando.remove(id);
    if (espera != null && !espera.isCompleted) espera.complete(resultado);
  }

  @override
  void dispose() {
    _assinatura?.cancel();
    super.dispose();
  }
}
