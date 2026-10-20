import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'test_bridge.dart';

/// Publishes `window.__bb` with state(), dragPath(slot, row, col) and
/// load(json). Values cross as JSON strings to keep the interop simple.
void installJsBridge(TestBridge bridge) {
  final api = JSObject();
  api['state'] = (() => bridge.stateJson().toJS).toJS;
  api['dragPath'] = ((JSNumber slot, JSNumber row, JSNumber col) => jsonEncode(
    bridge.dragPath(slot.toDartInt, row.toDartInt, col.toDartInt),
  ).toJS).toJS;
  api['load'] = ((JSString json) => bridge.load(json.toDart).toJS).toJS;
  globalContext['__bb'] = api;
}
