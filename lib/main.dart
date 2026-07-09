import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app.dart';
import 'auth/auth_service.dart';
import 'config/env.dart';
import 'data/firestore/user_profile_repository.dart';
import 'firebase_options.dart';

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
  // Keep the users/{uid} profile document in sync with the signed-in
  // Google account, so it always reflects the latest displayName/photo.
  authService.authStateChanges.listen((user) {
    if (user == null) return;
    userProfileRepository.upsertProfile(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoURL: user.photoURL,
    );
  });

  runApp(EpisodesTrackerApp(authService: authService));
}
