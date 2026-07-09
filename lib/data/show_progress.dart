import 'firestore/watched_repository.dart';
import 'models/episode.dart';
import 'models/tv_show_details.dart';
import 'resilient_fetch.dart';
import 'tmdb_client.dart';

class ShowProgress {
  final int watchedCount;
  final int airedCount;

  /// The earliest aired-but-unwatched episode, in season/episode order.
  /// Null if the user is caught up with everything aired so far.
  final Episode? nextToWatch;

  const ShowProgress({
    required this.watchedCount,
    required this.airedCount,
    required this.nextToWatch,
  });
}

/// Fetches every season's episode list for [show] (in parallel, tolerating
/// individual season failures via [fetchOrNull]), keeps only episodes that
/// have actually aired, and cross-references them against watched state to
/// compute a watched/aired count and the next episode to watch.
Future<ShowProgress> computeShowProgress({
  required TmdbClient tmdbClient,
  required WatchedRepository watchedRepository,
  required TvShowDetails show,
}) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final seasonEpisodeLists = await Future.wait(
    show.seasons.map(
      (season) => fetchOrNull(
        () => tmdbClient.getSeasonEpisodes(show.id, season.seasonNumber),
      ),
    ),
  );

  final airedEpisodes =
      seasonEpisodeLists.whereType<List<Episode>>().expand((e) => e).where(
        (e) => e.airDate != null && !e.airDate!.isAfter(today),
      ).toList()..sort((a, b) {
        final seasonCompare = a.seasonNumber.compareTo(b.seasonNumber);
        if (seasonCompare != 0) return seasonCompare;
        return a.episodeNumber.compareTo(b.episodeNumber);
      });

  final watched = await watchedRepository
      .watchedEpisodeIdsForShow(show.id)
      .first;

  var watchedCount = 0;
  Episode? nextToWatch;
  for (final episode in airedEpisodes) {
    final id = WatchedEpisodeId(
      showId: show.id,
      season: episode.seasonNumber,
      episode: episode.episodeNumber,
    );
    if (watched.containsKey(id)) {
      watchedCount++;
    } else {
      nextToWatch ??= episode;
    }
  }

  return ShowProgress(
    watchedCount: watchedCount,
    airedCount: airedEpisodes.length,
    nextToWatch: nextToWatch,
  );
}
