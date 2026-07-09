import 'dart:async';
import 'dart:convert';

import 'package:episodes_tracker/data/firestore/watched_repository.dart';
import 'package:episodes_tracker/data/firestore/watchlist_repository.dart';
import 'package:episodes_tracker/data/models/search_result.dart';
import 'package:episodes_tracker/data/tmdb_client.dart';
import 'package:episodes_tracker/screens/detail_screen.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchlistRepository extends Mock implements WatchlistRepository {}

void main() {
  testWidgets(
    'does not call setState after the widget is disposed mid-load',
    (tester) async {
      final completer = Completer<http.Response>();
      final mockClient = MockClient((request) => completer.future);
      final tmdbClient = TmdbClient(
        httpClient: mockClient,
        readAccessToken: 'test-token',
      );
      final firestore = FakeFirebaseFirestore();
      final watchlistRepository = WatchlistRepository(
        firestore: firestore,
        uid: 'user-1',
      );
      final watchedRepository = WatchedRepository(
        firestore: firestore,
        uid: 'user-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DetailScreen(
            tmdbId: 1399,
            mediaType: MediaType.tv,
            tmdbClient: tmdbClient,
            watchlistRepository: watchlistRepository,
            watchedRepository: watchedRepository,
          ),
        ),
      );

      // Simulate the user navigating away before the TMDB call resolves:
      // replace the whole widget tree, disposing DetailScreen.
      await tester.pumpWidget(const SizedBox());

      // Now the in-flight HTTP call fails (or succeeds) after disposal.
      completer.completeError(Exception('network error'));
      await tester.pump();

      // Before the fix, this throws "setState() called after dispose()".
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reverts the optimistic watchlist toggle and shows an error when the write fails',
    (tester) async {
      final mockClient = MockClient(
        (request) async => http.Response(
          jsonEncode({
            'id': 550,
            'title': 'Fight Club',
            'overview': 'An insomniac office worker...',
            'poster_path': null,
            'backdrop_path': null,
            'release_date': '1999-10-15',
            'runtime': 139,
            'status': 'Released',
          }),
          200,
        ),
      );
      final tmdbClient = TmdbClient(
        httpClient: mockClient,
        readAccessToken: 'test-token',
      );
      final watchlistRepository = MockWatchlistRepository();
      when(
        () => watchlistRepository.isMovieInWatchlist(550),
      ).thenAnswer((_) async => false);
      when(
        () => watchlistRepository.addMovie(550),
      ).thenThrow(Exception('offline'));
      final watchedRepository = WatchedRepository(
        firestore: FakeFirebaseFirestore(),
        uid: 'user-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DetailScreen(
            tmdbId: 550,
            mediaType: MediaType.movie,
            tmdbClient: tmdbClient,
            watchlistRepository: watchlistRepository,
            watchedRepository: watchedRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aggiungi a watchlist'), findsOneWidget);

      await tester.tap(find.text('Aggiungi a watchlist'));
      await tester.pumpAndSettle();

      // The optimistic flip to "Nella watchlist" is reverted once the
      // write fails, and the failure is surfaced instead of silently
      // leaving the UI stuck on the wrong (never-persisted) state.
      expect(find.text('Aggiungi a watchlist'), findsOneWidget);
      expect(find.text('Nella watchlist'), findsNothing);
      expect(find.textContaining('Errore'), findsOneWidget);
    },
  );

  testWidgets(
    'shows the upcoming episode when caught up but TMDB has one scheduled',
    (tester) async {
      final mockClient = MockClient(
        (request) async => http.Response(
          jsonEncode({
            'id': 94997,
            'name': 'House of the Dragon',
            'overview': 'Targaryen civil war.',
            'poster_path': null,
            'backdrop_path': null,
            'number_of_seasons': 0,
            'number_of_episodes': 0,
            'status': 'Returning Series',
            // No aired-but-unwatched episode (no seasons listed at all
            // here, so computeShowProgress's nextToWatch is null), but
            // TMDB still reports a scheduled next episode.
            'next_episode_to_air': {
              'id': 7196567,
              'name': 'Episode 4',
              'overview': '',
              'air_date': '2026-07-19',
              'episode_number': 4,
              'season_number': 3,
            },
            'last_episode_to_air': null,
            'seasons': [],
          }),
          200,
        ),
      );
      final tmdbClient = TmdbClient(
        httpClient: mockClient,
        readAccessToken: 'test-token',
      );
      final watchlistRepository = MockWatchlistRepository();
      when(
        () => watchlistRepository.isShowInWatchlist(94997),
      ).thenAnswer((_) async => false);
      final watchedRepository = WatchedRepository(
        firestore: FakeFirebaseFirestore(),
        uid: 'user-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DetailScreen(
            tmdbId: 94997,
            mediaType: MediaType.tv,
            tmdbClient: tmdbClient,
            watchlistRepository: watchlistRepository,
            watchedRepository: watchedRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sei aggiornato'), findsOneWidget);
      expect(
        find.text('Prossimo episodio: S03E04 - Episode 4 (2026-07-19)'),
        findsOneWidget,
      );
      expect(
        find.text('Sei aggiornato con tutti gli episodi usciti'),
        findsNothing,
      );
    },
  );
}
