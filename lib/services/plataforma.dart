import 'package:flutter/foundation.dart';

/// The iPhone app (App Store, Game Center), as opposed to Android (Google
/// Play) and the web. Follows defaultTargetPlatform, so tests can set it.
bool get noIPhone => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
