import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// The one piece of ad pacing that outlives the app process: how many
/// interstitial break points this install has ever reached, which is what the
/// "no interstitial on the first few breaks" grace period counts against.
class AdsPacingStore {
  AdsPacingStore(this._preferences);

  final SharedPreferences _preferences;

  static const _lifetimeBreaksKey = 'ads.lifetimeBreaks';

  int get lifetimeBreaks => _preferences.getInt(_lifetimeBreaksKey) ?? 0;

  void recordBreak() {
    unawaited(_preferences.setInt(_lifetimeBreaksKey, lifetimeBreaks + 1));
  }
}
