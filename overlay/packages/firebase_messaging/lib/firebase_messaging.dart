/// Stand-in for package:firebase_messaging.
///
/// Keeps the names upstream's Dart code uses. On iOS, permission and the
/// APNs token come from package:iphoneblog_native, which asks Apple directly.
/// No Google service is contacted. FCM (Android) is not available.
library;

import 'dart:async';

import 'package:iphoneblog_native/iphoneblog_native.dart';

class RemoteMessage {
  const RemoteMessage({this.data = const {}, this.messageId});
  final Map<String, dynamic> data;
  final String? messageId;
}

typedef BackgroundMessageHandler = Future<void> Function(RemoteMessage message);

enum AuthorizationStatus { authorized, denied, notDetermined, provisional }

class NotificationSettings {
  const NotificationSettings({required this.authorizationStatus});
  final AuthorizationStatus authorizationStatus;
}

class FirebaseMessaging {
  FirebaseMessaging._();

  static final FirebaseMessaging instance = FirebaseMessaging._();

  /// No FCM: never emits.
  static Stream<RemoteMessage> get onMessage => const Stream.empty();

  /// No FCM: the handler is never called.
  static void onBackgroundMessage(BackgroundMessageHandler handler) {}

  /// iOS hands out a new token through the same registration call; nothing to stream.
  Stream<String> get onTokenRefresh => const Stream.empty();

  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
  }) async {
    final status = switch (await IphoneblogNative.requestNotificationPermission()) {
      'authorized' => AuthorizationStatus.authorized,
      'denied' => AuthorizationStatus.denied,
      'provisional' => AuthorizationStatus.provisional,
      _ => AuthorizationStatus.notDetermined,
    };
    return NotificationSettings(authorizationStatus: status);
  }

  /// No FCM.
  Future<String?> getToken({String? vapidKey}) async => null;

  /// Returns null when iOS gives no answer within 30 seconds,
  /// so a missing token never blocks the app.
  Future<String?> getAPNSToken() => IphoneblogNative.apnsToken()
    .timeout(const Duration(seconds: 30), onTimeout: () => null);
}
