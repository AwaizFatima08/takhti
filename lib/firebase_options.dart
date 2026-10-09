// Firebase options for project takhti-grow-homilabs (Android only).
// Written from `firebase apps:sdkconfig`; regenerate if the Firebase app changes.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError('Takhti Grow is configured for Android only.');
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDrBkedjHEmyvY8nHwh55uGSAcpU3p4Iq4',
    appId: '1:6197077163:android:d6d9f0fdb5f61a6e6003ee',
    messagingSenderId: '6197077163',
    projectId: 'takhti-grow-homilabs',
    storageBucket: 'takhti-grow-homilabs.firebasestorage.app',
  );
}
