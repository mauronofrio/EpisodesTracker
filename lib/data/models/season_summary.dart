class SeasonSummary {
  final int seasonNumber;
  final String name;
  final int episodeCount;
  final String? posterPath;
  final DateTime? airDate;

  const SeasonSummary({
    required this.seasonNumber,
    required this.name,
    required this.episodeCount,
    required this.posterPath,
    required this.airDate,
  });

  factory SeasonSummary.fromJson(Map<String, dynamic> json) {
    final rawDate = json['air_date'] as String?;
    return SeasonSummary(
      seasonNumber: json['season_number'] as int,
      name: json['name'] as String? ?? '',
      episodeCount: json['episode_count'] as int? ?? 0,
      posterPath: json['poster_path'] as String?,
      airDate: (rawDate == null || rawDate.isEmpty)
          ? null
          : DateTime.parse(rawDate),
    );
  }
}
