import 'dart:async';

import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../data/firestore/watched_repository.dart';
import '../data/firestore/watchlist_repository.dart';
import '../data/models/search_result.dart';
import '../data/tmdb_client.dart';
import '../widgets/poster_list_tile.dart';
import '../widgets/sign_out_button.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final AuthService authService;
  final TmdbClient tmdbClient;
  final WatchlistRepository watchlistRepository;
  final WatchedRepository watchedRepository;

  const SearchScreen({
    super.key,
    required this.authService,
    required this.tmdbClient,
    required this.watchlistRepository,
    required this.watchedRepository,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<SearchResult> _results = [];
  bool _loading = false;
  Object? _error;

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.tmdbClient.searchMulti(query);
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
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: false,
          decoration: const InputDecoration(
            hintText: 'Cerca serie o film...',
            border: InputBorder.none,
          ),
          onChanged: _onQueryChanged,
        ),
        actions: [SignOutButton(authService: widget.authService)],
      ),
      body: Builder(
        builder: (context) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_error != null) {
            return Center(child: Text('Errore: $_error'));
          }
          if (_results.isEmpty) {
            return const Center(child: Text('Cerca una serie o un film'));
          }
          return ListView.builder(
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final result = _results[index];
              return PosterListTile(
                posterPath: result.posterPath,
                title: result.title,
                subtitle: result.mediaType == MediaType.tv
                    ? 'Serie TV'
                    : 'Film',
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
        },
      ),
    );
  }
}
