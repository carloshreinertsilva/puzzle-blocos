import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/hats.dart';
import 'package:puzzle_blocos/core/wardrobe.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:puzzle_blocos/ui/capi.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProgressStore> _store([Map<String, Object> saved = const {}]) async {
  SharedPreferences.setMockInitialValues(saved);
  return ProgressStore.load();
}

void main() {
  test('catalog ids are unique and the old hat ids are kept', () {
    final ids = Wardrobe.catalog.map((c) => c.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final h in CapiHat.values) {
      final c = Wardrobe.byId(h.id);
      expect(c, isNotNull, reason: h.id);
      expect(c!.slot, Slot.cabeca);
      expect(c.hat, h);
    }
  });

  test('collections name real items and an epic prize', () {
    for (final col in Wardrobe.colecoes) {
      for (final id in col.itens) {
        expect(Wardrobe.byId(id), isNotNull, reason: id);
      }
      final premio = Wardrobe.byId(col.premio)!;
      expect(premio.raridade, Raridade.epico);
      expect((premio.fonte as PremioColecao).colecao, col.nome);
    }
  });

  test('nothing paid is random: the chest gives only star items', () {
    for (final c in Wardrobe.catalog) {
      if (c.raridade.index >= Raridade.epico.index) {
        expect(c.fonte, isNot(isA<Estrelas>()), reason: c.id);
      }
    }
  });

  test('every item draws in every mood', () {
    for (final c in Wardrobe.catalog) {
      final look = const CapiLook().wearing(c);
      for (final m in CapiMood.values) {
        final rec = ui.PictureRecorder();
        CapiPainter(
          mood: m,
          t: 0.4,
          hat: look.hat,
          look: look,
        ).paint(Canvas(rec), const Size.square(100));
        rec.endRecording();
      }
    }
  });

  test('buying spends stars, equips and keeps the item', () async {
    final store = await _store({'stars': 30});
    final touca = Wardrobe.byId('touca')!;
    final chef = Wardrobe.byId('chef')!;
    expect(await Wardrobe.buy(store, chef), isFalse, reason: 'too expensive');
    expect(await Wardrobe.buy(store, touca), isTrue);
    expect(store.stars, 30 - Wardrobe.precoComum);
    expect(Wardrobe.owns(store, touca), isTrue);
    expect(await Wardrobe.buy(store, touca), isFalse, reason: 'already owned');
    await Wardrobe.equip(store, touca);
    expect(store.equippedHat, 'touca');

    final oculos = Wardrobe.byId('oculos_sol')!;
    await store.unlockHat(oculos.id);
    await Wardrobe.equip(store, oculos);
    expect(CapiLook.of(store).rosto, 'oculos_sol');
    await Wardrobe.takeOff(store, Slot.rosto);
    expect(CapiLook.of(store).rosto, isNull);
  });

  test('completing a collection gives its prize once', () async {
    final store = await _store();
    for (final id in ['touca', 'cachecol']) {
      await store.unlockHat(id);
    }
    expect(await Wardrobe.awardCollections(store), isEmpty);
    await store.unlockHat('mochila');
    final prizes = await Wardrobe.awardCollections(store);
    expect(prizes.map((p) => p.id), ['neve']);
    expect(await Wardrobe.awardCollections(store), isEmpty);
  });

  test('old saves keep their hats', () async {
    final store = await _store({
      'unlockedHats': ['helmet', 'crown', 'party'],
      'equippedHat': 'crown',
    });
    final look = CapiLook.of(store);
    expect(look.hat, CapiHat.crown);
    expect(look.pelagem, Wardrobe.pelagemPadrao);
    expect(Wardrobe.owns(store, Wardrobe.byId('crown')!), isTrue);
    expect(Wardrobe.owns(store, Wardrobe.byId('caramelo')!), isTrue);
  });
}
