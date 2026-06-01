import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    authDomain: 'dsspa-73a47.firebaseapp.com',
    projectId: 'dsspa-73a47',
    storageBucket: 'dsspa-73a47.appspot.com',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    appId: 'YOUR_WEB_APP_ID',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'dsspa-73a47',
    storageBucket: 'dsspa-73a47.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyChHGzYofdgILci5bPdCpFMBclhbESBwT0',
    appId: '1:912364213375:ios:54c08693da5a2a7b8f5b4a',
    messagingSenderId: '912364213375',
    projectId: 'dsspa-73a47',
    storageBucket: 'dsspa-73a47.appspot.com',
    iosClientId:
        '912364213375-ss5k5236r9m9roe5ai3s40su2kag3m1c.apps.googleusercontent.com',
    iosBundleId: 'com.example.statelink',
  );
}
