import 'package:episodes_tracker/data/firestore/device_token_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late DeviceTokenRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = DeviceTokenRepository(firestore: firestore, uid: 'user-1');
  });

  test('registerToken creates a document keyed by the token', () async {
    await repository.registerToken('token-abc');

    final doc = await firestore
        .collection('users/user-1/deviceTokens')
        .doc('token-abc')
        .get();
    expect(doc.exists, isTrue);
  });

  test('removeToken deletes the document', () async {
    await repository.registerToken('token-abc');
    await repository.removeToken('token-abc');

    final doc = await firestore
        .collection('users/user-1/deviceTokens')
        .doc('token-abc')
        .get();
    expect(doc.exists, isFalse);
  });

  test('multiple devices can be registered independently', () async {
    await repository.registerToken('token-a');
    await repository.registerToken('token-b');

    final snapshot = await firestore
        .collection('users/user-1/deviceTokens')
        .get();
    expect(snapshot.docs, hasLength(2));
  });
}
