/// Awaits [fetch], returning null instead of letting the error propagate.
///
/// Used when bulk-fetching details for a list of ids via `Future.wait`:
/// wrapping each individual fetch means one failing item (deleted from
/// TMDB, a timeout, a rate limit) degrades to "skip this one" instead of
/// aborting the whole batch.
Future<T?> fetchOrNull<T>(Future<T> Function() fetch) async {
  try {
    return await fetch();
  } catch (_) {
    return null;
  }
}
