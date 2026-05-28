import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDewMFw0tsQL01KOj0ODudS6ABpoSBLer0',
    appId: '1:238542833918:web:4c9aff7a7c259e17143daf',
    messagingSenderId: '238542833918',
    projectId: 'faarfannaa-obbolootaa',
    authDomain: 'faarfannaa-obbolootaa.firebaseapp.com',
    storageBucket: 'faarfannaa-obbolootaa.firebasestorage.app',
    measurementId: 'G-NHZ0Y73Q90',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAU46xIZoPK0POy-6BgQWis_uQjUUhVymM',
    appId: '1:238542833918:android:40d6241865702890143daf',
    messagingSenderId: '238542833918',
    projectId: 'faarfannaa-obbolootaa',
    storageBucket: 'faarfannaa-obbolootaa.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCAv9tBaJRj4An5qAaJAPSEINiemIHbs_Y',
    appId: '1:238542833918:ios:9e610c35fcfce2a1143daf',
    messagingSenderId: '238542833918',
    projectId: 'faarfannaa-obbolootaa',
    storageBucket: 'faarfannaa-obbolootaa.firebasestorage.app',
    iosBundleId: 'com.example.faarfannaaObbolootaa',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCAv9tBaJRj4An5qAaJAPSEINiemIHbs_Y',
    appId: '1:238542833918:ios:9e610c35fcfce2a1143daf',
    messagingSenderId: '238542833918',
    projectId: 'faarfannaa-obbolootaa',
    storageBucket: 'faarfannaa-obbolootaa.firebasestorage.app',
    iosBundleId: 'com.example.faarfannaaObbolootaa',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDewMFw0tsQL01KOj0ODudS6ABpoSBLer0',
    appId: '1:238542833918:web:35060cb4d2451058143daf',
    messagingSenderId: '238542833918',
    projectId: 'faarfannaa-obbolootaa',
    authDomain: 'faarfannaa-obbolootaa.firebaseapp.com',
    storageBucket: 'faarfannaa-obbolootaa.firebasestorage.app',
    measurementId: 'G-BZ35PV3FK8',
  );
}
