import 'package:episodes_tracker/data/firestore/user_profile_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late UserProfileRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = UserProfileRepository(firestore: firestore);
  });

  test('upsertProfile writes displayName, email, photoURL', () async {
    await repository.upsertProfile(
      uid: 'user-1',
      displayName: 'Mario',
      email: 'mario@example.com',
      photoURL: 'https://example.com/photo.jpg',
    );

    final doc = await firestore.collection('users').doc('user-1').get();
    expect(doc.data()!['displayName'], 'Mario');
    expect(doc.data()!['email'], 'mario@example.com');
    expect(doc.data()!['photoURL'], 'https://example.com/photo.jpg');
  });

  test('calling it twice merges rather than overwrites unrelated fields', () async {
    await firestore.collection('users').doc('user-1').set({
      'someOtherField': 'keep-me',
    });

    await repository.upsertProfile(
      uid: 'user-1',
      displayName: 'Mario',
      email: 'mario@example.com',
      photoURL: null,
    );

    final doc = await firestore.collection('users').doc('user-1').get();
    expect(doc.data()!['someOtherField'], 'keep-me');
    expect(doc.data()!['displayName'], 'Mario');
  });
}
