import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:puzzle_blocos/services/analytics.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:puzzle_blocos/shop/loja_play.dart';
import 'package:puzzle_blocos/shop/loja_service.dart';
import 'package:puzzle_blocos/shop/produtos.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A purchase as the Android plugin builds it from Google Play's answer.
GooglePlayPurchaseDetails _compra(
  Produto produto, {
  String pedido = 'GPA.1',
  String token = 'token-1',
  PurchaseStateWrapper estado = PurchaseStateWrapper.purchased,
  bool confirmada = false,
}) => GooglePlayPurchaseDetails.fromPurchase(
  PurchaseWrapper(
    orderId: pedido,
    packageName: 'com.capiblocks.app',
    purchaseTime: 0,
    purchaseToken: token,
    signature: '',
    products: [produto.id],
    isAutoRenewing: false,
    originalJson: '',
    isAcknowledged: confirmada,
    purchaseState: estado,
  ),
).single;

/// What the Android plugin reports when Google Play's answer brings no
/// purchase (the player cancelled, the item is already owned...): no product.
PurchaseDetails _avisoSemProduto(PurchaseStatus status) => PurchaseDetails(
  purchaseID: '',
  productID: '',
  status: status,
  transactionDate: null,
  verificationData: PurchaseVerificationData(
    localVerificationData: '',
    serverVerificationData: '',
    source: 'google_play',
  ),
);

class _Plataforma extends InAppPurchasePlatform {
  // Synchronous, so a second report arrives while the first is being handled.
  final fluxo = StreamController<List<PurchaseDetails>>.broadcast(sync: true);

  /// What the store answers when asked for the purchases.
  var passadas = <GooglePlayPurchaseDetails>[];
  var consultas = 0;
  bool? autoConsume;
  final confirmadas = <String>[];

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => fluxo.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async => ProductDetailsResponse(
    productDetails: [
      for (final id in identifiers)
        ProductDetails(
          id: id,
          title: id,
          description: '',
          price: 'R\$ 1,00',
          rawPrice: 1,
          currencyCode: 'BRL',
        ),
    ],
    notFoundIDs: const [],
  );

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    consultas++;
    // Like the real plugin: "restored", whatever the purchase's own state.
    fluxo.add([for (final p in passadas) p..status = PurchaseStatus.restored]);
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async {
    this.autoConsume = autoConsume;
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    confirmadas.add(purchase.verificationData.serverVerificationData);
  }
}

class _Adicao extends Fake implements InAppPurchaseAndroidPlatformAddition {
  _Adicao(this.aoConsumir);

  final void Function() aoConsumir;
  final consumidas = <String>[];

  @override
  Future<BillingResultWrapper> consumePurchase(PurchaseDetails purchase) async {
    aoConsumir();
    consumidas.add(purchase.verificationData.serverVerificationData);
    return const BillingResultWrapper(responseCode: BillingResponse.ok);
  }
}

class _Estatisticas implements AnalyticsBackend {
  final eventos = <Map<String, Object>>[];

  @override
  void log(String name, Map<String, Object> params) {
    if (name == 'compra') eventos.add(params);
  }

  @override
  Future<void> setEnabled(bool on) async {}
}

void main() {
  late ProgressStore store;
  late _Plataforma plataforma;
  late _Adicao adicao;
  late _Estatisticas estatisticas;
  late int estrelasAoConsumir;

  setUpAll(() {
    // Keeps the first InAppPurchase.instance from registering the real
    // plugin, which would need a phone.
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    InAppPurchase.instance;
    debugDefaultTargetPlatformOverride = null;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await ProgressStore.load();
    plataforma = _Plataforma();
    InAppPurchasePlatform.instance = plataforma;
    estrelasAoConsumir = -1;
    adicao = _Adicao(() => estrelasAoConsumir = store.stars);
    InAppPurchasePlatformAddition.instance = adicao;
    estatisticas = _Estatisticas();
    Analytics.use(estatisticas);
  });

  tearDown(() {
    Analytics.use(null);
  });

  Future<LojaPlay> abrir({bool android = true}) async {
    final loja = LojaPlay(store, android: android);
    await loja.iniciar();
    await pumpEventQueue();
    return loja;
  }

  test('restoring does not deliver a Pix still unpaid', () async {
    final loja = await abrir();
    plataforma.passadas = [
      _compra(Produto.estrelas400, estado: PurchaseStateWrapper.pending),
      _compra(
        Produto.removerAnuncios,
        pedido: '',
        token: 'token-2',
        estado: PurchaseStateWrapper.pending,
      ),
    ];

    await loja.restaurar();
    await pumpEventQueue();

    expect(store.stars, 0);
    expect(store.adsRemoved, isFalse);
    expect(adicao.consumidas, isEmpty);
    expect(plataforma.confirmadas, isEmpty);
    expect(estatisticas.eventos, isEmpty);
  });

  test('a Pix approved with the game closed arrives at the next opening, '
      'and is consumed only after being delivered', () async {
    plataforma.passadas = [_compra(Produto.estrelas400)];

    await abrir();

    expect(plataforma.consultas, 1);
    expect(store.stars, 400);
    expect(estrelasAoConsumir, 400);
    expect(adicao.consumidas, ['token-1']);
    expect(plataforma.confirmadas, isEmpty);
    expect(estatisticas.eventos, [
      {'produto': 'estrelas_400', 'restaurada': 0},
    ]);
  });

  test('a Pix still unpaid at the opening waits for the payment', () async {
    plataforma.passadas = [
      _compra(Produto.estrelas150, estado: PurchaseStateWrapper.pending),
    ];
    final loja = await abrir();
    expect(store.stars, 0);

    plataforma.passadas = [_compra(Produto.estrelas150)];
    await loja.restaurar();
    await pumpEventQueue();

    expect(store.stars, 150);
    expect(adicao.consumidas, ['token-1']);
  });

  test('buying a consumable leaves consuming to the game on Android', () async {
    final loja = await abrir();
    unawaited(loja.comprar(Produto.estrelas150));
    await pumpEventQueue();
    expect(plataforma.autoConsume, isFalse);
  });

  group('an answer from the store with no purchase ends the wait', () {
    for (final (status, esperado) in [
      (PurchaseStatus.canceled, ResultadoCompra.cancelada),
      (PurchaseStatus.error, ResultadoCompra.erro),
      // Nothing came to deliver, so it must not be reported as delivered.
      (PurchaseStatus.purchased, ResultadoCompra.erro),
    ]) {
      test('${status.name} is ${esperado.name}', () async {
        final loja = await abrir();
        ResultadoCompra? resultado;
        unawaited(loja.comprar(Produto.estrelas150).then((r) => resultado = r));
        await pumpEventQueue();
        expect(resultado, isNull);

        plataforma.fluxo.add([_avisoSemProduto(status)]);
        await pumpEventQueue();

        expect(resultado, esperado);
        expect(store.stars, 0);
        expect(estatisticas.eventos, isEmpty);
      });
    }
  });

  test('on iPhone: automatic consume, and no restore at the opening', () async {
    final loja = await abrir(android: false);
    unawaited(loja.comprar(Produto.estrelas150));
    await pumpEventQueue();
    expect(plataforma.autoConsume, isTrue);
    expect(plataforma.consultas, 0);

    final compra = PurchaseDetails(
      purchaseID: 'ios-1',
      productID: Produto.estrelas150.id,
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: 'recibo',
        source: 'app_store',
      ),
      transactionDate: '0',
      status: PurchaseStatus.purchased,
    )..pendingCompletePurchase = true;
    plataforma.fluxo.add([compra]);
    await pumpEventQueue();

    expect(store.stars, 150);
    expect(plataforma.confirmadas, ['recibo']);
    expect(adicao.consumidas, isEmpty);
  });

  test('the same purchase reported at once pays only once', () async {
    await abrir();
    final compra = _compra(Produto.estrelas1000);
    plataforma.fluxo
      ..add([compra])
      ..add([_compra(Produto.estrelas1000)]);
    await pumpEventQueue();
    expect(store.stars, 1000);
  });

  test('a consumable stuck by an old restore is delivered once and freed '
      'from the store', () async {
    await Entrega.aplicar(store, Produto.estrelas150, compraId: 'GPA.1');
    plataforma.passadas = [_compra(Produto.estrelas150, confirmada: true)];

    await abrir();

    expect(store.stars, 150);
    expect(adicao.consumidas, ['token-1']);
    expect(estatisticas.eventos, isEmpty);
  });

  test('purchases without an order number do not block each other', () async {
    await abrir();
    plataforma.fluxo
      ..add([_compra(Produto.estrelas150, pedido: '', token: 'a')])
      ..add([_compra(Produto.estrelas150, pedido: '', token: 'b')]);
    await pumpEventQueue();
    expect(store.stars, 300);
  });

  test('a one-time purchase is acknowledged, not consumed, and counted '
      'once however many openings bring it back', () async {
    plataforma.passadas = [_compra(Produto.removerAnuncios)];
    (await abrir()).dispose();
    plataforma.passadas = [_compra(Produto.removerAnuncios, confirmada: true)];
    await abrir();
    await pumpEventQueue();

    expect(store.adsRemoved, isTrue);
    expect(plataforma.confirmadas, ['token-1']);
    expect(adicao.consumidas, isEmpty);
    expect(estatisticas.eventos, [
      {'produto': 'remover_anuncios', 'restaurada': 1},
    ]);
  });

  test('a failure at the store still leaves the shop open', () async {
    final falha = _PlataformaQueFalha();
    InAppPurchasePlatform.instance = falha;
    final loja = LojaPlay(store, android: true);
    await loja.iniciar();
    expect(loja.disponivel, isTrue);
    expect(await loja.comprar(Produto.estrelas150), ResultadoCompra.erro);
  });
}

class _PlataformaQueFalha extends _Plataforma {
  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    throw InAppPurchaseException(source: 'google_play', code: 'x');
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async => false;
}
