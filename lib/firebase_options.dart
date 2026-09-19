// File generated from the Firebase console config files
// (android/app/google-services.json, ios/Runner/GoogleService-Info.plist)
// for the "quizoo-d1b36" Firebase project, in the shape `flutterfire configure`
// produces. Do not hand-edit beyond keeping it in sync with those two files —
// re-run `flutterfire configure --project=quizoo-d1b36` to regenerate for
// real once the FlutterFire CLI is available in this environment.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'quizoo is a mobile-only app (design bible §22).',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAVEb5SRp1Jy3lJmOg92E1oZv8bVK7xGBU',
    appId: '1:943523651627:android:7a46fe7a365885d1698a6e',
    messagingSenderId: '943523651627',
    projectId: 'quizoo-d1b36',
    storageBucket: 'quizoo-d1b36.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDxafPHQA4SIQAx-m6q2dyRbvmu6aibYcQ',
    appId: '1:943523651627:ios:6990d3999a727819698a6e',
    messagingSenderId: '943523651627',
    projectId: 'quizoo-d1b36',
    storageBucket: 'quizoo-d1b36.firebasestorage.app',
    iosBundleId: 'com.quizoo.play',
  );
}
