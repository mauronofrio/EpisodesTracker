import 'package:cloud_firestore/cloud_firestore.dart';

/// Manages the two watchlist collections (`watchlist_shows`,
/// `watchlist_movies`) under a single user's document. TMDB IDs are used
/// directly as Firestore document IDs, so add/remove are idempotent.
class WatchlistRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  WatchlistRepository({
    required FirebaseFirestore firestore,
    required String uid,
  }) : _firestore = firestore,
       _uid = uid;

  CollectionReference<Map<String, dynamic>> get _shows =>
      _firestore.collection('users/$_uid/watchlist_shows');

  CollectionReference<Map<String, dynamic>> get _movies =>
      _firestore.collection('users/$_uid/watchlist_movies');

  Future<void> addShow(int tmdbId) {
    return _shows.doc('$tmdbId').set({
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeShow(int tmdbId) => _shows.doc('$tmdbId').delete();

  Future<bool> isShowInWatchlist(int tmdbId) async {
    final doc = await _shows.doc('$tmdbId').get();
    return doc.exists;
  }

  Stream<List<int>> watchShowIds() {
    return _shows.snapshots().map(
      (snapshot) => snapshot.docs.map((d) => int.parse(d.id)).toList(),
    );
  }

  Future<void> addMovie(int tmdbId) {
    return _movies.doc('$tmdbId').set({
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeMovie(int tmdbId) => _movies.doc('$tmdbId').delete();

  Future<bool> isMovieInWatchlist(int tmdbId) async {
    final doc = await _movies.doc('$tmdbId').get();
    return doc.exists;
  }

  Stream<List<int>> watchMovieIds() {
    return _movies.snapshots().map(
      (snapshot) => snapshot.docs.map((d) => int.parse(d.id)).toList(),
    );
  }
}
