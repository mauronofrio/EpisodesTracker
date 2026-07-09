class Episode {
  final int id;
  final String name;
  final String overview;
  final DateTime? airDate;
  final int episodeNumber;
  final int seasonNumber;
  final String? stillPath;

  const Episode({
    required this.id,
    required this.name,
    required this.overview,
    required this.airDate,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.stillPath,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    final rawDate = json['air_date'] as String?;
    return Episode(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      overview: json['overview'] as String? ?? '',
      airDate: (rawDate == null || rawDate.isEmpty)
          ? null
          : DateTime.parse(rawDate),
      episodeNumber: json['episode_number'] as int,
      seasonNumber: json['season_number'] as int,
      stillPath: json['still_path'] as String?,
    );
  }
}
