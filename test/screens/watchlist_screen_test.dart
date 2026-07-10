import 'dart:convert';

import 'package:episodes_tracker/auth/auth_service.dart';
import 'package:episodes_tracker/data/firestore/watched_repository.dart';
import 'package:episodes_tracker/data/firestore/watchlist_repository.dart';
import 'package:episodes_tracker/data/tmdb_client.dart';
import 'package:episodes_tracker/screens/watchlist_screen.dart';
import 'package:episodes_tracker/widgets/home_drawer_scope.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

import '../support/localized_test_app.dart';

class MockGoogleAuthTokenProvider extends Mock
    implements GoogleAuthTokenProvider {}

void main() {
  late AuthService authService;
  late TmdbClient tmdbClient;
  late WatchlistRepository watchlistRepository;
  late WatchedRepository watchedRepository;

  setUp(() {
    final firestore = FakeFirebaseFirestore();
    authService = AuthService(
      firebaseAuth: MockFirebaseAuth(),
      googleAuth: MockGoogleAuthTokenProvider(),
    );
    tmdbClient = TmdbClient(
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode({'page': 1, 'results': [], 'total_results': 0}),
          200,
        ),
      ),
      readAccessToken: 'test-token',
    );
    watchlistRepository = WatchlistRepository(
      firestore: firestore,
      uid: 'user-1',
    );
    watchedRepository = WatchedRepository(firestore: firestore, uid: 'user-1');
  });

  Widget wrap(GlobalKey<WatchlistScreenState> key) {
    return localizedTestApp(
      home: HomeDrawerScope(
        openDrawer: () {},
        child: WatchlistScreen(
          key: key,
          authService: authService,
          tmdbClient: tmdbClient,
          watchlistRepository: watchlistRepository,
          watchedRepository: watchedRepository,
        ),
      ),
    );
  }

  Future<void> waitForDebounce(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'keeps the typed query visible once the search transition happens',
    (tester) async {
      await tester.pumpWidget(wrap(GlobalKey<WatchlistScreenState>()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'batman');
      await waitForDebounce(tester);

      // Now searching: the tab bar is replaced by search results, and the
      // AppBar's leading/bottom shape changed - the typed text must
      // survive that transition, not just the debounce firing.
      expect(find.byType(TabBar), findsNothing);
      expect(find.text('batman'), findsOneWidget);
    },
  );

  testWidgets(
    'exitSearchIfOpen closes an open search (called by HomeShell when '
    'switching tabs)',
    (tester) async {
      final key = GlobalKey<WatchlistScreenState>();
      await tester.pumpWidget(wrap(key));
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'batman');
      await waitForDebounce(tester);

      expect(find.byType(TabBar), findsNothing);
      expect(find.text('batman'), findsOneWidget);

      // Simulates what HomeShell does the moment the user taps the other
      // bottom-nav destination.
      key.currentState!.exitSearchIfOpen();
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('batman'), findsNothing);
    },
  );

  testWidgets('exitSearchIfOpen is a no-op when nothing is being searched', (
    tester,
  ) async {
    final key = GlobalKey<WatchlistScreenState>();
    await tester.pumpWidget(wrap(key));
    await tester.pumpAndSettle();

    expect(find.byType(TabBar), findsOneWidget);

    key.currentState!.exitSearchIfOpen();
    await tester.pumpAndSettle();

    expect(find.byType(TabBar), findsOneWidget);
  });
}
