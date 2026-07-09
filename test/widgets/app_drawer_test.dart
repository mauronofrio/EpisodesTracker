// test/widgets/app_drawer_test.dart
import 'package:episodes_tracker/auth/auth_service.dart';
import 'package:episodes_tracker/config/locale_controller.dart';
import 'package:episodes_tracker/widgets/app_drawer.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/localized_test_app.dart';

class MockGoogleAuthTokenProvider extends Mock
    implements GoogleAuthTokenProvider {}

void main() {
  late AuthService authService;
  late LocaleController localeController;

  setUp(() async {
    final firebaseAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'user-1',
        email: 'mario@example.com',
        displayName: 'Mario',
      ),
    );
    authService = AuthService(
      firebaseAuth: firebaseAuth,
      googleAuth: MockGoogleAuthTokenProvider(),
    );
    SharedPreferences.setMockInitialValues({'locale': 'it'});
    final prefs = await SharedPreferences.getInstance();
    localeController = await LocaleController.load(
      prefs: prefs,
      deviceLocale: const Locale('it'),
    );
  });

  Widget wrap() {
    return localizedTestApp(
      home: LocaleControllerScope(
        controller: localeController,
        child: Scaffold(
          endDrawer: AppDrawer(authService: authService),
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openDrawer(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the signed-in account name and email', (tester) async {
    await tester.pumpWidget(wrap());
    await openDrawer(tester);

    expect(find.text('Mario'), findsOneWidget);
    expect(find.text('mario@example.com'), findsOneWidget);
  });

  testWidgets('shows GitHub link, language switch, and sign-out tiles', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await openDrawer(tester);

    expect(find.text('Progetto GitHub'), findsOneWidget);
    expect(find.text('Italiano / English'), findsOneWidget);
    expect(find.text('Esci'), findsOneWidget);
  });

  testWidgets('tapping sign-out opens the confirmation dialog', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await openDrawer(tester);

    await tester.tap(find.text('Esci'));
    await tester.pumpAndSettle();

    expect(
      find.text('Vuoi disconnetterti da questo account?'),
      findsOneWidget,
    );
  });

  testWidgets('toggling the language switch updates the LocaleController', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await openDrawer(tester);

    expect(localeController.value, const Locale('it'));

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(localeController.value, const Locale('en'));
  });
}
