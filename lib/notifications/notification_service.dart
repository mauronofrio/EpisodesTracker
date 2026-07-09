import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../data/firestore/device_token_repository.dart';

/// Requests notification permission, registers/refreshes the FCM device
/// token in Firestore, and exposes the foreground-message stream. Actual
/// push delivery and the "should we notify" decision live in the
/// GitHub Actions job (Plan 2) — this class only wires the client side.
class NotificationService {
  final FirebaseMessaging _messaging;
  StreamSubscription<String>? _tokenRefreshSubscription;

  NotificationService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  /// Call once after sign-in, with the repository scoped to the signed-in
  /// user. No-ops (leaves no token registered) if the user denies the
  /// permission prompt. Cancels any subscription from a previous call
  /// (e.g. a different user on a shared device) before creating a new one,
  /// so a refreshed token never lands in the wrong user's Firestore doc.
  Future<void> registerDeviceToken(DeviceTokenRepository repository) async {
    final settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    final token = await _messaging.getToken();
    if (token != null) {
      await repository.registerToken(token);
    }

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      repository.registerToken,
    );
  }

  /// Call on sign-out so a stale subscription bound to the now-signed-out
  /// user's repository doesn't keep writing token refreshes to their doc.
  Future<void> stopListening() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }

  /// Messages received while the app is in the foreground. Background/
  /// terminated-state notifications are shown automatically by the OS via
  /// FCM's "notification" payload and need no app code.
  Stream<RemoteMessage> get onForegroundMessage => FirebaseMessaging.onMessage;
}
