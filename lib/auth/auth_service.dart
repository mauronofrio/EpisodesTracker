import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';

/// Thrown when the user cancels the Google Sign-In flow (not an error the
/// UI should surface as a failure).
class SignInCanceledException implements Exception {}

/// Abstraction over the Google Sign-In SDK, isolated behind an interface so
/// [AuthService] can be unit tested without depending on platform channels.
abstract class GoogleAuthTokenProvider {
  Future<String> getIdToken();
  Future<void> signOut();
}

/// Real implementation backed by the `google_sign_in` plugin (7.x,
/// event-stream/`authenticate()`-based API).
class GoogleSignInTokenProvider implements GoogleAuthTokenProvider {
  final GoogleSignIn _googleSignIn;

  GoogleSignInTokenProvider(this._googleSignIn);

  /// Must be called once before [getIdToken] (e.g. in `main()`).
  Future<void> initialize({required String serverClientId}) {
    return _googleSignIn.initialize(serverClientId: serverClientId);
  }

  @override
  Future<String> getIdToken() async {
    final GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw SignInCanceledException();
      }
      rethrow;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw StateError('Google Sign-In did not return an ID token');
    }
    return idToken;
  }

  @override
  Future<void> signOut() => _googleSignIn.signOut();
}

/// Exchanges a Google ID token for a Firebase session and exposes the
/// current-user/auth-state surface the rest of the app depends on.
class AuthService {
  final fb_auth.FirebaseAuth _firebaseAuth;
  final GoogleAuthTokenProvider _googleAuth;

  AuthService({
    required fb_auth.FirebaseAuth firebaseAuth,
    required GoogleAuthTokenProvider googleAuth,
  }) : _firebaseAuth = firebaseAuth,
       _googleAuth = googleAuth;

  Stream<fb_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  fb_auth.User? get currentUser => _firebaseAuth.currentUser;

  /// Runs the interactive Google Sign-In flow and exchanges the resulting
  /// ID token for a Firebase session. Throws [SignInCanceledException] if
  /// the user dismisses the sign-in UI.
  Future<fb_auth.User> signInWithGoogle() async {
    final idToken = await _googleAuth.getIdToken();
    final credential = fb_auth.GoogleAuthProvider.credential(idToken: idToken);
    final userCredential = await _firebaseAuth.signInWithCredential(
      credential,
    );
    final user = userCredential.user;
    if (user == null) {
      throw StateError('Firebase sign-in did not return a user');
    }
    return user;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleAuth.signOut();
  }
}
