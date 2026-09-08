// File generated from the Firebase console config files
// (android/app/google-services.json, ios/Runner/GoogleService-Info.plist)
// for the "quizoo-d512b" Firebase project, in the shape `flutterfire configure`
// produces. Do not hand-edit beyond keeping it in sync with those two files —
// re-run `flutterfire configure --project=quizoo-d512b` to regenerate for
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
    apiKey: 'AIzaSyBc9fr_IkNBQnq6MzyUm9ThJ6L9Nx_b3wE',
    appId: '1:724215808400:android:c3a9a54d40d471928f3315',
    messagingSenderId: '724215808400',
    projectId: 'quizoo-d512b',
    storageBucket: 'quizoo-d512b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBaYAygy3kl1lHl1NqCutYz8yXvKpM5HSw',
    appId: '1:724215808400:ios:aadefac488c4fb598f3315',
    messagingSenderId: '724215808400',
    projectId: 'quizoo-d512b',
    storageBucket: 'quizoo-d512b.firebasestorage.app',
    iosBundleId: 'com.quizoo.play',
  );
}
