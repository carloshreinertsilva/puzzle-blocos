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
  globalContext['__bb'] = api;
}
