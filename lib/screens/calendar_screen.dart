import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../auth/auth_service.dart';
import '../data/firestore/watched_repository.dart';
import '../data/firestore/watchlist_repository.dart';
import '../data/models/movie_details.dart';
import '../data/models/search_result.dart';
import '../data/models/tv_show_details.dart';
import '../data/resilient_fetch.dart';
import '../data/tmdb_client.dart';
import '../l10n/app_localizations.dart';
import '../widgets/app_drawer.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/poster_list_tile.dart';
import '../widgets/search_results_list.dart';
import '../widgets/update_indicator_button.dart';
import 'detail_screen.dart';

class _UpcomingItem {
  final int tmdbId;
  final MediaType mediaType;
  final String title;
  final String? posterPath;
  final DateTime date;
  final String subtitle;

  const _UpcomingItem({
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    required this.posterPath,
    required this.date,
    required this.subtitle,
  });
}

class CalendarScreen extends StatefulWidget {
  final AuthService authService;
  final TmdbClient tmdbClient;
  final WatchlistRepository watchlistRepository;
  final WatchedRepository watchedRepository;

  const CalendarScreen({
    super.key,
    required this.authService,
    required this.tmdbClient,
    required this.watchlistRepository,
    required this.watchedRepository,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  Future<List<_UpcomingItem>>? _future;
  String _query = '';
  int _searchFieldGeneration = 0;

  @override
  void initState() {
    super.initState();
    _future = _loadUpcoming();
  }

  void _exitSearch() {
    setState(() {
      _query = '';
      _searchFieldGeneration++;
    });
  }

  /// Pull-to-refresh: forces a fresh TMDB fetch for every watchlist item
  /// instead of reusing [TmdbClient]'s cache.
  Future<void> _refresh() async {
    widget.tmdbClient.clearCache();
    setState(() {
      _future = _loadUpcoming();
    });
    await _future;
  }

  Future<List<_UpcomingItem>> _loadUpcoming() async {
    final showIds = await widget.watchlistRepository.watchShowIds().first;
    final movieIds = await widget.watchlistRepository.watchMovieIds().first;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final items = <_UpcomingItem>[];

    final shows = (await Future.wait(
      showIds.map(
        (id) => fetchOrNull(() => widget.tmdbClient.getTvShowDetails(id)),
      ),
    )).whereType<TvShowDetails>();
    for (final show in shows) {
      final next = show.nextEpisodeToAir;
      if (next?.airDate == null) continue;
      if (next!.airDate!.isBefore(today)) continue;
      items.add(
        _UpcomingItem(
          tmdbId: show.id,
          mediaType: MediaType.tv,
          title: show.name,
          posterPath: show.posterPath,
          date: next.airDate!,
          subtitle:
              'S${next.seasonNumber.toString().padLeft(2, '0')}E${next.episodeNumber.toString().padLeft(2, '0')} - ${next.name}',
        ),
      );
    }

    final movies = (await Future.wait(
      movieIds.map(
        (id) => fetchOrNull(() => widget.tmdbClient.getMovieDetails(id)),
      ),
    )).whereType<MovieDetails>();
    for (final movie in movies) {
      if (movie.releaseDate == null) continue;
      if (movie.releaseDate!.isBefore(today)) continue;
      items.add(
        _UpcomingItem(
          tmdbId: movie.id,
          mediaType: MediaType.movie,
          title: movie.title,
          posterPath: movie.posterPath,
          date: movie.releaseDate!,
          subtitle: '__MOVIE_RELEASE__',
        ),
      );
    }

    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }

  String _formatDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = date.difference(today).inDays;
    if (diff == 0) return l10n.today;
    if (diff == 1) return l10n.tomorrow;
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final searching = _query.isNotEmpty;
    return PopScope(
      canPop: !searching,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && searching) _exitSearch();
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 8,
          leading: searching
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _exitSearch,
                )
              : null,
          title: DebouncedSearchField(
            key: ValueKey(_searchFieldGeneration),
            onQueryChanged: (query) => setState(() => _query = query),
          ),
          actions: [
            const UpdateIndicatorButton(),
            AccountMenuButton(authService: widget.authService),
          ],
        ),
        body: searching
            ? SearchResultsList(
                query: _query,
                tmdbClient: widget.tmdbClient,
                watchlistRepository: widget.watchlistRepository,
                watchedRepository: widget.watchedRepository,
              )
            : FutureBuilder<List<_UpcomingItem>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(l10n.errorPrefix(snapshot.error.toString())),
                    );
                  }
                  final items = snapshot.data!;
                  if (items.isEmpty) {
                    return Center(child: Text(l10n.noUpcomingReleases));
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final subtitle = item.subtitle == '__MOVIE_RELEASE__'
                            ? l10n.movieRelease
                            : item.subtitle;
                        return PosterListTile(
                          posterPath: item.posterPath,
                          title: item.title,
                          subtitle:
                              '${_formatDate(context, item.date)} • $subtitle',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(
                                tmdbId: item.tmdbId,
                                mediaType: item.mediaType,
                                tmdbClient: widget.tmdbClient,
                                watchlistRepository: widget.watchlistRepository,
                                watchedRepository: widget.watchedRepository,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
