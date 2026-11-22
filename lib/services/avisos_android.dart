import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/lembretes.dart';
import '../l10n/idioma.dart';
import 'analytics.dart';
import 'avisos.dart';
import 'config_remota_firebase.dart';
import 'duelo_aviso.dart';
import 'firebase_app.dart';
import 'progress_store.dart';

/// Reminders are local notifications: Android and iPhone.
bool get lembretesSuportados => Platform.isAndroid || Platform.isIOS;

/// Firebase messages, duels and the in-game update need Google's services
/// (on the iPhone, push would need an APNs key: not set up).
bool get mensagensSuportadas => Platform.isAndroid;

final _plugin = FlutterLocalNotificationsPlugin();
bool _pronto = false;

// Getters, so the names follow the game's language.
AndroidNotificationChannel get _canalLembretes => AndroidNotificationChannel(
  'lembretes',
  tr('Lembretes do Capi'),
  description: tr('O presente do dia e as missões, uma vez por dia.'),
);

AndroidNotificationChannel get _canalNovidades => AndroidNotificationChannel(
  'novidades',
  tr('Novidades'),
  description: tr('Versões novas e eventos do CapiBlocks.'),
  importance: Importance.high,
);

AndroidNotificationChannel get _canalDuelos => AndroidNotificationChannel(
  'duelos',
  tr('Duelos'),
  description: tr('Quando um amigo joga ou devolve o seu desafio.'),
  importance: Importance.high,
);

Future<void> _preparar() async {
  if (_pronto) return;
  _pronto = true;
  tzdata.initializeTimeZones();
  try {
    final local = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(local.identifier));
  } catch (_) {
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
  }
  await _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_notificacao'),
      // The iPhone asks for permission only when the player says yes to
      // the reminders (see lembretes), not when the game opens.
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
    // A duel notification shown with the game open: its route; a reminder:
    // just counted.
    onDidReceiveNotificationResponse: (r) => _tocou(r.payload),
  );
  // The game was opened by tapping a reminder: counted (duels opened from
  // a closed game come through Firebase, in _mensagens).
  final inicio = await _plugin.getNotificationAppLaunchDetails();
  final payload = inicio?.notificationResponse?.payload;
  if ((inicio?.didNotificationLaunchApp ?? false) &&
      (payload?.startsWith(_lembrete) ?? false)) {
    _tocou(payload);
  }
  final android = _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await android?.createNotificationChannel(_canalLembretes);
  await android?.createNotificationChannel(_canalNovidades);
  await android?.createNotificationChannel(_canalDuelos);
}

/// The payload of a reminder: `lembrete:<tipo>:<dias>`.
const _lembrete = 'lembrete:';

void _tocou(String? payload) {
  if (payload != null && payload.startsWith(_lembrete)) {
    final partes = payload.substring(_lembrete.length).split(':');
    Analytics.event('lembrete_aberto', {
      'tipo': partes.first,
      'dias': int.tryParse(partes.last) ?? 0,
    });
    return;
  }
  _abrir(payload);
}

/// A route from a notification (`/` is just the game: the menu fetches
/// the duels' results by itself).
void _abrir(String? rota) {
  if (rota == null || rota.isEmpty || rota == '/') return;
  Avisos.abrir?.call(rota);
}

/// Leaving the game re-schedules the reminders too: their texts then
/// tell what is waiting by now (today's gift taken, a streak to keep...).
AppLifecycleListener? _aoSair;

Future<void> iniciar(ProgressStore store) async {
  if (!lembretesSuportados) return;
  try {
    await _preparar();
    await _agendar(store);
    _aoSair ??= AppLifecycleListener(
      onHide: () => unawaited(_agendar(store).catchError((_) {})),
    );
    if (mensagensSuportadas) await _mensagens();
  } catch (_) {
    // Notifications must never stop the game.
  }
}

/// Firebase Cloud Messaging: every phone listens to the "novidades" topic,
/// so a message sent from the Firebase console reaches everyone, and leaves
/// its own address for the duels' notifications. With the game open, a
/// message shows as a local notification; tapping one opens its route.
Future<void> _mensagens() async {
  if (!await firebasePronto()) return;
  final fcm = FirebaseMessaging.instance;
  await fcm.subscribeToTopic('novidades');
  // The registration token, which the function on Vercel sends to (FCM
  // HTTP v1 `message.token`). The newer register()/onRegistered gives an
  // installation id instead, for a different way of sending.
  // ignore: deprecated_member_use
  final token = await fcm.getToken();
  if (token != null) unawaited(DueloAviso.registrarAparelho(token));
  // ignore: deprecated_member_use
  fcm.onTokenRefresh.listen(DueloAviso.registrarAparelho);
  FirebaseMessaging.onMessageOpenedApp.listen(
    (m) => _abrir(m.data['rota'] as String?),
  );
  final inicial = await fcm.getInitialMessage();
  if (inicial != null) {
    // The game was closed: let the menu come up first.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _abrir(inicial.data['rota'] as String?),
    );
  }
  FirebaseMessaging.onMessage.listen((m) {
    final n = m.notification;
    if (n == null) return;
    final rota = m.data['rota'] as String?;
    final canal = rota != null ? _canalDuelos : _canalNovidades;
    _plugin.show(
      id: m.hashCode,
      title: n.title,
      body: n.body,
      payload: rota,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          canal.id,
          canal.name,
          channelDescription: canal.description,
          importance: Importance.high,
          icon: 'ic_notificacao',
          color: const Color(0xFFFFC94D),
        ),
      ),
    );
  });
}

Future<void> pedirParaDuelos() async {
  if (!mensagensSuportadas) return;
  try {
    await _preparar();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
  } catch (_) {
    // Never stops the game.
  }
}

/// Schedules the reminders for the days of absence in [lembretesDias] at
/// [lembretesHora], replacing the old ones, each with what the player has
/// waiting (core/lembretes.dart); with reminders off, just clears them.
Future<void> _agendar(ProgressStore store) async {
  // 100 to 103 (and 100 to 102 from before 1.16).
  for (var i = 0; i < lembretesDias.length; i++) {
    await _plugin.cancel(id: 100 + i);
  }
  if (!store.remindersOn) return;
  final agora = tz.TZDateTime.now(tz.local);
  final lembretes = escolherLembretes(
    EstadoLembretes.doStore(store, DateTime.now()),
  );
  for (var i = 0; i < lembretes.length; i++) {
    final l = lembretes[i];
    final quando = tz.TZDateTime(
      tz.local,
      agora.year,
      agora.month,
      agora.day + l.dias,
      lembretesHora,
    );
    await _plugin.zonedSchedule(
      id: 100 + i,
      title: l.titulo,
      body: l.texto,
      payload: '$_lembrete${l.tipo}:${l.dias}',
      scheduledDate: quando,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _canalLembretes.id,
          _canalLembretes.name,
          channelDescription: _canalLembretes.description,
          icon: 'ic_notificacao',
          color: const Color(0xFFFFC94D),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}

Future<bool> lembretes(ProgressStore store, bool ligar) async {
  if (!lembretesSuportados) return false;
  try {
    await _preparar();
    if (ligar && !await _pedirPermissao()) {
      await store.setRemindersOn(false);
      await _agendar(store);
      Analytics.event('lembretes', {'ligado': 0, 'permissao': 0});
      return false;
    }
    await store.setRemindersOn(ligar);
    await _agendar(store);
    Analytics.event('lembretes', {'ligado': ligar ? 1 : 0, 'permissao': 1});
    return ligar;
  } catch (_) {
    return false;
  }
}

/// Android 13+ or the iPhone's own question (asked once by the system;
/// after a "no", only the phone's settings can turn it back on).
Future<bool> _pedirPermissao() async {
  if (Platform.isIOS) {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }
  final android = _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  return await android?.requestNotificationsPermission() ?? false;
}

/// Offered once per opening of the game.
bool _oferecida = false;

Future<void> verificarAtualizacao(
  BuildContext context,
  ProgressStore store,
) async {
  if (!mensagensSuportadas || _oferecida) return;
  _oferecida = true;
  try {
    final info = await InAppUpdate.checkForUpdate();
    if (info.updateAvailability != UpdateAvailability.updateAvailable) return;
    // Google Play's own screen: "update now", with the progress.
    final r = await InAppUpdate.performImmediateUpdate();
    if (r == AppUpdateResult.success || !context.mounted) return;
    // Declined: fine, unless this version is too old to play
    // (Firebase Remote Config `versao_minima`, a build number).
    if (!await _obrigatoria()) return;
    if (!context.mounted) return;
    await _exigirAtualizacao(context);
  } catch (_) {
    // Not installed from Google Play (tests, sideloaded APK): nothing to do.
  }
}

/// Whether the installed build is below the minimum set in Firebase
/// Remote Config (`versao_minima`; 0 or missing: none is required).
Future<bool> _obrigatoria() async {
  try {
    final rc = await configRemota();
    if (rc == null) return false;
    await rc.fetchAndActivate();
    final minima = rc.getInt(chaveVersaoMinima);
    final atual = int.tryParse((await PackageInfo.fromPlatform()).buildNumber);
    return atual != null && atual < minima;
  } catch (_) {
    return false;
  }
}

/// A version too old to play: the game waits until it is updated.
Future<void> _exigirAtualizacao(BuildContext context) async {
  while (true) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(tr('Atualize o CapiBlocks')),
          content: Text(
            tr(
              'Esta versão do jogo é antiga demais. Atualize pela Play Store '
              'para continuar jogando — seu progresso continua salvo.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(tr('Atualizar agora')),
            ),
          ],
        ),
      ),
    );
    try {
      final r = await InAppUpdate.performImmediateUpdate();
      if (r == AppUpdateResult.success) return;
    } catch (_) {
      return;
    }
  }
}
