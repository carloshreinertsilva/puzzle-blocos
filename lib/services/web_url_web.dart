import 'package:web/web.dart' as web;

void clearUrlQuery() {
  final path = web.window.location.pathname;
  web.window.history.replaceState(null, '', path);
}
