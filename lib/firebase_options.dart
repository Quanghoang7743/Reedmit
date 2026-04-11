import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web configuration is provided from --dart-define FIREBASE_WEB_*.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC4rTpAfExplFxrjO0aej90sUiGmv-3HGg',
    appId: '1:1095586646526:android:b9ea1f96f4d0fec15d98af',
    messagingSenderId: '1095586646526',
    projectId: 'diary-8572c',
    storageBucket: 'diary-8572c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAV9z6IuVNe5RM6VstYGJCN4eGwrwTuNx4',
    appId: '1:1095586646526:ios:818f7818f705e9175d98af',
    messagingSenderId: '1095586646526',
    projectId: 'diary-8572c',
    storageBucket: 'diary-8572c.firebasestorage.app',
    iosBundleId: 'com.example.reedemit',
  );
}
