import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../l10n/idioma.dart';
import 'duelos_servidor.dart';

/// Tells the other player of a duel, by a notification on their phone,
/// through the function on Vercel (`api/duelo-aviso.js`):
/// - a friend answered their challenge (or did better);
/// - a friend challenged them back.
///
/// Each phone leaves its notification address in `aparelhos/{uid}` (only
/// Android for now). Nothing here ever stops the game: without a server, a
/// connection or a phone to tell, it quietly does nothing.
abstract final class DueloAviso {
  static const _endereco = 'https://capiblocks.vercel.app/api/duelo-aviso';

  /// Off in tests and the browser tests (the server there is in memory).
  static bool get _ligado => DuelosServidor.atual is DuelosFirebase;

  /// A friend's answer `respostas/[id]` was just sent.
  static Future<void> resposta(String id) => _chamar('resposta', id);

  /// The challenge back `duelos/[id]` was just created.
  static Future<void> revanche(String id) => _chamar('revanche', id);

  static Future<void> _chamar(String tipo, String id) async {
    if (!_ligado) return;
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return;
      await http
          .post(
            Uri.parse(_endereco),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': token, 'tipo': tipo, 'id': id}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Duelos: aviso: $e');
    }
  }

  /// Leaves this phone's notification [token] and the game's language
  /// where the function finds them.
  static Future<void> registrarAparelho(String token) async {
    if (!_ligado) return;
    try {
      final uid = await DuelosSync.preparar();
      if (uid == null) return;
      await FirebaseFirestore.instance.collection('aparelhos').doc(uid).set({
        'token': token,
        'idioma': Lingua.idioma.name,
        'em': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Duelos: aparelho: $e');
    }
  }
}
