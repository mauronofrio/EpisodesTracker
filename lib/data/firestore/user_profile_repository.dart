import 'package:cloud_firestore/cloud_firestore.dart';

/// Writes the `users/{uid}` profile document. Called once after a
/// successful sign-in; safe to call repeatedly (merges rather than
/// overwrites, and never touches watchlist/watched subcollections).
class UserProfileRepository {
  final FirebaseFirestore _firestore;

  UserProfileRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  Future<void> upsertProfile({
    required String uid,
    required String? displayName,
    required String? email,
    required String? photoURL,
  }) {
    return _firestore.collection('users').doc(uid).set({
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
