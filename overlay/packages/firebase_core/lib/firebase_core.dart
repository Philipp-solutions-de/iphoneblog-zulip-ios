/// Stand-in for package:firebase_core.
///
/// The iphoneblog build replaces Firebase with direct calls to Apple
/// (package:iphoneblog_native). This package keeps the few names the app
/// imports, so upstream's Dart code compiles unchanged. Nothing here talks
/// to the network.
library;

class FirebaseOptions {
  const FirebaseOptions({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    this.authDomain,
    this.databaseURL,
    this.storageBucket,
    this.measurementId,
    this.iosBundleId,
  });

  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String? authDomain;
  final String? databaseURL;
  final String? storageBucket;
  final String? measurementId;
  final String? iosBundleId;
}

class FirebaseApp {
  const FirebaseApp._(this.options);
  final FirebaseOptions? options;
}

abstract final class Firebase {
  static Future<FirebaseApp> initializeApp({String? name, FirebaseOptions? options}) async {
    return FirebaseApp._(options);
  }
}
