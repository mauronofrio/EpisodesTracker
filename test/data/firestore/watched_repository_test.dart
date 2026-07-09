import 'package:episodes_tracker/data/firestore/watched_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late WatchedRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = WatchedRepository(firestore: firestore, uid: 'user-1');
  });

  group('episodes', () {
    test('markEpisodeWatched then it appears in watchedEpisodeIdsForShow', () async {
      final id = const WatchedEpisodeId(showId: 1399, season: 1, episode: 1);
      await repository.markEpisodeWatched(id);

      final watched = await repository.watchedEpisodeIdsForShow(1399).first;
      expect(watched, contains(id));
    });

    test('watchedEpisodeIdsForShow only returns episodes for that show', () async {
      await repository.markEpisodeWatched(
        const WatchedEpisodeId(showId: 1399, season: 1, episode: 1),
      );
      await repository.markEpisodeWatched(
        const WatchedEpisodeId(showId: 94997, season: 1, episode: 1),
      );

      final watched = await repository.watchedEpisodeIdsForShow(1399).first;
      expect(watched, hasLength(1));
      expect(watched.keys.first.showId, 1399);
    });

    test('a newly-watched episode defaults to not rewatched', () async {
      final id = const WatchedEpisodeId(showId: 1399, season: 1, episode: 1);
      await repository.markEpisodeWatched(id);

      final watched = await repository.watchedEpisodeIdsForShow(1399).first;
      expect(watched[id], isFalse);
    });

    test('setEpisodeRewatched sets and unsets the flag without touching watchedAt', () async {
      final id = const WatchedEpisodeId(showId: 1399, season: 1, episode: 1);
      await repository.markEpisodeWatched(id);

      await repository.setEpisodeRewatched(id, true);
      var watched = await repository.watchedEpisodeIdsForShow(1399).first;
      expect(watched[id], isTrue);

      await repository.setEpisodeRewatched(id, false);
      watched = await repository.watchedEpisodeIdsForShow(1399).first;
      expect(watched[id], isFalse);
    });

    test('markEpisodeUnwatched clears the rewatched flag along with the episode', () async {
      final id = const WatchedEpisodeId(showId: 1399, season: 1, episode: 1);
      await repository.markEpisodeWatched(id);
      await repository.setEpisodeRewatched(id, true);
      await repository.markEpisodeUnwatched(id);
      await repository.markEpisodeWatched(id);

      final watched = await repository.watchedEpisodeIdsForShow(1399).first;
      expect(watched[id], isFalse);
    });

    test('markSeasonWatched marks every given episode number as watched', () async {
      await repository.markSeasonWatched(1399, 1, [1, 2, 3]);

      final watched = await repository.watchedEpisodeIdsForShow(1399).first;
      expect(watched.keys, containsAll([
        const WatchedEpisodeId(showId: 1399, season: 1, episode: 1),
        const WatchedEpisodeId(showId: 1399, season: 1, episode: 2),
        const WatchedEpisodeId(showId: 1399, season: 1, episode: 3),
      ]));
    });

    test('markSeasonWatched only marks the episode numbers passed in (caller filters unaired ones)', () async {
      await repository.markSeasonWatched(1399, 1, [1, 2]);

      final watched = await repository.watchedEpisodeIdsForShow(1399).first;
      expect(watched, hasLength(2));
      expect(
        watched.keys,
        isNot(contains(const WatchedEpisodeId(showId: 1399, season: 1, episode: 3))),
      );
    });

    test('markEpisodeUnwatched removes it', () async {
      final id = const WatchedEpisodeId(showId: 1399, season: 1, episode: 1);
      await repository.markEpisodeWatched(id);
      await repository.markEpisodeUnwatched(id);

      final watched = await repository.watchedEpisodeIdsForShow(1399).first;
      expect(watched, isEmpty);
    });

    test('WatchedEpisodeId equality is by value', () {
      const a = WatchedEpisodeId(showId: 1, season: 2, episode: 3);
      const b = WatchedEpisodeId(showId: 1, season: 2, episode: 3);
      expect(a, equals(b));
      expect(a.docId, '1_2_3');
    });

    test(
      'skips malformed documents instead of erroring the whole stream',
      () async {
        await repository.markEpisodeWatched(
          const WatchedEpisodeId(showId: 1399, season: 1, episode: 1),
        );
        // A doc with a non-int field, as could result from a manual edit
        // or a future migration bug.
        await firestore
            .collection('users/user-1/watched_episodes')
            .doc('1399_1_2')
            .set({'showId': 1399, 'season': 1, 'episode': 'not-a-number'});

        final watched = await repository
            .watchedEpisodeIdsForShow(1399)
            .first;

        expect(watched, hasLength(1));
        expect(
          watched.keys.first,
          const WatchedEpisodeId(showId: 1399, season: 1, episode: 1),
        );
      },
    );
  });

  group('movies', () {
    test('markMovieWatched then isMovieWatched returns true', () async {
      await repository.markMovieWatched(550);
      expect(await repository.isMovieWatched(550), isTrue);
    });

    test('markMovieUnwatched removes it', () async {
      await repository.markMovieWatched(550);
      await repository.markMovieUnwatched(550);
      expect(await repository.isMovieWatched(550), isFalse);
    });

    test('watchedMovieIds streams the current set', () async {
      await repository.markMovieWatched(550);
      await repository.markMovieWatched(551);
      final ids = await repository.watchedMovieIds().first;
      expect(ids, {550, 551});
    });

    test(
      'watchedMovieIds skips non-numeric doc ids instead of erroring the stream',
      () async {
        await repository.markMovieWatched(550);
        await firestore
            .collection('users/user-1/watched_movies')
            .doc('not-a-number')
            .set({'watchedAt': null});

        final ids = await repository.watchedMovieIds().first;

        expect(ids, {550});
      },
    );
  });
}
