// Generated Firebase config for the namma-empire project.
// Regenerate with: flutterfire configure --project=namma-empire
//
// ignore_for_file: type=lint

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for '
          '$defaultTargetPlatform. Run `flutterfire configure`.',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDw0kG3E_MRKYUVu_MBK3VQCfWxh0GKTa4',
    appId: '1:1075476022217:ios:f5d7233e7f0d39237b1e18',
    messagingSenderId: '1075476022217',
    projectId: 'namma-empire',
    storageBucket: 'namma-empire.firebasestorage.app',
    androidClientId: '1075476022217-banuda446jqf2ehbkg7qo9ftqom1nplq.apps.googleusercontent.com',
    iosClientId: '1075476022217-hpbiuphm9988nca0rhkpjr60n7l9a7eh.apps.googleusercontent.com',
    iosBundleId: 'com.example.nammasignPhase1',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA3t5DEojmNX0Tz9qWZSyyuxZsKXrC20q0',
    appId: '1:1075476022217:android:c12cb4939c8a3b3b7b1e18',
    messagingSenderId: '1075476022217',
    projectId: 'namma-empire',
    storageBucket: 'namma-empire.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD3HMbSSuWXDY7xt1YbwI90tUyxMo7jmjA',
    appId: '1:1075476022217:web:5d6f546e93f41f817b1e18',
    messagingSenderId: '1075476022217',
    projectId: 'namma-empire',
    authDomain: 'namma-empire.firebaseapp.com',
    storageBucket: 'namma-empire.firebasestorage.app',
    measurementId: 'G-WL5EM753L3',
  );

}