import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../services/analytics.dart';
import '../services/progress_store.dart';
import 'loja_service.dart';
import 'produtos.dart';

LojaService? criarLojaPlay(ProgressStore store) =>
    Platform.isAndroid || Platform.isIOS ? LojaPlay(store) : null;

/// Google Play Billing on Android, StoreKit on iPhone (both through
/// in_app_purchase, with the same product ids). Purchases are delivered from
/// the purchase stream, which also brings the ones "Restaurar compras" brings
/// back and the ones the store finished while the game was closed. Purchases
/// are checked by the store on the phone; there is no server of ours yet.
class LojaPlay extends LojaService {
  LojaPlay(super.store, {@visibleForTesting bool? android})
    : _android = android ?? Platform.isAndroid;

  final bool _android;
  final _iap = InAppPurchase.instance;
  final _detalhes = <String, ProductDetails>{};
  final _esperando = <String, Completer<ResultadoCompra>>{};
  StreamSubscription<List<PurchaseDetails>>? _assinatura;
  Future<void> _fila = Future.value();
  bool _disponivel = false;

  @override
  bool get disponivel => _disponivel;

  @override
  Future<void> iniciar() async {
    _assinatura ??= _iap.purchaseStream.listen(
      // One list at a time: two reports of the same purchase running together
      // would both find it undelivered and pay twice.
      (compras) => _fila = _fila.then((_) => _recebidas(compras)),
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
      // On Android a Pix approved while the game was closed only shows up by
      // asking for the purchases. StoreKit resends by itself, and restoring
      // there would ask the player to sign in for nothing.
      if (_disponivel && _android) await _iap.restorePurchases();
    } catch (_) {
      _disponivel = _detalhes.isNotEmpty;
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
      // On Android we consume after delivering: the plugin's automatic
      // consume is forgotten if the game closes before a Pix is paid, and
      // happens before delivery otherwise. StoreKit requires the automatic.
      final iniciou = produto.consumivel
          ? await _iap.buyConsumable(
              purchaseParam: param,
              autoConsume: !_android,
            )
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
      try {
        await _processar(compra);
      } catch (_) {
        // Not confirmed to the store, so it comes back on the next query.
        _terminar(compra.productID, ResultadoCompra.erro);
      }
    }
    notifyListeners();
  }

  /// On Android, restoring reports everything as "restored", even a Pix not
  /// paid yet: the purchase's own state is what tells the truth.
  static bool _aindaPendente(PurchaseDetails compra) =>
      compra.status == PurchaseStatus.pending ||
      (compra is GooglePlayPurchaseDetails &&
          compra.billingClientPurchase.purchaseState ==
              PurchaseStateWrapper.pending);

  Future<void> _processar(PurchaseDetails compra) async {
    final id = compra.productID;
    if (id.isEmpty) {
      // When Google Play's answer brings no purchase (cancelled, item already
      // owned...) the Android plugin reports it with no product. The shop
      // sells one thing at a time, so it is about whatever is waiting. Even
      // if the status says "purchased", there is nothing here to deliver.
      _terminarTodas(
        compra.status == PurchaseStatus.canceled
            ? ResultadoCompra.cancelada
            : ResultadoCompra.erro,
      );
      return;
    }
    if (_aindaPendente(compra)) {
      _terminar(id, ResultadoCompra.pendente);
      return;
    }
    switch (compra.status) {
      case PurchaseStatus.purchased || PurchaseStatus.restored:
        final produto = Produto.porId(id);
        if (produto != null) {
          final compraId = _idDaCompra(compra);
          final nova = !_jaEntregue(produto, compraId);
          await Entrega.aplicar(store, produto, compraId: compraId);
          // The purchases are queried at every opening: only count news.
          if (nova) {
            final volta =
                compra.status == PurchaseStatus.restored && !produto.consumivel;
            Analytics.event('compra', {
              'produto': produto.id,
              'restaurada': volta ? 1 : 0,
            });
          }
        }
        _terminar(id, ResultadoCompra.ok);
        await _confirmar(compra, produto);
      case PurchaseStatus.canceled:
        _terminar(id, ResultadoCompra.cancelada);
        await _encerrar(compra);
      case PurchaseStatus.error:
        _terminar(id, ResultadoCompra.erro);
        await _encerrar(compra);
      case PurchaseStatus.pending:
        break;
    }
  }

  bool _jaEntregue(Produto produto, String compraId) => produto.consumivel
      ? store.purchaseDelivered(compraId)
      : store.owns(produto.id);

  /// A purchase may have no order number on Android (a promo code, say), and
  /// an empty id would pass for every other purchase without one. The token
  /// is unique there; on iPhone the "token" is the app receipt, but StoreKit
  /// always gives a delivered purchase its transaction id.
  static String _idDaCompra(PurchaseDetails compra) {
    final id = compra.purchaseID;
    if (id != null && id.isNotEmpty) return id;
    return compra.verificationData.serverVerificationData;
  }

  /// Tells the store it was delivered; otherwise Google Play refunds the
  /// purchase after a few days.
  Future<void> _confirmar(PurchaseDetails compra, Produto? produto) async {
    if (_android && (produto?.consumivel ?? false)) {
      // Consuming also acknowledges, and lets the player buy it again.
      await _iap
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
          .consumePurchase(compra);
      return;
    }
    await _encerrar(compra);
  }

  Future<void> _encerrar(PurchaseDetails compra) async {
    if (compra.pendingCompletePurchase) await _iap.completePurchase(compra);
  }

  void _terminar(String id, ResultadoCompra resultado) {
    final espera = _esperando.remove(id);
    if (espera != null && !espera.isCompleted) espera.complete(resultado);
  }

  void _terminarTodas(ResultadoCompra resultado) {
    for (final id in _esperando.keys.toList()) {
      _terminar(id, resultado);
    }
  }

  @override
  void dispose() {
    _assinatura?.cancel();
    super.dispose();
  }
}
