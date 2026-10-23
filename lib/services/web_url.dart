import 'web_url_stub.dart'
    if (dart.library.js_interop) 'web_url_web.dart'
    as impl;

/// Drops the query (?duelo=...) from the address bar, so reloading the page
/// opens the game normally instead of the same challenge again.
void clearUrlQuery() => impl.clearUrlQuery();
