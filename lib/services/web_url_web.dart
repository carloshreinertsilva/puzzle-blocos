import 'package:web/web.dart' as web;

/// Back to the plain address (`/duelo?s=…` or `/?duelo=…` become `/`).
void clearUrlQuery() {
  web.window.history.replaceState(null, '', '/');
}

void openExternalUrl(String url) {
  web.window.open(url, '_blank');
}
