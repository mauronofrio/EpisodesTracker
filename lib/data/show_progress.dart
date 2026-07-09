import 'firestore/watched_repository.dart';
import 'models/episode.dart';
import 'models/season_summary.dart';
import 'models/tv_show_details.dart';
import 'resilient_fetch.dart';
import 'tmdb_client.dart';

class ShowProgress {
  final int watchedCount;
  final int airedCount;

  /// The earliest aired-but-unwatched episode, in season/episode order.
  /// Null if the user is caught up with everything aired so far.
  final Episode? nextToWatch;

  /// Watched-episode and aired-episode counts per season number. A season
  /// with no aired episodes yet (entirely in the future) has no entry in
  /// either map.
  final Map<int, int> watchedCountBySeason;
  final Map<int, int> airedCountBySeason;

  const ShowProgress({
    required this.watchedCount,
    required this.airedCount,
    required this.nextToWatch,
    required this.watchedCountBySeason,
    required this.airedCountBySeason,
  });

  /// A season counts as complete only once every episode TMDB currently
  /// lists for it is watched — [seasonEpisodeCount] is the season's own
  /// total (e.g. `SeasonSummary.episodeCount`), not just the aired subset.
  /// This deliberately does NOT use airedCountBySeason: a season that's
  /// still airing (3 of 8 episodes out, all 3 watched) must stay
  /// incomplete, not show as done just because nothing more has aired
  /// *yet*. Since unaired episodes can never be marked watched, this
  /// naturally requires the season to have finished airing too.
  bool isSeasonComplete(int seasonNumber, int seasonEpisodeCount) {
    if (seasonEpisodeCount == 0) return false;
    return (watchedCountBySeason[seasonNumber] ?? 0) >= seasonEpisodeCount;
  }

  /// The whole show counts as complete only when every season TMDB
  /// currently lists (per [seasons]) is complete by the same rule. If a
  /// new season is announced/added by TMDB with its own episode count
  /// while the show was previously "complete", this immediately becomes
  /// false again — the checkmark disappears as soon as TMDB reflects the
  /// new season's episodes, not waiting for anything else.
  bool isShowComplete(List<SeasonSummary> seasons) {
    if (seasons.isEmpty) return false;
    return seasons.every(
      (season) => isSeasonComplete(season.seasonNumber, season.episodeCount),
    );
  }
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
  final seasonEpisodeLists = await Future.wait(
    show.seasons.map(
      (season) => fetchOrNull(
        () => tmdbClient.getSeasonEpisodes(show.id, season.seasonNumber),
      ),
    ),
  );

  final airedEpisodes =
      seasonEpisodeLists.whereType<List<Episode>>().expand((e) => e).where(
        hasAired,
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
  final watchedCountBySeason = <int, int>{};
  final airedCountBySeason = <int, int>{};
  for (final episode in airedEpisodes) {
    airedCountBySeason[episode.seasonNumber] =
        (airedCountBySeason[episode.seasonNumber] ?? 0) + 1;
    final id = WatchedEpisodeId(
      showId: show.id,
      season: episode.seasonNumber,
      episode: episode.episodeNumber,
    );
    if (watched.containsKey(id)) {
      watchedCount++;
      watchedCountBySeason[episode.seasonNumber] =
          (watchedCountBySeason[episode.seasonNumber] ?? 0) + 1;
    } else {
      nextToWatch ??= episode;
    }
  }

  return ShowProgress(
    watchedCount: watchedCount,
    airedCount: airedEpisodes.length,
    nextToWatch: nextToWatch,
    watchedCountBySeason: watchedCountBySeason,
    airedCountBySeason: airedCountBySeason,
  );
}

/// True if [episode] has a known air date that isn't in the future. An
/// episode can't be "watched" (or rewatched) before it has aired.
bool hasAired(Episode episode) {
  final airDate = episode.airDate;
  if (airDate == null) return false;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return !airDate.isAfter(today);
}

/// Episode numbers from [episodes] that have already aired. Shared by any
/// caller that needs to mark a whole season watched without including
/// unaired episodes.
List<int> airedEpisodeNumbers(List<Episode> episodes) {
  return episodes.where(hasAired).map((e) => e.episodeNumber).toList();
}
