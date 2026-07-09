import 'package:flutter/material.dart';

import '../data/firestore/watched_repository.dart';
import '../data/firestore/watchlist_repository.dart';
import '../data/models/movie_details.dart';
import '../data/models/search_result.dart';
import '../data/models/tv_show_details.dart';
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
        setState(() {
          _showDetails = details;
          _inWatchlist = inWatchlist;
          _loading = false;
        });
      } else {
        final details = await widget.tmdbClient.getMovieDetails(
          widget.tmdbId,
        );
        final inWatchlist = await widget.watchlistRepository
            .isMovieInWatchlist(widget.tmdbId);
        final watched = await widget.watchedRepository.isMovieWatched(
          widget.tmdbId,
        );
        setState(() {
          _movieDetails = details;
          _inWatchlist = inWatchlist;
          _isWatched = watched;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _toggleWatchlist() async {
    final adding = !_inWatchlist;
    setState(() => _inWatchlist = adding);
    if (widget.mediaType == MediaType.tv) {
      await (adding
          ? widget.watchlistRepository.addShow(widget.tmdbId)
          : widget.watchlistRepository.removeShow(widget.tmdbId));
    } else {
      await (adding
          ? widget.watchlistRepository.addMovie(widget.tmdbId)
          : widget.watchlistRepository.removeMovie(widget.tmdbId));
    }
  }

  Future<void> _toggleMovieWatched() async {
    final watching = !_isWatched;
    setState(() => _isWatched = watching);
    await (watching
        ? widget.watchedRepository.markMovieWatched(widget.tmdbId)
        : widget.watchedRepository.markMovieUnwatched(widget.tmdbId));
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
            const SizedBox(height: 24),
            Text(
              'Stagioni',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ..._showDetails!.seasons.map(
              (season) => ListTile(
                title: Text(season.name),
                subtitle: Text('${season.episodeCount} episodi'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
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
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
