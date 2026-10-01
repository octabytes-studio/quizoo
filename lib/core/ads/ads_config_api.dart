import 'package:firebase_remote_config/firebase_remote_config.dart';

/// The only thing that reads Remote Config on behalf of ads — a thin wrapper
/// so `AdsConfigRepository` can be tested against a mock instead of Firebase.
class AdsConfigApi {
  AdsConfigApi(this._remoteConfig);

  final FirebaseRemoteConfig _remoteConfig;

  bool getBool(String key) => _remoteConfig.getBool(key);

  int getInt(String key) => _remoteConfig.getInt(key);

  String getString(String key) => _remoteConfig.getString(key);
}
