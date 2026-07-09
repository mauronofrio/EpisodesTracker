import 'dart:async';

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
}
