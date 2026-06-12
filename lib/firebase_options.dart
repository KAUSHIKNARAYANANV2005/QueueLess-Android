import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBkig69nDDjFsTgYWp_aN_kxlfkLiJqRvM',
    appId: '1:378813036718:web:e7147a0ef62a7fc696d53f',
    messagingSenderId: '378813036718',
    projectId: 'queueless-d131e',
    authDomain: 'queueless-d131e.firebaseapp.com',
    storageBucket: 'queueless-d131e.firebasestorage.app',
    measurementId: 'G-4H5SRPJ7RY',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBN2KCBsD70xFN7Oq53IlD6Ijr29g1gtJY',
    appId: '1:378813036718:android:1305e292ef9f959196d53f',
    messagingSenderId: '378813036718',
    projectId: 'queueless-d131e',
    storageBucket: 'queueless-d131e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBN2KCBsD70xFN7Oq53IlD6Ijr29g1gtJY',
    appId: '1:378813036718:ios:queueless_ios_96d53f',
    messagingSenderId: '378813036718',
    projectId: 'queueless-d131e',
    storageBucket: 'queueless-d131e.firebasestorage.app',
    iosBundleId: 'com.queueless.queueless',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBN2KCBsD70xFN7Oq53IlD6Ijr29g1gtJY',
    appId: '1:378813036718:ios:queueless_macos_96d53f',
    messagingSenderId: '378813036718',
    projectId: 'queueless-d131e',
    storageBucket: 'queueless-d131e.firebasestorage.app',
    iosBundleId: 'com.queueless.queueless',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBkig69nDDjFsTgYWp_aN_kxlfkLiJqRvM',
    appId: '1:378813036718:web:e7147a0ef62a7fc696d53f',
    messagingSenderId: '378813036718',
    projectId: 'queueless-d131e',
    authDomain: 'queueless-d131e.firebaseapp.com',
    storageBucket: 'queueless-d131e.firebasestorage.app',
    measurementId: 'G-4H5SRPJ7RY',
  );
}
