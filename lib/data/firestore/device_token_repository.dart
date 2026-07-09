import 'package:cloud_firestore/cloud_firestore.dart';

/// Manages the `deviceTokens` subcollection used by the notification job
/// (Plan 2) to know where to send FCM pushes for a given user. A
/// subcollection (rather than a single field) supports multiple devices per
/// user without merge logic.
class DeviceTokenRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  DeviceTokenRepository({
    required FirebaseFirestore firestore,
    required String uid,
  }) : _firestore = firestore,
       _uid = uid;

  CollectionReference<Map<String, dynamic>> get _tokens =>
      _firestore.collection('users/$_uid/deviceTokens');

  Future<void> registerToken(String token) {
    return _tokens.doc(token).set({
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeToken(String token) => _tokens.doc(token).delete();
}
