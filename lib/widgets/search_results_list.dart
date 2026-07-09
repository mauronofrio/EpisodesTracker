import 'package:flutter/material.dart';

import '../data/firestore/watched_repository.dart';
import '../data/firestore/watchlist_repository.dart';
import '../data/models/search_result.dart';
import '../data/tmdb_client.dart';
import '../screens/detail_screen.dart';
import 'poster_list_tile.dart';

/// Fetches and renders TMDB search results for [query]. Re-fetches whenever
/// [query] changes (a new instance with a different query, or the same
/// instance rebuilt with a different query — either works via
/// [didUpdateWidget]). Meant to replace a screen's normal body while the
/// user has an active search query, per [DebouncedSearchField].
class SearchResultsList extends StatefulWidget {
  final String query;
  final TmdbClient tmdbClient;
  final WatchlistRepository watchlistRepository;
  final WatchedRepository watchedRepository;

  const SearchResultsList({
    super.key,
    required this.query,
    required this.tmdbClient,
    required this.watchlistRepository,
    required this.watchedRepository,
  });

  @override
  State<SearchResultsList> createState() => _SearchResultsListState();
}

class _SearchResultsListState extends State<SearchResultsList> {
  List<SearchResult> _results = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void didUpdateWidget(covariant SearchResultsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) _search();
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.tmdbClient.searchMulti(widget.query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Errore: $_error'));
    }
    if (_results.isEmpty) {
      return const Center(child: Text('Nessun risultato'));
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        return PosterListTile(
          posterPath: result.posterPath,
          title: result.title,
          subtitle: result.mediaType == MediaType.tv ? 'Serie TV' : 'Film',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DetailScreen(
                  tmdbId: result.id,
                  mediaType: result.mediaType,
                  tmdbClient: widget.tmdbClient,
                  watchlistRepository: widget.watchlistRepository,
                  watchedRepository: widget.watchedRepository,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
