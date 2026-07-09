import 'dart:convert';

import 'package:episodes_tracker/data/firestore/watched_repository.dart';
import 'package:episodes_tracker/data/firestore/watchlist_repository.dart';
import 'package:episodes_tracker/data/tmdb_client.dart';
import 'package:episodes_tracker/widgets/search_results_list.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _searchResponse(String query) {
  return http.Response(
    jsonEncode({
      'page': 1,
      'results': query == 'breaking'
          ? [
              {
                'id': 1396,
                'media_type': 'tv',
                'name': 'Breaking Bad',
                'poster_path': null,
                'first_air_date': '2008-01-20',
                'overview': '',
              },
            ]
          : [],
      'total_pages': 1,
      'total_results': query == 'breaking' ? 1 : 0,
    }),
    200,
  );
}

void main() {
  late WatchlistRepository watchlistRepository;
  late WatchedRepository watchedRepository;

  setUp(() {
    final firestore = FakeFirebaseFirestore();
    watchlistRepository = WatchlistRepository(
      firestore: firestore,
      uid: 'user-1',
    );
    watchedRepository = WatchedRepository(firestore: firestore, uid: 'user-1');
  });

  testWidgets('shows results for the initial query', (tester) async {
    final tmdbClient = TmdbClient(
      httpClient: MockClient(
        (request) async =>
            _searchResponse(request.url.queryParameters['query']!),
      ),
      readAccessToken: 'test-token',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchResultsList(
            query: 'breaking',
            tmdbClient: tmdbClient,
            watchlistRepository: watchlistRepository,
            watchedRepository: watchedRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Breaking Bad'), findsOneWidget);
  });

  testWidgets('re-fetches when the query changes', (tester) async {
    final tmdbClient = TmdbClient(
      httpClient: MockClient(
        (request) async =>
            _searchResponse(request.url.queryParameters['query']!),
      ),
      readAccessToken: 'test-token',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchResultsList(
            query: 'breaking',
            tmdbClient: tmdbClient,
            watchlistRepository: watchlistRepository,
            watchedRepository: watchedRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Breaking Bad'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchResultsList(
            query: 'nothing-matches',
            tmdbClient: tmdbClient,
            watchlistRepository: watchlistRepository,
            watchedRepository: watchedRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Breaking Bad'), findsNothing);
    expect(find.text('Nessun risultato'), findsOneWidget);
  });

  testWidgets('shows an error message when the search fails', (tester) async {
    final tmdbClient = TmdbClient(
      httpClient: MockClient(
        (request) async => http.Response('server error', 500),
      ),
      readAccessToken: 'test-token',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchResultsList(
            query: 'breaking',
            tmdbClient: tmdbClient,
            watchlistRepository: watchlistRepository,
            watchedRepository: watchedRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Errore'), findsOneWidget);
  });
}
