import 'package:episodes_tracker/updates/update_banner.dart';
import 'package:episodes_tracker/updates/update_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
        return http.Response(
          '{"tag_name": "$tagName", "assets": []}',
          200,
        );
      }),
      owner: 'mauronofrio',
      repo: 'EpisodesTracker',
    );
  }

  testWidgets(
    'shows the banner when a newer release is found, and reopens it via '
    'the persistent icon after dismissal',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UpdateBanner(
            updateChecker: checkerReturning('v2.0.0'),
            child: const Scaffold(body: Text('home')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MaterialBanner), findsOneWidget);
      expect(find.text('Nuova versione disponibile: v2.0.0'), findsOneWidget);
      expect(find.byIcon(Icons.system_update), findsNothing);

      await tester.tap(find.text('Più tardi'));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialBanner), findsNothing);
      expect(find.byIcon(Icons.system_update), findsOneWidget);
      // The underlying app content must stay visible/usable behind the icon.
      expect(find.text('home'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.system_update));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialBanner), findsOneWidget);
      expect(find.byIcon(Icons.system_update), findsNothing);
    },
  );

  testWidgets('shows neither banner nor icon when already up to date', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UpdateBanner(
          updateChecker: checkerReturning('v1.0.0'),
          child: const Scaffold(body: Text('home')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialBanner), findsNothing);
    expect(find.byIcon(Icons.system_update), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });
}
