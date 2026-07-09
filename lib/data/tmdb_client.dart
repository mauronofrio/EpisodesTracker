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
class TmdbClient {
  final http.Client _httpClient;
  final String _readAccessToken;
  static const _baseUrl = 'https://api.themoviedb.org/3';

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
    final json = await _getJson('/tv/$id');
    return TvShowDetails.fromJson(json);
  }

  Future<MovieDetails> getMovieDetails(int id) async {
    final json = await _getJson('/movie/$id');
    return MovieDetails.fromJson(json);
  }

  Future<List<Episode>> getSeasonEpisodes(int showId, int seasonNumber) async {
    final json = await _getJson('/tv/$showId/season/$seasonNumber');
    final episodes = json['episodes'] as List<dynamic>? ?? [];
    return episodes
        .map((e) => Episode.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Closes the underlying HTTP client, releasing its connection pool.
  /// Callers that own a TmdbClient for a bounded lifetime (e.g. one per
  /// signed-in session) must call this when they're done with it.
  void close() => _httpClient.close();
}
