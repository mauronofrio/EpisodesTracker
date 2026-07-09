import 'package:flutter/material.dart';

import '../data/firestore/watched_repository.dart';
import '../data/firestore/watchlist_repository.dart';
import '../data/models/movie_details.dart';
import '../data/models/search_result.dart';
import '../data/models/tv_show_details.dart';
import '../data/tmdb_client.dart';
import '../widgets/poster_list_tile.dart';
import 'detail_screen.dart';

class WatchlistScreen extends StatelessWidget {
  final TmdbClient tmdbClient;
  final WatchlistRepository watchlistRepository;
  final WatchedRepository watchedRepository;

  const WatchlistScreen({
    super.key,
    required this.tmdbClient,
    required this.watchlistRepository,
    required this.watchedRepository,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Watchlist'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Serie'), Tab(text: 'Film')],
          ),
        ),
        body: TabBarView(
          children: [
            _WatchlistShowsTab(
              tmdbClient: tmdbClient,
              watchlistRepository: watchlistRepository,
              watchedRepository: watchedRepository,
            ),
            _WatchlistMoviesTab(
              tmdbClient: tmdbClient,
              watchlistRepository: watchlistRepository,
              watchedRepository: watchedRepository,
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchlistShowsTab extends StatelessWidget {
  final TmdbClient tmdbClient;
  final WatchlistRepository watchlistRepository;
  final WatchedRepository watchedRepository;

  const _WatchlistShowsTab({
    required this.tmdbClient,
    required this.watchlistRepository,
    required this.watchedRepository,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<int>>(
      stream: watchlistRepository.watchShowIds(),
      builder: (context, idsSnapshot) {
        final ids = idsSnapshot.data ?? [];
        if (ids.isEmpty) {
          return const Center(child: Text('Nessuna serie in watchlist'));
        }
        return FutureBuilder<List<TvShowDetails>>(
          future: Future.wait(ids.map(tmdbClient.getTvShowDetails)),
          builder: (context, detailsSnapshot) {
            if (!detailsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final shows = detailsSnapshot.data!;
            return ListView.builder(
              itemCount: shows.length,
              itemBuilder: (context, index) {
                final show = shows[index];
                return PosterListTile(
                  posterPath: show.posterPath,
                  title: show.name,
                  subtitle: '${show.numberOfSeasons} stagioni • ${show.status}',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DetailScreen(
                        tmdbId: show.id,
                        mediaType: MediaType.tv,
                        tmdbClient: tmdbClient,
                        watchlistRepository: watchlistRepository,
                        watchedRepository: watchedRepository,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _WatchlistMoviesTab extends StatelessWidget {
  final TmdbClient tmdbClient;
  final WatchlistRepository watchlistRepository;
  final WatchedRepository watchedRepository;

  const _WatchlistMoviesTab({
    required this.tmdbClient,
    required this.watchlistRepository,
    required this.watchedRepository,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<int>>(
      stream: watchlistRepository.watchMovieIds(),
      builder: (context, idsSnapshot) {
        final ids = idsSnapshot.data ?? [];
        if (ids.isEmpty) {
          return const Center(child: Text('Nessun film in watchlist'));
        }
        return FutureBuilder<List<MovieDetails>>(
          future: Future.wait(ids.map(tmdbClient.getMovieDetails)),
          builder: (context, detailsSnapshot) {
            if (!detailsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final movies = detailsSnapshot.data!;
            return ListView.builder(
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
                        tmdbClient: tmdbClient,
                        watchlistRepository: watchlistRepository,
                        watchedRepository: watchedRepository,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
