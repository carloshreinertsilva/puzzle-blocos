import 'dart:io';

import 'package:puzzle_blocos/services/firebase_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Firebase Analytics on Android starts before Dart and reads the app from
/// `res/values/firebase.xml`: without `google_app_id` there it turns itself
/// off and no statistics arrive. The file must say the same as
/// [FirebaseConfig.android].
void main() {
  final xml = File('android/app/src/main/res/values/firebase.xml')
      .readAsStringSync();

  String? valor(String nome) =>
      RegExp('<string name="$nome"[^>]*>([^<]*)</string>').firstMatch(xml)?[1];

  test('os recursos do Android batem com FirebaseConfig.android', () {
    const o = FirebaseConfig.android;
    expect(valor('google_app_id'), o.appId);
    expect(valor('google_api_key'), o.apiKey);
    expect(valor('gcm_defaultSenderId'), o.messagingSenderId);
    expect(valor('project_id'), o.projectId);
  });

  test('a coleta só começa quando o Dart liga', () {
    final manifesto = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(
      manifesto,
      matches(
        RegExp(
          r'android:name="firebase_analytics_collection_enabled"\s+'
          r'android:value="false"',
        ),
      ),
    );
  });
}
