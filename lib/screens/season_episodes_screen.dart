import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/firestore/watched_repository.dart';
import '../data/models/episode.dart';
import '../data/tmdb_client.dart';

class SeasonEpisodesScreen extends StatefulWidget {
  final int showId;
  final String showName;
  final int seasonNumber;
  final TmdbClient tmdbClient;
  final WatchedRepository watchedRepository;

  const SeasonEpisodesScreen({
    super.key,
    required this.showId,
    required this.showName,
    required this.seasonNumber,
    required this.tmdbClient,
    required this.watchedRepository,
  });

  @override
  State<SeasonEpisodesScreen> createState() => _SeasonEpisodesScreenState();
}

class _SeasonEpisodesScreenState extends State<SeasonEpisodesScreen> {
  late final Future<List<Episode>> _episodesFuture;
  List<Episode>? _loadedEpisodes;

  @override
  void initState() {
    super.initState();
    _episodesFuture = widget.tmdbClient.getSeasonEpisodes(
      widget.showId,
      widget.seasonNumber,
    );
    // Cached separately (with a setState once ready) so the "mark season
    // watched" AppBar action can enable itself without depending on the
    // FutureBuilder's own internal state.
    _episodesFuture.then((episodes) {
      if (mounted) setState(() => _loadedEpisodes = episodes);
    });
  }

  Future<void> _toggleWatched(WatchedEpisodeId id, bool checked) async {
    try {
      if (checked) {
        await widget.watchedRepository.markEpisodeWatched(id);
      } else {
        await widget.watchedRepository.markEpisodeUnwatched(id);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore: $e')));
    }
  }

  Future<void> _toggleRewatched(WatchedEpisodeId id, bool rewatched) async {
    try {
      await widget.watchedRepository.setEpisodeRewatched(id, rewatched);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore: $e')));
    }
  }

  Future<void> _markSeasonWatched() async {
    final episodes = _loadedEpisodes;
    if (episodes == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final airedEpisodeNumbers = episodes
        .where((e) => e.airDate != null && !e.airDate!.isAfter(today))
        .map((e) => e.episodeNumber)
        .toList();
    try {
      await widget.watchedRepository.markSeasonWatched(
        widget.showId,
        widget.seasonNumber,
        airedEpisodeNumbers,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.showName} - Stagione ${widget.seasonNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add_check),
            tooltip: 'Segna stagione vista',
            onPressed: _loadedEpisodes == null ? null : _markSeasonWatched,
          ),
        ],
      ),
      body: FutureBuilder<List<Episode>>(
        future: _episodesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          }
          final episodes = snapshot.data!;
          return StreamBuilder<Map<WatchedEpisodeId, bool>>(
            stream: widget.watchedRepository.watchedEpisodeIdsForShow(
              widget.showId,
            ),
            builder: (context, watchedSnapshot) {
              final watched = watchedSnapshot.data ?? const {};
              return ListView.builder(
                itemCount: episodes.length,
                itemBuilder: (context, index) {
                  final episode = episodes[index];
                  final id = WatchedEpisodeId(
                    showId: widget.showId,
                    season: widget.seasonNumber,
                    episode: episode.episodeNumber,
                  );
                  final isWatched = watched.containsKey(id);
                  final isRewatched = watched[id] ?? false;
                  return CheckboxListTile(
                    value: isWatched,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text('${episode.episodeNumber}. ${episode.name}'),
                    subtitle: episode.airDate == null
                        ? null
                        : Text(DateFormat('yyyy-MM-dd').format(episode.airDate!)),
                    secondary: IconButton(
                      icon: Icon(
                        Icons.replay_circle_filled,
                        color: isRewatched
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      tooltip: 'Rivisto',
                      onPressed: isWatched
                          ? () => _toggleRewatched(id, !isRewatched)
                          : null,
                    ),
                    onChanged: (checked) => _toggleWatched(id, checked == true),
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
