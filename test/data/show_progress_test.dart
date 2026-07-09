import 'dart:convert';

import 'package:episodes_tracker/data/firestore/watched_repository.dart';
import 'package:episodes_tracker/data/models/episode.dart';
import 'package:episodes_tracker/data/models/season_summary.dart';
import 'package:episodes_tracker/data/models/tv_show_details.dart';
import 'package:episodes_tracker/data/show_progress.dart';
import 'package:episodes_tracker/data/tmdb_client.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> _episode({
  required int id,
  required int season,
  required int number,
  required String? airDate,
}) => {
  'id': id,
  'name': 'Episode $number',
  'overview': '',
  'air_date': airDate,
  'episode_number': number,
  'season_number': season,
  'still_path': null,
};

http.Response _seasonResponse(int season, List<Map<String, dynamic>> episodes) {
  return http.Response(
    jsonEncode({
      'air_date': '2020-01-01',
      'name': 'Season $season',
      'season_number': season,
      'episodes': episodes,
    }),
    200,
  );
}

TvShowDetails _show({required List<SeasonSummary> seasons}) {
  return TvShowDetails(
    id: 1399,
    name: 'Test Show',
    overview: '',
    posterPath: null,
    backdropPath: null,
    numberOfSeasons: seasons.length,
    numberOfEpisodes: 0,
    status: 'Returning Series',
    nextEpisodeToAir: null,
    lastEpisodeToAir: null,
    seasons: seasons,
  );
}

void main() {
  late FakeFirebaseFirestore firestore;
  late WatchedRepository watchedRepository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    watchedRepository = WatchedRepository(firestore: firestore, uid: 'user-1');
  });

  test('counts only aired episodes and finds no next-to-watch when caught up', () async {
    // "today" is fixed for the test via a far-future air date check below;
    // use dates safely in the past relative to whenever this test runs.
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/season/1')) {
        return _seasonResponse(1, [
          _episode(id: 1, season: 1, number: 1, airDate: '2020-01-01'),
          _episode(id: 2, season: 1, number: 2, airDate: '2020-01-08'),
        ]);
      }
      return http.Response('not found', 404);
    });
    final tmdbClient = TmdbClient(
      httpClient: mockClient,
      readAccessToken: 'test-token',
    );
    final show = _show(
      seasons: [
        const SeasonSummary(
          seasonNumber: 1,
          name: 'Season 1',
          episodeCount: 2,
          posterPath: null,
          airDate: null,
        ),
      ],
    );

    await watchedRepository.markSeasonWatched(1399, 1, [1, 2]);

    final progress = await computeShowProgress(
      tmdbClient: tmdbClient,
      watchedRepository: watchedRepository,
      show: show,
    );

    expect(progress.airedCount, 2);
    expect(progress.watchedCount, 2);
    expect(progress.nextToWatch, isNull);
    expect(progress.watchedCountBySeason, {1: 2});
  });

  test('finds the earliest aired-but-unwatched episode as next-to-watch', () async {
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/season/1')) {
        return _seasonResponse(1, [
          _episode(id: 1, season: 1, number: 1, airDate: '2020-01-01'),
          _episode(id: 2, season: 1, number: 2, airDate: '2020-01-08'),
          _episode(id: 3, season: 1, number: 3, airDate: '2020-01-15'),
        ]);
      }
      return http.Response('not found', 404);
    });
    final tmdbClient = TmdbClient(
      httpClient: mockClient,
      readAccessToken: 'test-token',
    );
    final show = _show(
      seasons: [
        const SeasonSummary(
          seasonNumber: 1,
          name: 'Season 1',
          episodeCount: 3,
          posterPath: null,
          airDate: null,
        ),
      ],
    );

    await watchedRepository.markEpisodeWatched(
      const WatchedEpisodeId(showId: 1399, season: 1, episode: 1),
    );

    final progress = await computeShowProgress(
      tmdbClient: tmdbClient,
      watchedRepository: watchedRepository,
      show: show,
    );

    expect(progress.airedCount, 3);
    expect(progress.watchedCount, 1);
    expect(progress.nextToWatch?.episodeNumber, 2);
  });

  test('excludes episodes with a future air date from airedCount', () async {
    final farFuture = DateTime.now().add(const Duration(days: 365));
    final farFutureDate =
        '${farFuture.year}-${farFuture.month.toString().padLeft(2, '0')}-${farFuture.day.toString().padLeft(2, '0')}';

    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/season/1')) {
        return _seasonResponse(1, [
          _episode(id: 1, season: 1, number: 1, airDate: '2020-01-01'),
          _episode(id: 2, season: 1, number: 2, airDate: farFutureDate),
        ]);
      }
      return http.Response('not found', 404);
    });
    final tmdbClient = TmdbClient(
      httpClient: mockClient,
      readAccessToken: 'test-token',
    );
    final show = _show(
      seasons: [
        const SeasonSummary(
          seasonNumber: 1,
          name: 'Season 1',
          episodeCount: 2,
          posterPath: null,
          airDate: null,
        ),
      ],
    );

    final progress = await computeShowProgress(
      tmdbClient: tmdbClient,
      watchedRepository: watchedRepository,
      show: show,
    );

    expect(progress.airedCount, 1);
    expect(progress.nextToWatch?.episodeNumber, 1);
  });

  test('a season whose TMDB call fails is skipped, not fatal', () async {
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/season/1')) {
        return _seasonResponse(1, [
          _episode(id: 1, season: 1, number: 1, airDate: '2020-01-01'),
        ]);
      }
      if (request.url.path.endsWith('/season/2')) {
        return http.Response('server error', 500);
      }
      return http.Response('not found', 404);
    });
    final tmdbClient = TmdbClient(
      httpClient: mockClient,
      readAccessToken: 'test-token',
    );
    final show = _show(
      seasons: [
        const SeasonSummary(
          seasonNumber: 1,
          name: 'Season 1',
          episodeCount: 1,
          posterPath: null,
          airDate: null,
        ),
        const SeasonSummary(
          seasonNumber: 2,
          name: 'Season 2',
          episodeCount: 5,
          posterPath: null,
          airDate: null,
        ),
      ],
    );

    final progress = await computeShowProgress(
      tmdbClient: tmdbClient,
      watchedRepository: watchedRepository,
      show: show,
    );

    expect(progress.airedCount, 1);
  });

  test('watchedCountBySeason tracks each season independently', () async {
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/season/1')) {
        return _seasonResponse(1, [
          _episode(id: 1, season: 1, number: 1, airDate: '2020-01-01'),
          _episode(id: 2, season: 1, number: 2, airDate: '2020-01-08'),
        ]);
      }
      if (request.url.path.endsWith('/season/2')) {
        return _seasonResponse(2, [
          _episode(id: 3, season: 2, number: 1, airDate: '2021-01-01'),
        ]);
      }
      return http.Response('not found', 404);
    });
    final tmdbClient = TmdbClient(
      httpClient: mockClient,
      readAccessToken: 'test-token',
    );
    final show = _show(
      seasons: [
        const SeasonSummary(
          seasonNumber: 1,
          name: 'Season 1',
          episodeCount: 2,
          posterPath: null,
          airDate: null,
        ),
        const SeasonSummary(
          seasonNumber: 2,
          name: 'Season 2',
          episodeCount: 1,
          posterPath: null,
          airDate: null,
        ),
      ],
    );

    // Watch all of season 1, none of season 2.
    await watchedRepository.markSeasonWatched(1399, 1, [1, 2]);

    final progress = await computeShowProgress(
      tmdbClient: tmdbClient,
      watchedRepository: watchedRepository,
      show: show,
    );

    expect(progress.watchedCountBySeason, {1: 2});
    expect(progress.watchedCountBySeason.containsKey(2), isFalse);
  });

  group('ShowProgress.isSeasonComplete', () {
    test('true once every episode TMDB lists for the season is watched', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/season/1')) {
          return _seasonResponse(1, [
            _episode(id: 1, season: 1, number: 1, airDate: '2020-01-01'),
            _episode(id: 2, season: 1, number: 2, airDate: '2020-01-08'),
          ]);
        }
        return http.Response('not found', 404);
      });
      final tmdbClient = TmdbClient(
        httpClient: mockClient,
        readAccessToken: 'test-token',
      );
      final show = _show(
        seasons: [
          const SeasonSummary(
            seasonNumber: 1,
            name: 'Season 1',
            episodeCount: 2,
            posterPath: null,
            airDate: null,
          ),
        ],
      );

      await watchedRepository.markSeasonWatched(1399, 1, [1, 2]);
      final progress = await computeShowProgress(
        tmdbClient: tmdbClient,
        watchedRepository: watchedRepository,
        show: show,
      );

      expect(progress.isSeasonComplete(1, 2), isTrue);
    });

    test('false when some listed episodes are still unwatched', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/season/1')) {
          return _seasonResponse(1, [
            _episode(id: 1, season: 1, number: 1, airDate: '2020-01-01'),
            _episode(id: 2, season: 1, number: 2, airDate: '2020-01-08'),
          ]);
        }
        return http.Response('not found', 404);
      });
      final tmdbClient = TmdbClient(
        httpClient: mockClient,
        readAccessToken: 'test-token',
      );
      final show = _show(
        seasons: [
          const SeasonSummary(
            seasonNumber: 1,
            name: 'Season 1',
            episodeCount: 2,
            posterPath: null,
            airDate: null,
          ),
        ],
      );

      await watchedRepository.markSeasonWatched(1399, 1, [1]);
      final progress = await computeShowProgress(
        tmdbClient: tmdbClient,
        watchedRepository: watchedRepository,
        show: show,
      );

      expect(progress.isSeasonComplete(1, 2), isFalse);
    });

    test('false for a season with no aired episodes yet', () async {
      final farFuture = DateTime.now().add(const Duration(days: 365));
      final farFutureDate =
          '${farFuture.year}-${farFuture.month.toString().padLeft(2, '0')}-${farFuture.day.toString().padLeft(2, '0')}';
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/season/1')) {
          return _seasonResponse(1, [
            _episode(id: 1, season: 1, number: 1, airDate: farFutureDate),
          ]);
        }
        return http.Response('not found', 404);
      });
      final tmdbClient = TmdbClient(
        httpClient: mockClient,
        readAccessToken: 'test-token',
      );
      final show = _show(
        seasons: [
          const SeasonSummary(
            seasonNumber: 1,
            name: 'Season 1',
            episodeCount: 1,
            posterPath: null,
            airDate: null,
          ),
        ],
      );

      final progress = await computeShowProgress(
        tmdbClient: tmdbClient,
        watchedRepository: watchedRepository,
        show: show,
      );

      expect(progress.isSeasonComplete(1, 1), isFalse);
    });

    test(
      'false for a still-airing season even if every aired episode is watched '
      '(regression: previously used aired count instead of the season total)',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.path.endsWith('/season/3')) {
            return _seasonResponse(3, [
              _episode(id: 1, season: 3, number: 1, airDate: '2026-06-01'),
              _episode(id: 2, season: 3, number: 2, airDate: '2026-06-08'),
              _episode(id: 3, season: 3, number: 3, airDate: '2026-06-15'),
              // Episodes 4-8 not out yet, but TMDB already lists 8 total
              // for the season.
            ]);
          }
          return http.Response('not found', 404);
        });
        final tmdbClient = TmdbClient(
          httpClient: mockClient,
          readAccessToken: 'test-token',
        );
        final show = _show(
          seasons: [
            const SeasonSummary(
              seasonNumber: 3,
              name: 'Season 3',
              episodeCount: 8,
              posterPath: null,
              airDate: null,
            ),
          ],
        );

        await watchedRepository.markSeasonWatched(1399, 3, [1, 2, 3]);
        final progress = await computeShowProgress(
          tmdbClient: tmdbClient,
          watchedRepository: watchedRepository,
          show: show,
        );

        expect(progress.watchedCountBySeason[3], 3);
        expect(progress.isSeasonComplete(3, 8), isFalse);
      },
    );

    test('false when the season has no episodes listed yet (episodeCount 0)', () async {
      final tmdbClient = TmdbClient(
        httpClient: MockClient((_) async => http.Response('not found', 404)),
        readAccessToken: 'test-token',
      );
      final show = _show(
        seasons: [
          const SeasonSummary(
            seasonNumber: 2,
            name: 'Season 2',
            episodeCount: 0,
            posterPath: null,
            airDate: null,
          ),
        ],
      );

      final progress = await computeShowProgress(
        tmdbClient: tmdbClient,
        watchedRepository: watchedRepository,
        show: show,
      );

      expect(progress.isSeasonComplete(2, 0), isFalse);
    });
  });

  group('ShowProgress.isShowComplete', () {
    test('true when every listed season is fully watched', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/season/1')) {
          return _seasonResponse(1, [
            _episode(id: 1, season: 1, number: 1, airDate: '2020-01-01'),
          ]);
        }
        if (request.url.path.endsWith('/season/2')) {
          return _seasonResponse(2, [
            _episode(id: 2, season: 2, number: 1, airDate: '2021-01-01'),
          ]);
        }
        return http.Response('not found', 404);
      });
      final tmdbClient = TmdbClient(
        httpClient: mockClient,
        readAccessToken: 'test-token',
      );
      final seasons = [
        const SeasonSummary(
          seasonNumber: 1,
          name: 'Season 1',
          episodeCount: 1,
          posterPath: null,
          airDate: null,
        ),
        const SeasonSummary(
          seasonNumber: 2,
          name: 'Season 2',
          episodeCount: 1,
          posterPath: null,
          airDate: null,
        ),
      ];
      final show = _show(seasons: seasons);

      await watchedRepository.markSeasonWatched(1399, 1, [1]);
      await watchedRepository.markSeasonWatched(1399, 2, [1]);
      final progress = await computeShowProgress(
        tmdbClient: tmdbClient,
        watchedRepository: watchedRepository,
        show: show,
      );

      expect(progress.isShowComplete(seasons), isTrue);
    });

    test(
      'false while any season (e.g. a currently-airing one) is incomplete',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.path.endsWith('/season/1')) {
            return _seasonResponse(1, [
              _episode(id: 1, season: 1, number: 1, airDate: '2020-01-01'),
            ]);
          }
          if (request.url.path.endsWith('/season/2')) {
            return _seasonResponse(2, [
              _episode(id: 2, season: 2, number: 1, airDate: '2026-06-01'),
              // Episode 2 of season 2 not out yet.
            ]);
          }
          return http.Response('not found', 404);
        });
        final tmdbClient = TmdbClient(
          httpClient: mockClient,
          readAccessToken: 'test-token',
        );
        final seasons = [
          const SeasonSummary(
            seasonNumber: 1,
            name: 'Season 1',
            episodeCount: 1,
            posterPath: null,
            airDate: null,
          ),
          const SeasonSummary(
            seasonNumber: 2,
            name: 'Season 2',
            episodeCount: 2,
            posterPath: null,
            airDate: null,
          ),
        ];
        final show = _show(seasons: seasons);

        await watchedRepository.markSeasonWatched(1399, 1, [1]);
        await watchedRepository.markSeasonWatched(1399, 2, [1]);
        final progress = await computeShowProgress(
          tmdbClient: tmdbClient,
          watchedRepository: watchedRepository,
          show: show,
        );

        expect(progress.isShowComplete(seasons), isFalse);
      },
    );

    test(
      'a newly-announced season with its own episode count uncompletes a previously-finished show',
      () async {
        // Simulates: show was fully watched and complete, then TMDB adds a
        // new season whose first episode has just aired.
        final mockClient = MockClient((request) async {
          if (request.url.path.endsWith('/season/1')) {
            return _seasonResponse(1, [
              _episode(id: 1, season: 1, number: 1, airDate: '2020-01-01'),
            ]);
          }
          if (request.url.path.endsWith('/season/2')) {
            return _seasonResponse(2, [
              _episode(id: 2, season: 2, number: 1, airDate: '2026-06-01'),
            ]);
          }
          return http.Response('not found', 404);
        });
        final tmdbClient = TmdbClient(
          httpClient: mockClient,
          readAccessToken: 'test-token',
        );
        // Season 2 was unknown before; now TMDB lists it with 6 total
        // episodes, only the first of which has aired (and is unwatched).
        final seasons = [
          const SeasonSummary(
            seasonNumber: 1,
            name: 'Season 1',
            episodeCount: 1,
            posterPath: null,
            airDate: null,
          ),
          const SeasonSummary(
            seasonNumber: 2,
            name: 'Season 2',
            episodeCount: 6,
            posterPath: null,
            airDate: null,
          ),
        ];
        final show = _show(seasons: seasons);

        await watchedRepository.markSeasonWatched(1399, 1, [1]);
        final progress = await computeShowProgress(
          tmdbClient: tmdbClient,
          watchedRepository: watchedRepository,
          show: show,
        );

        expect(progress.isShowComplete(seasons), isFalse);
      },
    );

    test('false for a show with no seasons listed', () async {
      final tmdbClient = TmdbClient(
        httpClient: MockClient((_) async => http.Response('not found', 404)),
        readAccessToken: 'test-token',
      );
      final show = _show(seasons: const []);

      final progress = await computeShowProgress(
        tmdbClient: tmdbClient,
        watchedRepository: watchedRepository,
        show: show,
      );

      expect(progress.isShowComplete(const []), isFalse);
    });
  });

  group('airedEpisodeNumbers', () {
    test('keeps only episodes with a non-future air date', () {
      final farFuture = DateTime.now().add(const Duration(days: 365));
      final episodes = [
        Episode(
          id: 1,
          name: 'E1',
          overview: '',
          airDate: DateTime(2020, 1, 1),
          episodeNumber: 1,
          seasonNumber: 1,
          stillPath: null,
        ),
        Episode(
          id: 2,
          name: 'E2',
          overview: '',
          airDate: farFuture,
          episodeNumber: 2,
          seasonNumber: 1,
          stillPath: null,
        ),
        Episode(
          id: 3,
          name: 'E3',
          overview: '',
          airDate: null,
          episodeNumber: 3,
          seasonNumber: 1,
          stillPath: null,
        ),
      ];

      expect(airedEpisodeNumbers(episodes), [1]);
    });
  });

  group('hasAired', () {
    Episode episodeWithAirDate(DateTime? airDate) => Episode(
      id: 1,
      name: 'E1',
      overview: '',
      airDate: airDate,
      episodeNumber: 1,
      seasonNumber: 1,
      stillPath: null,
    );

    test('true for a past air date', () {
      expect(hasAired(episodeWithAirDate(DateTime(2020, 1, 1))), isTrue);
    });

    test('true for today', () {
      final now = DateTime.now();
      expect(
        hasAired(episodeWithAirDate(DateTime(now.year, now.month, now.day))),
        isTrue,
      );
    });

    test('false for a future air date', () {
      final farFuture = DateTime.now().add(const Duration(days: 365));
      expect(hasAired(episodeWithAirDate(farFuture)), isFalse);
    });

    test('false for a null air date', () {
      expect(hasAired(episodeWithAirDate(null)), isFalse);
    });
  });
}
