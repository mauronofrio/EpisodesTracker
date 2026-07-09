import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/firestore/watched_repository.dart';
import '../data/firestore/watchlist_repository.dart';
import '../data/models/episode.dart';
import '../data/models/movie_details.dart';
import '../data/models/search_result.dart';
import '../data/models/season_summary.dart';
import '../data/models/tv_show_details.dart';
import '../data/show_progress.dart';
import '../data/tmdb_client.dart';
import 'season_episodes_screen.dart';

class DetailScreen extends StatefulWidget {
  final int tmdbId;
  final MediaType mediaType;
  final TmdbClient tmdbClient;
  final WatchlistRepository watchlistRepository;
  final WatchedRepository watchedRepository;

  const DetailScreen({
    super.key,
    required this.tmdbId,
    required this.mediaType,
    required this.tmdbClient,
    required this.watchlistRepository,
    required this.watchedRepository,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  TvShowDetails? _showDetails;
  MovieDetails? _movieDetails;
  bool _loading = true;
  Object? _error;
  bool _inWatchlist = false;
  bool _isWatched = false;
  ShowProgress? _progress;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (widget.mediaType == MediaType.tv) {
        final details = await widget.tmdbClient.getTvShowDetails(
          widget.tmdbId,
        );
        final inWatchlist = await widget.watchlistRepository
            .isShowInWatchlist(widget.tmdbId);
        if (!mounted) return;
        setState(() {
          _showDetails = details;
          _inWatchlist = inWatchlist;
          _loading = false;
        });
        await _refreshProgress();
      } else {
        final details = await widget.tmdbClient.getMovieDetails(
          widget.tmdbId,
        );
        final inWatchlist = await widget.watchlistRepository
            .isMovieInWatchlist(widget.tmdbId);
        final watched = await widget.watchedRepository.isMovieWatched(
          widget.tmdbId,
        );
        if (!mounted) return;
        setState(() {
          _movieDetails = details;
          _inWatchlist = inWatchlist;
          _isWatched = watched;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _toggleWatchlist() async {
    final adding = !_inWatchlist;
    setState(() => _inWatchlist = adding);
    try {
      if (widget.mediaType == MediaType.tv) {
        await (adding
            ? widget.watchlistRepository.addShow(widget.tmdbId)
            : widget.watchlistRepository.removeShow(widget.tmdbId));
      } else {
        await (adding
            ? widget.watchlistRepository.addMovie(widget.tmdbId)
            : widget.watchlistRepository.removeMovie(widget.tmdbId));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _inWatchlist = !adding);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore: $e')));
    }
  }

  Future<void> _toggleMovieWatched() async {
    final watching = !_isWatched;
    setState(() => _isWatched = watching);
    try {
      await (watching
          ? widget.watchedRepository.markMovieWatched(widget.tmdbId)
          : widget.watchedRepository.markMovieUnwatched(widget.tmdbId));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isWatched = !watching);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore: $e')));
    }
  }

  /// Recomputes watched/aired counts and the next episode to watch. Runs
  /// after the initial load and after marking the next episode watched.
  /// Best-effort: a failure here (e.g. one season's TMDB call failing)
  /// shouldn't block the rest of the detail screen from working.
  Future<void> _refreshProgress() async {
    final show = _showDetails;
    if (show == null) return;
    try {
      final progress = await computeShowProgress(
        tmdbClient: widget.tmdbClient,
        watchedRepository: widget.watchedRepository,
        show: show,
      );
      if (!mounted) return;
      setState(() => _progress = progress);
    } catch (_) {
      // Leave the previous (or null) progress in place.
    }
  }

  Future<void> _markNextEpisodeWatched(Episode episode) async {
    final id = WatchedEpisodeId(
      showId: widget.tmdbId,
      season: episode.seasonNumber,
      episode: episode.episodeNumber,
    );
    try {
      await widget.watchedRepository.markEpisodeWatched(id);
      await _refreshProgress();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore: $e')));
    }
  }

  Future<void> _markSeasonWatchedFromSummary(SeasonSummary season) async {
    try {
      final episodes = await widget.tmdbClient.getSeasonEpisodes(
        widget.tmdbId,
        season.seasonNumber,
      );
      await widget.watchedRepository.markSeasonWatched(
        widget.tmdbId,
        season.seasonNumber,
        airedEpisodeNumbers(episodes),
      );
      await _refreshProgress();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text('Errore: $_error')));
    }

    final title = _showDetails?.name ?? _movieDetails!.title;
    final overview = _showDetails?.overview ?? _movieDetails!.overview;
    final posterPath = _showDetails?.posterPath ?? _movieDetails!.posterPath;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                height: 150,
                child: posterPath == null
                    ? const ColoredBox(color: Color(0xFFE0E0E0))
                    : Image.network(
                        'https://image.tmdb.org/t/p/w300$posterPath',
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FilledButton.icon(
                      onPressed: _toggleWatchlist,
                      icon: Icon(
                        _inWatchlist ? Icons.check : Icons.add,
                      ),
                      label: Text(
                        _inWatchlist
                            ? 'Nella watchlist'
                            : 'Aggiungi a watchlist',
                      ),
                    ),
                    if (widget.mediaType == MediaType.movie) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _toggleMovieWatched,
                        icon: Icon(
                          _isWatched
                              ? Icons.visibility
                              : Icons.visibility_outlined,
                        ),
                        label: Text(_isWatched ? 'Visto' : 'Segna come visto'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(overview),
          if (_showDetails != null) ...[
            const SizedBox(height: 16),
            if (_progress case final progress?) ...[
              Text(
                '${progress.watchedCount}/${progress.airedCount} episodi visti',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (progress.nextToWatch case final next?)
                Card(
                  child: ListTile(
                    title: const Text('Prossimo episodio'),
                    subtitle: Text(
                      'S${next.seasonNumber.toString().padLeft(2, '0')}'
                      'E${next.episodeNumber.toString().padLeft(2, '0')} - ${next.name}'
                      '${next.airDate == null ? '' : ' (${DateFormat('yyyy-MM-dd').format(next.airDate!)})'}',
                    ),
                    trailing: FilledButton(
                      onPressed: () => _markNextEpisodeWatched(next),
                      child: const Text('Segna visto'),
                    ),
                  ),
                )
              else
                const Text('Sei aggiornato con tutti gli episodi usciti'),
            ],
            const SizedBox(height: 16),
            Text(
              'Stagioni',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ..._showDetails!.seasons.map((season) {
              final watchedInSeason =
                  _progress?.watchedCountBySeason[season.seasonNumber];
              final subtitle = watchedInSeason == null
                  ? '${season.episodeCount} episodi'
                  : '$watchedInSeason/${season.episodeCount} episodi visti';
              final isComplete =
                  _progress?.isSeasonComplete(season.seasonNumber) ?? false;
              return ListTile(
                leading: isComplete
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                title: Text(season.name),
                subtitle: Text(subtitle),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.playlist_add_check),
                      tooltip: 'Segna stagione vista',
                      onPressed: () => _markSeasonWatchedFromSummary(season),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SeasonEpisodesScreen(
                        showId: widget.tmdbId,
                        showName: _showDetails!.name,
                        seasonNumber: season.seasonNumber,
                        tmdbClient: widget.tmdbClient,
                        watchedRepository: widget.watchedRepository,
                      ),
                    ),
                  );
                  // The user may have marked episodes watched/rewatched
                  // inside the season screen; refresh counts on return.
                  await _refreshProgress();
                },
              );
            }),
          ],
        ],
      ),
    );
  }
}
