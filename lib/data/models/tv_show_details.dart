import 'episode.dart';
import 'season_summary.dart';

class TvShowDetails {
  final int id;
  final String name;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final int numberOfSeasons;
  final int numberOfEpisodes;
  final String status;
  final Episode? nextEpisodeToAir;
  final Episode? lastEpisodeToAir;
  final List<SeasonSummary> seasons;

  const TvShowDetails({
    required this.id,
    required this.name,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.numberOfSeasons,
    required this.numberOfEpisodes,
    required this.status,
    required this.nextEpisodeToAir,
    required this.lastEpisodeToAir,
    required this.seasons,
  });

  factory TvShowDetails.fromJson(Map<String, dynamic> json) {
    final nextRaw = json['next_episode_to_air'] as Map<String, dynamic>?;
    final lastRaw = json['last_episode_to_air'] as Map<String, dynamic>?;
    final seasonsRaw = json['seasons'] as List<dynamic>? ?? [];

    return TvShowDetails(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      numberOfSeasons: json['number_of_seasons'] as int? ?? 0,
      numberOfEpisodes: json['number_of_episodes'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      nextEpisodeToAir: nextRaw == null ? null : Episode.fromJson(nextRaw),
      lastEpisodeToAir: lastRaw == null ? null : Episode.fromJson(lastRaw),
      seasons: seasonsRaw
          .map((e) => SeasonSummary.fromJson(e as Map<String, dynamic>))
          // TMDB includes a "Specials" entry as season_number 0; the app
          // only tracks regular seasons.
          .where((s) => s.seasonNumber > 0)
          .toList(),
    );
  }
}
