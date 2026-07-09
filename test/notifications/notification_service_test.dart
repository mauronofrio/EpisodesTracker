import 'package:episodes_tracker/data/firestore/device_token_repository.dart';
import 'package:episodes_tracker/notifications/notification_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

const _grantedSettings = NotificationSettings(
  alert: AppleNotificationSetting.enabled,
  announcement: AppleNotificationSetting.notSupported,
  authorizationStatus: AuthorizationStatus.authorized,
  badge: AppleNotificationSetting.enabled,
  carPlay: AppleNotificationSetting.notSupported,
  lockScreen: AppleNotificationSetting.enabled,
  notificationCenter: AppleNotificationSetting.enabled,
  showPreviews: AppleShowPreviewSetting.always,
  timeSensitive: AppleNotificationSetting.notSupported,
  criticalAlert: AppleNotificationSetting.notSupported,
  sound: AppleNotificationSetting.enabled,
  providesAppNotificationSettings: AppleNotificationSetting.notSupported,
);

const _deniedSettings = NotificationSettings(
  alert: AppleNotificationSetting.disabled,
  announcement: AppleNotificationSetting.notSupported,
  authorizationStatus: AuthorizationStatus.denied,
  badge: AppleNotificationSetting.disabled,
  carPlay: AppleNotificationSetting.notSupported,
  lockScreen: AppleNotificationSetting.disabled,
  notificationCenter: AppleNotificationSetting.disabled,
  showPreviews: AppleShowPreviewSetting.never,
  timeSensitive: AppleNotificationSetting.notSupported,
  criticalAlert: AppleNotificationSetting.notSupported,
  sound: AppleNotificationSetting.disabled,
  providesAppNotificationSettings: AppleNotificationSetting.notSupported,
);

void main() {
  late MockFirebaseMessaging messaging;
  late FakeFirebaseFirestore firestore;
  late DeviceTokenRepository repository;

  setUp(() {
    messaging = MockFirebaseMessaging();
    firestore = FakeFirebaseFirestore();
    repository = DeviceTokenRepository(firestore: firestore, uid: 'user-1');
  });

  test('registers the token when permission is granted', () async {
    when(
      () => messaging.requestPermission(),
    ).thenAnswer((_) async => _grantedSettings);
    when(() => messaging.getToken()).thenAnswer((_) async => 'fcm-token-1');
    when(
      () => messaging.onTokenRefresh,
    ).thenAnswer((_) => const Stream.empty());

    final service = NotificationService(messaging: messaging);
    await service.registerDeviceToken(repository);

    final doc = await firestore
        .collection('users/user-1/deviceTokens')
        .doc('fcm-token-1')
        .get();
    expect(doc.exists, isTrue);
  });

  test('does nothing when permission is denied', () async {
    when(
      () => messaging.requestPermission(),
    ).thenAnswer((_) async => _deniedSettings);

    final service = NotificationService(messaging: messaging);
    await service.registerDeviceToken(repository);

    final snapshot = await firestore
        .collection('users/user-1/deviceTokens')
        .get();
    expect(snapshot.docs, isEmpty);
    verifyNever(() => messaging.getToken());
  });

  test('re-registers the token on refresh', () async {
    when(
      () => messaging.requestPermission(),
    ).thenAnswer((_) async => _grantedSettings);
    when(() => messaging.getToken()).thenAnswer((_) async => 'fcm-token-1');
    when(
      () => messaging.onTokenRefresh,
    ).thenAnswer((_) => Stream.value('fcm-token-2'));

    final service = NotificationService(messaging: messaging);
    await service.registerDeviceToken(repository);
    // Let the onTokenRefresh stream's single event flush.
    await Future<void>.delayed(Duration.zero);

    final snapshot = await firestore
        .collection('users/user-1/deviceTokens')
        .get();
    expect(snapshot.docs.map((d) => d.id), containsAll(['fcm-token-1', 'fcm-token-2']));
  });
}
