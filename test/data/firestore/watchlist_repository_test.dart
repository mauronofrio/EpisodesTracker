import 'package:episodes_tracker/data/firestore/watchlist_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late WatchlistRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = WatchlistRepository(firestore: firestore, uid: 'user-1');
  });

  group('shows', () {
    test('addShow then isShowInWatchlist returns true', () async {
      await repository.addShow(1399);
      expect(await repository.isShowInWatchlist(1399), isTrue);
    });

    test('isShowInWatchlist returns false for a show never added', () async {
      expect(await repository.isShowInWatchlist(9999), isFalse);
    });

    test('removeShow removes it from the watchlist', () async {
      await repository.addShow(1399);
      await repository.removeShow(1399);
      expect(await repository.isShowInWatchlist(1399), isFalse);
    });

    test('watchShowIds streams current watchlist show IDs', () async {
      await repository.addShow(1399);
      await repository.addShow(94997);

      final ids = await repository.watchShowIds().first;
      expect(ids, containsAll([1399, 94997]));
    });

    test('adding the same show twice is idempotent', () async {
      await repository.addShow(1399);
      await repository.addShow(1399);
      final ids = await repository.watchShowIds().first;
      expect(ids.where((id) => id == 1399), hasLength(1));
    });
  });

  group('movies', () {
    test('addMovie then isMovieInWatchlist returns true', () async {
      await repository.addMovie(550);
      expect(await repository.isMovieInWatchlist(550), isTrue);
    });

    test('removeMovie removes it from the watchlist', () async {
      await repository.addMovie(550);
      await repository.removeMovie(550);
      expect(await repository.isMovieInWatchlist(550), isFalse);
    });

    test('watchMovieIds streams current watchlist movie IDs', () async {
      await repository.addMovie(550);
      final ids = await repository.watchMovieIds().first;
      expect(ids, [550]);
    });
  });

  test('shows and movies watchlists are independent', () async {
    await repository.addShow(1399);
    expect(await repository.isMovieInWatchlist(1399), isFalse);
  });
}
