import 'dart:convert';

import 'package:episodes_tracker/data/models/search_result.dart';
import 'package:episodes_tracker/data/tmdb_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('TmdbClient.searchMulti', () {
    test('parses tv and movie results and drops person results', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/3/search/multi');
        expect(request.url.queryParameters['query'], 'breaking bad');
        expect(request.headers['Authorization'], 'Bearer test-token');
        return http.Response(
          jsonEncode({
            'page': 1,
            'results': [
              {
                'id': 1396,
                'media_type': 'tv',
                'name': 'Breaking Bad',
                'poster_path': '/ztkUQFLlC19CCMYHW9o1zWhJRNq.jpg',
                'first_air_date': '2008-01-20',
                'overview': 'Walter White...',
              },
              {
                'id': 42,
                'media_type': 'movie',
                'title': 'Some Movie',
                'poster_path': null,
                'release_date': '2020-01-01',
                'overview': 'A movie.',
              },
              {'id': 99, 'media_type': 'person', 'name': 'Someone'},
            ],
            'total_pages': 1,
            'total_results': 3,
          }),
          200,
        );
      });

      final client = TmdbClient(
        httpClient: mockClient,
        readAccessToken: 'test-token',
      );
      final results = await client.searchMulti('breaking bad');

      expect(results, hasLength(2));
      expect(results[0].id, 1396);
      expect(results[0].mediaType, MediaType.tv);
      expect(results[0].title, 'Breaking Bad');
      expect(results[1].id, 42);
      expect(results[1].mediaType, MediaType.movie);
      expect(results[1].title, 'Some Movie');
    });

    test('throws TmdbException on non-200 response', () async {
      final mockClient = MockClient(
        (request) async => http.Response('{"status_message":"denied"}', 401),
      );
      final client = TmdbClient(
        httpClient: mockClient,
        readAccessToken: 'bad-token',
      );

      expect(
        () => client.searchMulti('x'),
        throwsA(isA<TmdbException>()),
      );
    });
  });

  group('TmdbClient.getTvShowDetails', () {
    test('parses an actively-airing show with next_episode_to_air', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/3/tv/94997');
        return http.Response(
          jsonEncode({
            'id': 94997,
            'name': 'House of the Dragon',
            'overview': 'Targaryen civil war.',
            'poster_path': '/poster.jpg',
            'backdrop_path': '/backdrop.jpg',
            'number_of_seasons': 3,
            'number_of_episodes': 24,
            'status': 'Returning Series',
            'next_episode_to_air': {
              'id': 7196567,
              'name': 'Episode 4',
              'overview': '',
              'air_date': '2026-07-12',
              'episode_number': 4,
              'season_number': 3,
            },
            'last_episode_to_air': {
              'id': 7196566,
              'name': 'Rhaenyra Triumphant',
              'overview': 'Rhaenyra learns...',
              'air_date': '2026-07-05',
              'episode_number': 3,
              'season_number': 3,
            },
            'seasons': [
              {
                'season_number': 0,
                'name': 'Specials',
                'episode_count': 5,
                'air_date': '2022-08-01',
              },
              {
                'season_number': 1,
                'name': 'Season 1',
                'episode_count': 10,
                'air_date': '2022-08-21',
              },
            ],
          }),
          200,
        );
      });

      final client = TmdbClient(
        httpClient: mockClient,
        readAccessToken: 'test-token',
      );
      final details = await client.getTvShowDetails(94997);

      expect(details.name, 'House of the Dragon');
      expect(details.nextEpisodeToAir, isNotNull);
      expect(details.nextEpisodeToAir!.airDate, DateTime.parse('2026-07-12'));
      expect(details.nextEpisodeToAir!.episodeNumber, 4);
      expect(details.lastEpisodeToAir!.name, 'Rhaenyra Triumphant');
      // Season 0 ("Specials") is filtered out.
      expect(details.seasons, hasLength(1));
      expect(details.seasons[0].seasonNumber, 1);
    });

    test('parses an ended show with null next_episode_to_air', () async {
      final mockClient = MockClient(
        (request) async => http.Response(
          jsonEncode({
            'id': 1399,
            'name': 'Game of Thrones',
            'overview': '',
            'poster_path': null,
            'backdrop_path': null,
            'number_of_seasons': 8,
            'number_of_episodes': 73,
            'status': 'Ended',
            'next_episode_to_air': null,
            'last_episode_to_air': {
              'id': 1551830,
              'name': 'The Iron Throne',
              'overview': '',
              'air_date': '2019-05-19',
              'episode_number': 6,
              'season_number': 8,
            },
            'seasons': [],
          }),
          200,
        ),
      );

      final client = TmdbClient(
        httpClient: mockClient,
        readAccessToken: 'test-token',
      );
      final details = await client.getTvShowDetails(1399);

      expect(details.nextEpisodeToAir, isNull);
      expect(details.status, 'Ended');
    });
  });

  group('TmdbClient.getMovieDetails', () {
    test('parses movie details', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/3/movie/550');
        return http.Response(
          jsonEncode({
            'id': 550,
            'title': 'Fight Club',
            'overview': 'An insomniac office worker...',
            'poster_path': '/poster.jpg',
            'backdrop_path': '/backdrop.jpg',
            'release_date': '1999-10-15',
            'runtime': 139,
            'status': 'Released',
          }),
          200,
        );
      });

      final client = TmdbClient(
        httpClient: mockClient,
        readAccessToken: 'test-token',
      );
      final details = await client.getMovieDetails(550);

      expect(details.title, 'Fight Club');
      expect(details.releaseDate, DateTime.parse('1999-10-15'));
      expect(details.runtime, 139);
    });
  });

  group('TmdbClient.getSeasonEpisodes', () {
    test('parses episode list for a season', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/3/tv/94997/season/1');
        return http.Response(
          jsonEncode({
            'air_date': '2022-08-21',
            'name': 'Season 1',
            'season_number': 1,
            'episodes': [
              {
                'id': 1971015,
                'name': 'The Heirs of the Dragon',
                'overview': 'Viserys hosts a tournament...',
                'air_date': '2022-08-21',
                'episode_number': 1,
                'season_number': 1,
                'still_path': '/still.jpg',
              },
            ],
          }),
          200,
        );
      });

      final client = TmdbClient(
        httpClient: mockClient,
        readAccessToken: 'test-token',
      );
      final episodes = await client.getSeasonEpisodes(94997, 1);

      expect(episodes, hasLength(1));
      expect(episodes[0].name, 'The Heirs of the Dragon');
      expect(episodes[0].episodeNumber, 1);
    });
  });
}
