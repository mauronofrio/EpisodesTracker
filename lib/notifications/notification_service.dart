import 'package:firebase_messaging/firebase_messaging.dart';

import '../data/firestore/device_token_repository.dart';

/// Requests notification permission, registers/refreshes the FCM device
/// token in Firestore, and exposes the foreground-message stream. Actual
/// push delivery and the "should we notify" decision live in the
/// GitHub Actions job (Plan 2) — this class only wires the client side.
class NotificationService {
  final FirebaseMessaging _messaging;

  NotificationService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  /// Call once after sign-in, with the repository scoped to the signed-in
  /// user. No-ops (leaves no token registered) if the user denies the
  /// permission prompt.
  Future<void> registerDeviceToken(DeviceTokenRepository repository) async {
    final settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    final token = await _messaging.getToken();
    if (token != null) {
      await repository.registerToken(token);
    }

    _messaging.onTokenRefresh.listen(repository.registerToken);
  }

  /// Messages received while the app is in the foreground. Background/
  /// terminated-state notifications are shown automatically by the OS via
  /// FCM's "notification" payload and need no app code.
  Stream<RemoteMessage> get onForegroundMessage => FirebaseMessaging.onMessage;
}
