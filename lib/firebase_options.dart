// lib/firebase_options.dart

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
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDWSOF1ESE9mQceJ-OeVh0qUM-yLCXY9zw",
    authDomain: "trouvezmotel.firebaseapp.com",
    projectId: "trouvezmotel",
    storageBucket: "trouvezmotel.firebasestorage.app",
    messagingSenderId: "15888755082",
    appId: "1:15888755082:web:4a957e0c6a16536f81c073",
    measurementId: "G-HTG8K1C28T",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyDWSOF1ESE9mQceJ-OeVh0qUM-yLCXY9zw",
    authDomain: "trouvezmotel.firebaseapp.com",
    projectId: "trouvezmotel",
    storageBucket: "trouvezmotel.firebasestorage.app",
    messagingSenderId: "15888755082",
    appId: "1:15888755082:web:4a957e0c6a16536f81c073",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyDWSOF1ESE9mQceJ-OeVh0qUM-yLCXY9zw",
    authDomain: "trouvezmotel.firebaseapp.com",
    projectId: "trouvezmotel",
    storageBucket: "trouvezmotel.firebasestorage.app",
    messagingSenderId: "15888755082",
    appId: "1:15888755082:web:4a957e0c6a16536f81c073",
    iosBundleId: "com.example.trouvezmotel",
  );

  static const FirebaseOptions macos = ios;
  static const FirebaseOptions windows = android;
  static const FirebaseOptions linux = android;
}
