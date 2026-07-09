import 'package:cloud_firestore/cloud_firestore.dart';

/// Identifies a single tracked episode. Used both as the Firestore document
/// ID (`showId_season_episode`) and as a value type callers can compare.
class WatchedEpisodeId {
  final int showId;
  final int season;
  final int episode;

  const WatchedEpisodeId({
    required this.showId,
    required this.season,
    required this.episode,
  });

  String get docId => '${showId}_${season}_$episode';

  @override
  bool operator ==(Object other) =>
      other is WatchedEpisodeId &&
      other.showId == showId &&
      other.season == season &&
      other.episode == episode;

  @override
  int get hashCode => Object.hash(showId, season, episode);
}

/// Manages the `watched_episodes` and `watched_movies` collections under a
/// single user's document.
class WatchedRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  WatchedRepository({
    required FirebaseFirestore firestore,
    required String uid,
  }) : _firestore = firestore,
       _uid = uid;

  CollectionReference<Map<String, dynamic>> get _episodes =>
      _firestore.collection('users/$_uid/watched_episodes');

  CollectionReference<Map<String, dynamic>> get _movies =>
      _firestore.collection('users/$_uid/watched_movies');

  Future<void> markEpisodeWatched(WatchedEpisodeId id) {
    return _episodes.doc(id.docId).set({
      'showId': id.showId,
      'season': id.season,
      'episode': id.episode,
      'watchedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markEpisodeUnwatched(WatchedEpisodeId id) {
    return _episodes.doc(id.docId).delete();
  }

  /// Emits the set of watched episode IDs for a single show, so a detail
  /// screen can check "is this episode watched?" without loading the whole
  /// account's history. Documents with missing/malformed fields (should
  /// never happen via this repository's own writes, but defends against a
  /// manual edit or future migration bug) are skipped rather than crashing
  /// the whole stream.
  Stream<Set<WatchedEpisodeId>> watchedEpisodeIdsForShow(int showId) {
    return _episodes.where('showId', isEqualTo: showId).snapshots().map(
      (snapshot) => snapshot.docs
          .map((d) {
            final showId = d['showId'];
            final season = d['season'];
            final episode = d['episode'];
            if (showId is! int || season is! int || episode is! int) {
              return null;
            }
            return WatchedEpisodeId(
              showId: showId,
              season: season,
              episode: episode,
            );
          })
          .whereType<WatchedEpisodeId>()
          .toSet(),
    );
  }

  Future<void> markMovieWatched(int tmdbId) {
    return _movies.doc('$tmdbId').set({
      'watchedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markMovieUnwatched(int tmdbId) => _movies.doc('$tmdbId').delete();

  Future<bool> isMovieWatched(int tmdbId) async {
    final doc = await _movies.doc('$tmdbId').get();
    return doc.exists;
  }

  Stream<Set<int>> watchedMovieIds() {
    return _movies.snapshots().map(
      (snapshot) => snapshot.docs
          .map((d) => int.tryParse(d.id))
          .whereType<int>()
          .toSet(),
    );
  }
}
