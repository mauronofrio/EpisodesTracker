import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../data/firestore/watched_repository.dart';
import '../data/firestore/watchlist_repository.dart';
import '../data/models/movie_details.dart';
import '../data/models/search_result.dart';
import '../data/models/tv_show_details.dart';
import '../data/resilient_fetch.dart';
import '../data/show_progress.dart';
import '../data/tmdb_client.dart';
import '../l10n/app_localizations.dart';
import '../widgets/app_drawer.dart';
import '../widgets/caught_up_indicator.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/poster_list_tile.dart';
import '../widgets/search_results_list.dart';
import '../widgets/update_indicator_button.dart';
import 'detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  final AuthService authService;
  final TmdbClient tmdbClient;
  final WatchlistRepository watchlistRepository;
  final WatchedRepository watchedRepository;

  const WatchlistScreen({
    super.key,
    required this.authService,
    required this.tmdbClient,
    required this.watchlistRepository,
    required this.watchedRepository,
  });

  @override
  State<WatchlistScreen> createState() => WatchlistScreenState();
}

class WatchlistScreenState extends State<WatchlistScreen> {
  String _query = '';
  // Bumped to force DebouncedSearchField to rebuild with a fresh, empty
  // TextEditingController when search is dismissed via the back arrow/
  // system back (as opposed to the user clearing the field themselves).
  int _searchFieldGeneration = 0;

  void _exitSearch() {
    setState(() {
      _query = '';
      _searchFieldGeneration++;
    });
  }

  /// Called by [HomeShell] (via GlobalKey) the moment the user switches to
  /// the other bottom-nav tab, so an open search doesn't linger and
  /// silently reopen when they come back - HomeShell keeps every tab alive
  /// (see its IndexedStack), so nothing else would ever close this.
  void exitSearchIfOpen() {
    if (_query.isNotEmpty) _exitSearch();
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
      child: DefaultTabController(
        length: 2,
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
            // AppBar tears down and rebuilds its whole subtree - including
            // `title` (the search field) - whenever `bottom` toggles
            // between null and a widget, which was wiping out whatever
            // the user had typed the instant a search actually started.
            // Keeping `bottom` a stable PreferredSize (only its content and
            // height change) avoids that null<->non-null flip entirely.
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(searching ? 0 : kTextTabBarHeight),
              child: searching
                  ? const SizedBox.shrink()
                  : TabBar(
                      tabs: [
                        Tab(text: l10n.tabShows),
                        Tab(text: l10n.tabMovies),
                      ],
                    ),
            ),
          ),
          body: searching
              ? SearchResultsList(
                  query: _query,
                  tmdbClient: widget.tmdbClient,
                  watchlistRepository: widget.watchlistRepository,
                  watchedRepository: widget.watchedRepository,
                )
              : TabBarView(
                  children: [
                    _WatchlistShowsTab(
                      tmdbClient: widget.tmdbClient,
                      watchlistRepository: widget.watchlistRepository,
                      watchedRepository: widget.watchedRepository,
                    ),
                    _WatchlistMoviesTab(
                      tmdbClient: widget.tmdbClient,
                      watchlistRepository: widget.watchlistRepository,
                      watchedRepository: widget.watchedRepository,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _WatchlistShowsTab extends StatefulWidget {
  final TmdbClient tmdbClient;
  final WatchlistRepository watchlistRepository;
  final WatchedRepository watchedRepository;

  const _WatchlistShowsTab({
    required this.tmdbClient,
    required this.watchlistRepository,
    required this.watchedRepository,
  });

  @override
  State<_WatchlistShowsTab> createState() => _WatchlistShowsTabState();
}

class _WatchlistShowsTabState extends State<_WatchlistShowsTab> {
  /// Pull-to-refresh: forces a fresh TMDB fetch for every show in the tab
  /// instead of reusing [TmdbClient]'s cache.
  Future<void> _refresh() async {
    widget.tmdbClient.clearCache();
    setState(() {});
  }

  Future<void> _openDetail(BuildContext context, int showId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailScreen(
          tmdbId: showId,
          mediaType: MediaType.tv,
          tmdbClient: widget.tmdbClient,
          watchlistRepository: widget.watchlistRepository,
          watchedRepository: widget.watchedRepository,
        ),
      ),
    );
    // Watched state may have changed inside DetailScreen; rebuild so every
    // ShowProgress FutureBuilder below re-fetches instead of showing what
    // was cached before the user navigated away.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<int>>(
      stream: widget.watchlistRepository.watchShowIds(),
      builder: (context, idsSnapshot) {
        final ids = idsSnapshot.data ?? [];
        if (ids.isEmpty) {
          return Center(child: Text(l10n.noShowsInWatchlist));
        }
        return FutureBuilder<List<TvShowDetails?>>(
          future: Future.wait(
            ids.map(
              (id) => fetchOrNull(() => widget.tmdbClient.getTvShowDetails(id)),
            ),
          ),
          builder: (context, detailsSnapshot) {
            if (detailsSnapshot.hasError) {
              return Center(
                child: Text(l10n.errorPrefix(detailsSnapshot.error.toString())),
              );
            }
            if (!detailsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final shows = detailsSnapshot.data!
                .whereType<TvShowDetails>()
                .toList();
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                itemCount: shows.length,
                itemBuilder: (context, index) {
                  final show = shows[index];
                  return FutureBuilder<ShowProgress>(
                    future: computeShowProgress(
                      tmdbClient: widget.tmdbClient,
                      watchedRepository: widget.watchedRepository,
                      show: show,
                    ),
                    builder: (context, progressSnapshot) {
                      final progress = progressSnapshot.data;
                      final subtitle = progress == null
                          ? show.status
                          : l10n.watchedCount(
                              progress.watchedCount,
                              progress.airedCount,
                            );
                      final isComplete =
                          progress?.isShowComplete(show.seasons) ?? false;
                      final isCaughtUpButOngoing =
                          progress?.isShowCaughtUpButOngoing(show.seasons) ??
                          false;
                      return PosterListTile(
                        posterPath: show.posterPath,
                        title: show.name,
                        subtitle: subtitle,
                        titleSuffix: isComplete
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 18,
                              )
                            : isCaughtUpButOngoing
                            ? const CaughtUpIndicator(size: 18)
                            : null,
                        onTap: () => _openDetail(context, show.id),
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _WatchlistMoviesTab extends StatefulWidget {
  final TmdbClient tmdbClient;
  final WatchlistRepository watchlistRepository;
  final WatchedRepository watchedRepository;

  const _WatchlistMoviesTab({
    required this.tmdbClient,
    required this.watchlistRepository,
    required this.watchedRepository,
  });

  @override
  State<_WatchlistMoviesTab> createState() => _WatchlistMoviesTabState();
}

class _WatchlistMoviesTabState extends State<_WatchlistMoviesTab> {
  /// Pull-to-refresh: forces a fresh TMDB fetch for every movie in the tab
  /// instead of reusing [TmdbClient]'s cache.
  Future<void> _refresh() async {
    widget.tmdbClient.clearCache();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<int>>(
      stream: widget.watchlistRepository.watchMovieIds(),
      builder: (context, idsSnapshot) {
        final ids = idsSnapshot.data ?? [];
        if (ids.isEmpty) {
          return Center(child: Text(l10n.noMoviesInWatchlist));
        }
        return FutureBuilder<List<MovieDetails?>>(
          future: Future.wait(
            ids.map(
              (id) => fetchOrNull(() => widget.tmdbClient.getMovieDetails(id)),
            ),
          ),
          builder: (context, detailsSnapshot) {
            if (detailsSnapshot.hasError) {
              return Center(
                child: Text(l10n.errorPrefix(detailsSnapshot.error.toString())),
              );
            }
            if (!detailsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final movies = detailsSnapshot.data!
                .whereType<MovieDetails>()
                .toList();
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  final movie = movies[index];
                  return PosterListTile(
                    posterPath: movie.posterPath,
                    title: movie.title,
                    subtitle: movie.status,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(
                          tmdbId: movie.id,
                          mediaType: MediaType.movie,
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
        );
      },
    );
  }
}
