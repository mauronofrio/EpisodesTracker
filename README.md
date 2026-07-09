# EpisodesTracker

A personal replica of [TV Time](https://www.tvtime.com/)'s core episode-tracking
features, built with Flutter and Firebase after TV Time announced it was
shutting down. Meant for a small, shared device (2-3 people), not a public
app — free to host on Firebase's free tier.

## Features

- **Watchlist** for TV shows and movies, backed by [TMDB](https://www.themoviedb.org/)
- **Episode-level watched tracking**, with a separate rewatch flag per episode
- **Per-season and per-show progress**: watched/aired counts, "mark season
  watched" (skips episodes that haven't aired yet), and three status
  indicators next to a show/season title:
  - green check — fully watched, including every episode a still-airing
    season/show has yet to release
  - light-green "=" — caught up with everything aired so far, but the
    season/show isn't finished yet
  - nothing — still behind
- Unaired episodes can be viewed but not marked watched (TMDB only exposes
  an air *date*, not a time, so the cutoff is end-of-day)
- **Calendar** view of upcoming episodes/releases
- **Push notifications** via Firebase Cloud Messaging
- In-app **update banner** that checks this repo's GitHub releases
- Google Sign-In (Firebase Auth), data scoped per user in Firestore

## Tech stack

- Flutter / Dart
- Firebase: Auth (Google Sign-In), Cloud Firestore, Cloud Messaging
- [TMDB API](https://developer.themoviedb.org/) (v4 read access token) for
  show/movie/episode metadata

## Project structure

```
lib/
  auth/           Firebase Auth wrapper (Google Sign-In)
  config/         Compile-time config (Env, dart-define values)
  data/           TMDB client, Firestore repositories, progress computation
  notifications/  Firebase Cloud Messaging registration
  screens/        App screens (watchlist, detail, season, calendar, login)
  theme/          App theming
  updates/        GitHub-releases update checker + banner
  widgets/        Shared widgets
test/             Unit and widget tests, mirroring lib/
android/          Android project (adaptive launcher icon, manifest)
firestore.rules   Firestore security rules (per-user data isolation)
```

## Setup

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (see
  `environment.sdk` in `pubspec.yaml` for the minimum Dart version)
- A Firebase project with Auth (Google provider), Cloud Firestore, and
  Cloud Messaging enabled
- A [TMDB](https://www.themoviedb.org/) account with a v4 API read access
  token

### Firebase

This repo already includes `android/app/google-services.json` and
`lib/firebase_options.dart` for the project's own Firebase instance. Those
files hold client-side config values, not secrets (they're safe to check
in, the same way a Google OAuth client ID is) — but if you fork this for
your own Firebase project, regenerate both with the FlutterFire CLI:

```
dart pub global activate flutterfire_cli
flutterfire configure
```

Then deploy the Firestore rules:

```
firebase deploy --only firestore:rules
```

### TMDB token

Create a `.env` file at the repo root (gitignored, never committed):

```
TMDB_READ_ACCESS_TOKEN=your-tmdb-v4-read-access-token
```

### Install dependencies

```
flutter pub get
```

## Running

```
flutter run --dart-define-from-file=.env
```

## Testing

```
flutter test
```

## Building

```
flutter build apk --debug --dart-define-from-file=.env
```
