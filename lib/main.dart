import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app.dart';
import 'auth/auth_service.dart';
import 'config/env.dart';
import 'data/firestore/device_token_repository.dart';
import 'data/firestore/user_profile_repository.dart';
import 'firebase_options.dart';
import 'notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final googleAuth = GoogleSignInTokenProvider(GoogleSignIn.instance);
  await googleAuth.initialize(
    serverClientId: Env.googleSignInServerClientId,
  );
  final authService = AuthService(
    firebaseAuth: FirebaseAuth.instance,
    googleAuth: googleAuth,
  );

  final userProfileRepository = UserProfileRepository(
    firestore: FirebaseFirestore.instance,
  );
  final notificationService = NotificationService();
  // Keep the users/{uid} profile document in sync with the signed-in
  // Google account, and register this device's FCM token, every time the
  // sign-in state changes to a real user. On sign-out, stop listening for
  // token refreshes so a stale subscription doesn't write to the
  // now-signed-out user's Firestore doc (relevant on this app's shared
  // 2-3 user devices).
  authService.authStateChanges.listen((user) async {
    if (user == null) {
      await notificationService.stopListening();
      return;
    }
    try {
      await userProfileRepository.upsertProfile(
        uid: user.uid,
        displayName: user.displayName,
        email: user.email,
        photoURL: user.photoURL,
      );
    } catch (e) {
      debugPrint('Failed to upsert user profile for ${user.uid}: $e');
    }
    try {
      await notificationService.registerDeviceToken(
        DeviceTokenRepository(
          firestore: FirebaseFirestore.instance,
          uid: user.uid,
        ),
      );
    } catch (e) {
      debugPrint('Failed to register device token for ${user.uid}: $e');
    }
  });

  runApp(
    EpisodesTrackerApp(
      authService: authService,
      notificationService: notificationService,
    ),
  );
}
