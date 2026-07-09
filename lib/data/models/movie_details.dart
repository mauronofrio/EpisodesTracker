class MovieDetails {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final DateTime? releaseDate;
  final int? runtime;
  final String status;

  const MovieDetails({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.runtime,
    required this.status,
  });

  factory MovieDetails.fromJson(Map<String, dynamic> json) {
    final rawDate = json['release_date'] as String?;
    return MovieDetails(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: (rawDate == null || rawDate.isEmpty)
          ? null
          : DateTime.parse(rawDate),
      runtime: json['runtime'] as int?,
      status: json['status'] as String? ?? '',
    );
  }
}
