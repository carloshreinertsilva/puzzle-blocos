import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'test_bridge.dart';

/// Publishes `window.__bb` with state(), dragPath(slot, row, col),
/// load(json), win() and obraDrag(piece). Values cross as JSON strings to keep the interop simple.
void installJsBridge(TestBridge bridge) {
  final api = JSObject();
  api['state'] = (() => bridge.stateJson().toJS).toJS;
  api['dragPath'] = ((JSNumber slot, JSNumber row, JSNumber col) => jsonEncode(
    bridge.dragPath(slot.toDartInt, row.toDartInt, col.toDartInt),
  ).toJS).toJS;
  api['load'] = ((JSString json) => bridge.load(json.toDart).toJS).toJS;
  api['win'] = (() => bridge.win().toJS).toJS;
  api['blitzSeconds'] = ((
    JSNumber n,
  ) => bridge.blitzSeconds(n.toDartInt).toJS).toJS;
  api['obraDrag'] = ((JSNumber piece) => jsonEncode(
    bridge.obraDrag?.call(piece.toDartInt),
  ).toJS).toJS;
  api['useTool'] =
      ((JSString toolName, JSNumber? r, JSNumber? c, JSNumber? slot) => bridge
              .useTool(
                toolName.toDart,
                r?.toDartInt,
                c?.toDartInt,
                slot?.toDartInt,
              )
              .then((v) => v.toJS)
              .toJS)
          .toJS;
  api['addTool'] =
      ((JSString toolName, JSNumber count) => bridge
              .addTool(toolName.toDart, count.toDartInt)
              .then((_) => true.toJS)
              .toJS)
          .toJS;
  api['placeTower'] = ((
    JSBoolean? perfect,
  ) => bridge.placeTower(perfect?.toDart ?? true).toJS).toJS;
  api['missTower'] = (() => bridge.missTower().toJS).toJS;
  api['earnStars'] = ((
    JSNumber n,
  ) => bridge.earnStars(n.toDartInt).then((_) => true.toJS).toJS).toJS;
  api['equipHat'] = ((
    JSString hatId,
  ) => bridge.equipHat(hatId.toDart).then((_) => true.toJS).toJS).toJS;
  api['unlockHat'] = ((
    JSString hatId,
  ) => bridge.unlockHat(hatId.toDart).then((_) => true.toJS).toJS).toJS;
  api['progressDailyMission'] =
      ((JSNumber index, JSNumber amount) => bridge
              .progressDailyMission(index.toDartInt, amount.toDartInt)
              .then((_) => true.toJS)
              .toJS)
          .toJS;
  api['claimDailyChest'] =
      (() => bridge.claimDailyChest().then((v) => v?.toJS).toJS).toJS;
  globalContext['__bb'] = api;
}
