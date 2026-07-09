import 'package:episodes_tracker/auth/auth_service.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoogleAuthTokenProvider extends Mock
    implements GoogleAuthTokenProvider {}

void main() {
  late MockGoogleAuthTokenProvider googleAuth;
  late MockFirebaseAuth firebaseAuth;

  setUp(() {
    googleAuth = MockGoogleAuthTokenProvider();
    firebaseAuth = MockFirebaseAuth(
      mockUser: MockUser(
        uid: 'user-123',
        email: 'mario@example.com',
        displayName: 'Mario',
      ),
    );
  });

  group('AuthService.signInWithGoogle', () {
    test('exchanges a Google ID token for a Firebase user', () async {
      when(() => googleAuth.getIdToken()).thenAnswer((_) async => 'id-token');

      final service = AuthService(
        firebaseAuth: firebaseAuth,
        googleAuth: googleAuth,
      );
      final user = await service.signInWithGoogle();

      expect(user.uid, 'user-123');
      expect(firebaseAuth.currentUser?.uid, 'user-123');
    });

    test('propagates SignInCanceledException from the token provider', () {
      when(
        () => googleAuth.getIdToken(),
      ).thenThrow(SignInCanceledException());

      final service = AuthService(
        firebaseAuth: firebaseAuth,
        googleAuth: googleAuth,
      );

      expect(
        () => service.signInWithGoogle(),
        throwsA(isA<SignInCanceledException>()),
      );
    });
  });

  group('AuthService.signOut', () {
    test('signs out of both Firebase and Google', () async {
      when(() => googleAuth.getIdToken()).thenAnswer((_) async => 'id-token');
      when(() => googleAuth.signOut()).thenAnswer((_) async {});

      final service = AuthService(
        firebaseAuth: firebaseAuth,
        googleAuth: googleAuth,
      );
      await service.signInWithGoogle();
      expect(service.currentUser, isNotNull);

      await service.signOut();

      expect(service.currentUser, isNull);
      verify(() => googleAuth.signOut()).called(1);
    });
  });
}
