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

  @override
  void initState() {
    super.initState();
    _episodesFuture = widget.tmdbClient.getSeasonEpisodes(
      widget.showId,
      widget.seasonNumber,
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.showName} - Stagione ${widget.seasonNumber}'),
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
          return StreamBuilder<Set<WatchedEpisodeId>>(
            stream: widget.watchedRepository.watchedEpisodeIdsForShow(
              widget.showId,
            ),
            builder: (context, watchedSnapshot) {
              final watched = watchedSnapshot.data ?? <WatchedEpisodeId>{};
              return ListView.builder(
                itemCount: episodes.length,
                itemBuilder: (context, index) {
                  final episode = episodes[index];
                  final id = WatchedEpisodeId(
                    showId: widget.showId,
                    season: widget.seasonNumber,
                    episode: episode.episodeNumber,
                  );
                  final isWatched = watched.contains(id);
                  return CheckboxListTile(
                    value: isWatched,
                    title: Text('${episode.episodeNumber}. ${episode.name}'),
                    subtitle: episode.airDate == null
                        ? null
                        : Text(DateFormat('yyyy-MM-dd').format(episode.airDate!)),
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
