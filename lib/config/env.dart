/// Compile-time configuration injected via `--dart-define-from-file=.env`.
///
/// The `.env` file is gitignored and never committed. Every build/run/test
/// invocation must pass `--dart-define-from-file=.env` or these values are
/// empty strings.
class Env {
  static const tmdbReadAccessToken = String.fromEnvironment(
    'TMDB_READ_ACCESS_TOKEN',
  );

  /// The OAuth 2.0 "Web client" ID from the Firebase project
  /// (episodestracker-25bf3), auto-generated when the Google sign-in
  /// provider was enabled in Firebase Auth. Not a secret — Google OAuth
  /// client IDs are meant to be embedded in client apps — so it's a plain
  /// constant rather than a `.env` value.
  static const googleSignInServerClientId =
      '745329621491-mjh4jsddl1trutd9ttovpudhv1m5tuud.apps.googleusercontent.com';
}
