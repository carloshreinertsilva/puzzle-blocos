import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'avisos.dart';
import 'firebase_app.dart';
import 'progress_store.dart';

bool get suportado => Platform.isAndroid;

final _plugin = FlutterLocalNotificationsPlugin();
bool _pronto = false;

const _canalLembretes = AndroidNotificationChannel(
  'lembretes',
  'Lembretes do Capi',
  description: 'O presente do dia e as missões, uma vez por dia.',
);

const _canalNovidades = AndroidNotificationChannel(
  'novidades',
  'Novidades',
  description: 'Versões novas e eventos do CapiBlocks.',
  importance: Importance.high,
);

/// The hour the reminders ring (local time).
const _hora = 19;

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
    ),
  );
  final android = _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await android?.createNotificationChannel(_canalLembretes);
  await android?.createNotificationChannel(_canalNovidades);
}

Future<void> iniciar(ProgressStore store) async {
  if (!suportado) return;
  try {
    await _preparar();
    await _agendar(store);
    await _mensagens();
  } catch (_) {
    // Notifications must never stop the game.
  }
}

/// Firebase Cloud Messaging: every phone listens to the "novidades" topic,
/// so a message sent from the Firebase console reaches everyone. With the
/// game open, the message shows as a local notification.
Future<void> _mensagens() async {
  if (!await firebasePronto()) return;
  final fcm = FirebaseMessaging.instance;
  await fcm.subscribeToTopic('novidades');
  FirebaseMessaging.onMessage.listen((m) {
    final n = m.notification;
    if (n == null) return;
    _plugin.show(
      id: m.hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _canalNovidades.id,
          _canalNovidades.name,
          channelDescription: _canalNovidades.description,
          icon: 'ic_notificacao',
          color: const Color(0xFFFFC94D),
        ),
      ),
    );
  });
}

/// Schedules the next days' reminders (1, 2 and 3 days from now at 19h),
/// replacing the old ones; with reminders off, just clears them.
Future<void> _agendar(ProgressStore store) async {
  for (var i = 0; i < lembretesTextos.length; i++) {
    await _plugin.cancel(id: 100 + i);
  }
  if (!store.remindersOn) return;
  final agora = tz.TZDateTime.now(tz.local);
  for (var i = 0; i < lembretesTextos.length; i++) {
    final (titulo, texto) = lembretesTextos[i];
    final quando = tz.TZDateTime(
      tz.local,
      agora.year,
      agora.month,
      agora.day + i + 1,
      _hora,
    );
    await _plugin.zonedSchedule(
      id: 100 + i,
      title: titulo,
      body: texto,
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
      ),
    );
  }
}

Future<bool> lembretes(ProgressStore store, bool ligar) async {
  if (!suportado) return false;
  try {
    await _preparar();
    if (ligar) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final ok = await android?.requestNotificationsPermission() ?? false;
      if (!ok) {
        await store.setRemindersOn(false);
        await _agendar(store);
        return false;
      }
    }
    await store.setRemindersOn(ligar);
    await _agendar(store);
    return ligar;
  } catch (_) {
    return false;
  }
}

Future<void> verificarAtualizacao(
  BuildContext context,
  ProgressStore store,
) async {
  if (!suportado) return;
  final hoje = ProgressStore.dayKey(DateTime.now());
  if (store.updateOfferedDay == hoje) return;
  try {
    final info = await InAppUpdate.checkForUpdate();
    if (info.updateAvailability != UpdateAvailability.updateAvailable) return;
    await store.setUpdateOfferedDay(hoje);
    // Google Play's own screen: "update now", with the progress.
    await InAppUpdate.performImmediateUpdate();
  } catch (_) {
    // Not installed from Google Play (tests, sideloaded APK): nothing to do.
  }
}
