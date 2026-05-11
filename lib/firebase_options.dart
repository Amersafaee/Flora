// File generated from google-services.json — do not commit to public repos.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not configured.');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDC94PXNxLYGEY9vpqSs-QHXFfN3cJkmTY',
    appId: '1:731501257345:android:6cc054a6ff3d51ac50e380',
    messagingSenderId: '731501257345',
    projectId: 'flora-99ff7',
    storageBucket: 'flora-99ff7.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA9dWCgxiHv_v_8vp4ZziKiQXOGFQpobZ8',
    appId: '1:731501257345:ios:9f61ff7cb5906e1150e380',
    messagingSenderId: '731501257345',
    projectId: 'flora-99ff7',
    storageBucket: 'flora-99ff7.firebasestorage.app',
    iosClientId:
        '731501257345-vhhbs98n2ucjss0jmb0u1aa220jvae5m.apps.googleusercontent.com',
    iosBundleId: 'ios.app.digitalConservatory',
  );
}

