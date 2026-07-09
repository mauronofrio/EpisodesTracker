import 'package:episodes_tracker/auth/auth_service.dart';
import 'package:episodes_tracker/screens/login_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/localized_test_app.dart';

class MockGoogleAuthTokenProvider extends Mock
    implements GoogleAuthTokenProvider {}

void main() {
  late AuthService authService;

  setUp(() {
    authService = AuthService(
      firebaseAuth: MockFirebaseAuth(),
      googleAuth: MockGoogleAuthTokenProvider(),
    );
  });

  testWidgets('renders the Italian tagline and sign-in button by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(home: LoginScreen(authService: authService)),
    );

    expect(
      find.text('Serie e film che segui, in un unico posto.'),
      findsOneWidget,
    );
    expect(find.text('Accedi con Google'), findsOneWidget);
  });

  testWidgets(
    'renders the English tagline and sign-in button when the locale is '
    'English',
    (tester) async {
      await tester.pumpWidget(
        localizedTestApp(
          locale: const Locale('en'),
          home: LoginScreen(authService: authService),
        ),
      );

      expect(
        find.text('Series and movies you follow, all in one place.'),
        findsOneWidget,
      );
      expect(find.text('Sign in with Google'), findsOneWidget);
    },
  );
}
