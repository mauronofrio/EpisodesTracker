enum MediaType { tv, movie }

/// A single entry from TMDB's `/search/multi` endpoint, narrowed to the
/// `tv` and `movie` media types only (the endpoint also returns `person`
/// results, which are filtered out before this model is constructed).
class SearchResult {
  final int id;
  final MediaType mediaType;
  final String title;
  final String? posterPath;
  final String? releaseDate;
  final String overview;

  const SearchResult({
    required this.id,
    required this.mediaType,
    required this.title,
    required this.posterPath,
    required this.releaseDate,
    required this.overview,
  });

  /// Returns null for `person` results, which callers should filter out.
  static SearchResult? fromJson(Map<String, dynamic> json) {
    final rawType = json['media_type'] as String?;
    final MediaType? mediaType = switch (rawType) {
      'tv' => MediaType.tv,
      'movie' => MediaType.movie,
      _ => null,
    };
    if (mediaType == null) return null;

    return SearchResult(
      id: json['id'] as int,
      mediaType: mediaType,
      title: (mediaType == MediaType.tv ? json['name'] : json['title'])
              as String? ??
          '',
      posterPath: json['poster_path'] as String?,
      releaseDate:
          (mediaType == MediaType.tv
                  ? json['first_air_date']
                  : json['release_date'])
              as String?,
      overview: json['overview'] as String? ?? '',
    );
  }
}
