import 'package:episodes_tracker/updates/update_banner.dart';
import 'package:episodes_tracker/updates/update_checker.dart';
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

  testWidgets('UpdateBanner.of exposes the release once a newer one is found', (
    tester,
  ) async {
    ReleaseInfo? seen;
    await tester.pumpWidget(
      localizedTestApp(
        home: UpdateBanner(
          updateChecker: checkerReturning('v2.0.0'),
          child: Builder(
            builder: (context) {
              seen = UpdateBanner.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(seen, isNull);

    await tester.pumpAndSettle();

    expect(seen?.tagName, 'v2.0.0');
  });

  testWidgets('UpdateBanner.of stays null when already up to date', (
    tester,
  ) async {
    ReleaseInfo? seen;
    await tester.pumpWidget(
      localizedTestApp(
        home: UpdateBanner(
          updateChecker: checkerReturning('v1.0.0'),
          child: Builder(
            builder: (context) {
              seen = UpdateBanner.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(seen, isNull);
  });

  testWidgets('automatically opens the update dialog once on startup', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: UpdateBanner(
          updateChecker: checkerReturning('v2.0.0'),
          child: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );

    expect(find.byType(AlertDialog), findsNothing);

    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('È disponibile la versione v2.0.0.'), findsOneWidget);
  });

  testWidgets('does not reopen the dialog automatically after it is closed', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: UpdateBanner(
          updateChecker: checkerReturning('v2.0.0'),
          child: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Chiudi'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('does not open a dialog when already up to date', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: UpdateBanner(
          updateChecker: checkerReturning('v1.0.0'),
          child: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
