import 'package:episodes_tracker/updates/update_banner.dart';
import 'package:episodes_tracker/updates/update_checker.dart';
import 'package:episodes_tracker/widgets/update_indicator_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../support/localized_test_app.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Episodes Tracker',
      packageName: 'com.mauronofrio.episodes_tracker',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  UpdateChecker checkerReturning(String tagName) {
    return UpdateChecker(
      httpClient: MockClient((request) async {
        return http.Response('{"tag_name": "$tagName", "assets": []}', 200);
      }),
      owner: 'mauronofrio',
      repo: 'EpisodesTracker',
    );
  }

  Widget wrap(UpdateChecker checker) {
    return localizedTestApp(
      home: UpdateBanner(
        updateChecker: checker,
        child: Scaffold(
          appBar: AppBar(actions: [const UpdateIndicatorButton()]),
        ),
      ),
    );
  }

  testWidgets('renders nothing when already up to date', (tester) async {
    await tester.pumpWidget(wrap(checkerReturning('v1.0.0')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.system_update_outlined), findsNothing);
  });

  testWidgets(
    'shows the icon when a newer release exists, and reopens the same '
    'centered dialog (not a new route) on tap after the automatic one '
    'is closed',
    (tester) async {
      await tester.pumpWidget(wrap(checkerReturning('v2.0.0')));
      await tester.pumpAndSettle();

      // UpdateBanner already auto-opened the dialog once on startup.
      expect(find.byIcon(Icons.system_update_outlined), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Chiudi'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);

      await tester.tap(find.byIcon(Icons.system_update_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('È disponibile la versione v2.0.0.'), findsOneWidget);

      await tester.tap(find.text('Chiudi'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      // The underlying screen (with the button) is still there - it was a
      // dialog, not a full-page navigation.
      expect(find.byIcon(Icons.system_update_outlined), findsOneWidget);
    },
  );
}
