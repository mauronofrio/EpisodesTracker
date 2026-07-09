/// Compile-time configuration injected via `--dart-define-from-file=.env`.
///
/// The `.env` file is gitignored and never committed. Every build/run/test
/// invocation must pass `--dart-define-from-file=.env` or these values are
/// empty strings.
class Env {
  static const tmdbReadAccessToken = String.fromEnvironment(
    'TMDB_READ_ACCESS_TOKEN',
  );
}
