// File generated from google-services.json (scms-campus-app).
// Re-generate by running: flutterfire configure --project=scms-campus-app
// or update values manually if firebase project settings change.

// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web. '
        'Run flutterfire configure to add web support.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS. '
          'Run flutterfire configure to add iOS support.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDf1H5JHbPKW5KzW76aoIvxoMi1KKGsrRQ',
    appId: '1:182336575222:android:845f4814f4cde1f3a7fed7',
    messagingSenderId: '182336575222',
    projectId: 'scms-campus-app',
    storageBucket: 'scms-campus-app.firebasestorage.app',
  );
}
