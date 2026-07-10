import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models/episode.dart';
import 'models/movie_details.dart';
import 'models/search_result.dart';
import 'models/tv_show_details.dart';

class TmdbException implements Exception {
  final int statusCode;
  final String message;
  TmdbException(this.statusCode, this.message);

  @override
  String toString() => 'TmdbException($statusCode): $message';
}

/// Thin wrapper around TMDB's v3 REST API using a v4 read-access Bearer
/// token. Only the endpoints this app needs are implemented.
///
/// Show/movie details and season episode lists are cached in memory for
/// this client's lifetime (one instance per signed-in session, shared by
/// every screen - see `app.dart`). Progress computation
/// ([show_progress.dart]'s `computeShowProgress`) re-reads the same
/// season's episode list every time an episode is marked watched even
/// though the episode list itself hasn't changed; without this cache that
/// meant a full round-trip to TMDB for every season on every toggle. Call
/// [clearCache] (wired to a pull-to-refresh gesture) to force fresh data.
class TmdbClient {
  final http.Client _httpClient;
  final String _readAccessToken;
  static const _baseUrl = 'https://api.themoviedb.org/3';

  final Map<int, TvShowDetails> _showDetailsCache = {};
  final Map<int, MovieDetails> _movieDetailsCache = {};
  final Map<String, List<Episode>> _seasonEpisodesCache = {};

  TmdbClient({
    required http.Client httpClient,
    required String readAccessToken,
  }) : _httpClient = httpClient,
       _readAccessToken = readAccessToken;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_readAccessToken',
    'Accept': 'application/json',
  };

  Future<Map<String, dynamic>> _getJson(
    String path, [
    Map<String, String>? query,
  ]) async {
    final uri = Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: query);
    final response = await _httpClient.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw TmdbException(response.statusCode, response.body);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Searches TV shows and movies matching [query]. `person` results from
  /// the underlying `/search/multi` endpoint are filtered out.
  Future<List<SearchResult>> searchMulti(String query) async {
    final json = await _getJson('/search/multi', {'query': query});
    final results = json['results'] as List<dynamic>? ?? [];
    return results
        .map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
        .whereType<SearchResult>()
        .toList();
  }

  Future<TvShowDetails> getTvShowDetails(int id) async {
    final cached = _showDetailsCache[id];
    if (cached != null) return cached;
    final json = await _getJson('/tv/$id');
    final details = TvShowDetails.fromJson(json);
    _showDetailsCache[id] = details;
    return details;
  }

  Future<MovieDetails> getMovieDetails(int id) async {
    final cached = _movieDetailsCache[id];
    if (cached != null) return cached;
    final json = await _getJson('/movie/$id');
    final details = MovieDetails.fromJson(json);
    _movieDetailsCache[id] = details;
    return details;
  }

  Future<List<Episode>> getSeasonEpisodes(int showId, int seasonNumber) async {
    final cacheKey = '${showId}_$seasonNumber';
    final cached = _seasonEpisodesCache[cacheKey];
    if (cached != null) return cached;
    final json = await _getJson('/tv/$showId/season/$seasonNumber');
    final episodesJson = json['episodes'] as List<dynamic>? ?? [];
    final episodes = episodesJson
        .map((e) => Episode.fromJson(e as Map<String, dynamic>))
        .toList();
    _seasonEpisodesCache[cacheKey] = episodes;
    return episodes;
  }

  /// Wipes every cached response, so the next call to any getter above
  /// re-fetches from TMDB. Wired to pull-to-refresh gestures rather than
  /// any automatic expiry - this is a personal, single-device-per-user
  /// app, so a time-based cache invalidation strategy would add
  /// complexity without a real benefit here.
  void clearCache() {
    _showDetailsCache.clear();
    _movieDetailsCache.clear();
    _seasonEpisodesCache.clear();
  }

  /// Closes the underlying HTTP client, releasing its connection pool.
  /// Callers that own a TmdbClient for a bounded lifetime (e.g. one per
  /// signed-in session) must call this when they're done with it.
  void close() => _httpClient.close();
}
