import 'admob_stub.dart' if (dart.library.io) 'admob_service.dart' as impl;
import 'ad_service.dart';

/// The AdMob service on Android when it has ad units to use (see
/// [AdConfig]); null elsewhere (web, tests, iOS for now).
AdService? createAdMobService() => impl.createAdMobService();
