import 'dart:async';

import 'package:flutter/services.dart';

/// Calls into ios/Classes/IphoneblogNativePlugin.swift.
abstract final class IphoneblogNative {
  static const _channel = MethodChannel('de.iphoneblog/native');

  /// Asks for permission to show notifications.
  /// Returns one of 'authorized', 'denied', 'provisional', 'notDetermined'.
  static Future<String> requestNotificationPermission() async {
    return (await _channel.invokeMethod<String>('requestNotificationPermission'))!;
  }

  /// Registers with APNs and returns the device token as lowercase hex,
  /// or null if iOS does not hand one out (simulator, no network).
  static Future<String?> apnsToken() {
    return _channel.invokeMethod<String>('apnsToken');
  }

  /// Opens [url] in an ASWebAuthenticationSession and returns the address
  /// the server redirects to when it uses [callbackScheme].
  /// Throws a [PlatformException] with code 'canceled' when the user closes the sheet.
  static Future<Uri> webAuth(Uri url, {required String callbackScheme}) async {
    final result = await _channel.invokeMethod<String>('webAuth',
      {'url': url.toString(), 'callbackScheme': callbackScheme});
    return Uri.parse(result!);
  }
}
