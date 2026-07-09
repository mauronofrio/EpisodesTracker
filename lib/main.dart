import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app.dart';
import 'auth/auth_service.dart';
import 'config/env.dart';
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

  runApp(EpisodesTrackerApp(authService: authService));
}
