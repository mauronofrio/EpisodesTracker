# Account Menu, IT/EN Localization, Search Bar Polish — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the direct logout AppBar icon with an account icon that opens a side menu (account header, GitHub link, IT/EN language switch, logout); fully localize the app (currently 100% hardcoded Italian strings) with English as the new default; round the search bar's corners and tighten its spacing to the AppBar actions.

**Architecture:** Flutter's official `flutter_localizations`/`intl` codegen (`flutter gen-l10n`) generates an `AppLocalizations` class from two ARB files (`lib/l10n/app_en.arb` template, `lib/l10n/app_it.arb`). A new `LocaleController` (`ValueNotifier<Locale>` backed by `SharedPreferences`) drives `MaterialApp.locale`; a small `LocaleControllerScope` `InheritedWidget` exposes it to descendants (mirrors the existing `UpdateBanner.of(context)` pattern already in the codebase) so no screen's constructor needs to change to reach it. A new `AppDrawer` (`endDrawer`) replaces `SignOutButton`, opened via a new `AccountMenuButton` AppBar icon.

**Tech Stack:** Flutter/Dart, `flutter_localizations` (SDK), `intl` (already a dependency), `shared_preferences` (new), existing `firebase_auth_mocks`/`mocktail`/`fake_cloud_firestore` test tooling.

## Global Constraints

- Full translation coverage: every user-facing string in the app gets an ARB key (spec: `docs/superpowers/specs/2026-07-09-account-menu-i18n-design.md`), except the "Episodes Tracker" brand name and the "Italiano"/"English" language-picker labels (language names are conventionally shown in their own native spelling regardless of active app language, not translated).
- Language preference is device-local (`SharedPreferences`), not per Google account.
- First launch with no saved preference: Italian if the device's own locale is Italian, English otherwise (English is the new default).
- Drawer is an `endDrawer` (opens from the right, matching the AppBar icon's position), with an account header (photo/name/email), a GitHub link, the language switch, and sign-out (same confirm dialog as today, moved from `SignOutButton`).
- Search bar: `OutlineInputBorder` rounded to 24px (same radius already used elsewhere in `AppTheme`), tighter `AppBar.titleSpacing`.
- `flutter analyze` clean and full `flutter test` green after every task.
- No AI co-author trailer in commits (standing user preference); commit locally after each task, do not push unless asked.

---

## Task 1: Localization scaffolding (dependencies, ARB files, generated class, test helper)

**Files:**
- Modify: `pubspec.yaml`
- Create: `l10n.yaml`
- Create: `lib/l10n/app_en.arb`
- Create: `lib/l10n/app_it.arb`
- Modify: `.gitignore`
- Create: `test/support/localized_test_app.dart`

**Interfaces:**
- Produces: generated `AppLocalizations` class at `lib/l10n/app_localizations.dart` (import path `package:episodes_tracker/l10n/app_localizations.dart`), with `AppLocalizations.localizationsDelegates` / `AppLocalizations.supportedLocales` static members and one getter/method per ARB key (e.g. `l10n.tagline`, `l10n.errorPrefix(String message)`). Every later task calls `AppLocalizations.of(context)!`.
- Produces: `Widget localizedTestApp({required Widget home, Locale locale = const Locale('it')})` in `test/support/localized_test_app.dart`, used by every widget test touched in this plan.

This task has no application logic of its own (pure scaffolding/config), so its "test" is that codegen succeeds and the project still analyzes cleanly — per the Task Right-Sizing guidance, setup/config steps are folded into the task that needs them rather than force-fit into a red/green unit test cycle.

- [ ] **Step 1: Add dependencies to `pubspec.yaml`**

In `pubspec.yaml`, under `dependencies:`, add `flutter_localizations` right after the existing `flutter:` SDK entry, and `shared_preferences` at the end of the dependency list:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # The following adds the Cupertino Icons font to your application.
  # Use with the CupertinoIcons class for iOS style icons.
  cupertino_icons: ^1.0.8
  firebase_core: ^4.11.0
  firebase_auth: ^6.5.4
  google_sign_in: ^7.2.0
  cloud_firestore: ^6.6.0
  firebase_messaging: ^16.4.1
  http: ^1.6.0
  package_info_plus: ^10.2.0
  url_launcher: ^6.3.2
  intl: ^0.20.3
  shared_preferences: ^2.3.3
```

Then, in the `flutter:` section near the bottom of the file, add `generate: true` right after `uses-material-design: true`:

```yaml
flutter:

  # The following line ensures that the Material Icons font is
  # included with your application, so that you can use the icons in
  # the material Icons class.
  uses-material-design: true

  # Enables `flutter gen-l10n` codegen (see l10n.yaml) from lib/pub get,
  # run, build, and test.
  generate: true
```

- [ ] **Step 2: Run `flutter pub get`**

Run: `flutter pub get`
Expected: succeeds; if `intl`'s pinned version conflicts with what `flutter_localizations` requires for the installed Flutter SDK, `pub get` will print the required range — bump the `intl: ^0.20.3` constraint in `pubspec.yaml` to whatever it reports and re-run until it succeeds.

- [ ] **Step 3: Create `l10n.yaml`**

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-dir: lib/l10n
synthetic-package: false
```

- [ ] **Step 4: Create `lib/l10n/app_en.arb`**

```json
{
  "@@locale": "en",
  "account": "Account",
  "tagline": "Series and movies you follow, all in one place.",
  "signInWithGoogle": "Sign in with Google",
  "signInFailed": "Sign-in failed: {error}",
  "@signInFailed": {
    "placeholders": {
      "error": {"type": "String"}
    }
  },
  "navCalendar": "Calendar",
  "tabShows": "Shows",
  "tabMovies": "Movies",
  "noShowsInWatchlist": "No shows in your watchlist",
  "noMoviesInWatchlist": "No movies in your watchlist",
  "errorPrefix": "Error: {message}",
  "@errorPrefix": {
    "placeholders": {
      "message": {"type": "String"}
    }
  },
  "watchedCount": "{watched}/{aired} episodes watched",
  "@watchedCount": {
    "placeholders": {
      "watched": {"type": "int"},
      "aired": {"type": "int"}
    }
  },
  "movieRelease": "Movie release",
  "today": "Today",
  "tomorrow": "Tomorrow",
  "noUpcomingReleases": "No upcoming releases in your watchlist",
  "inWatchlist": "In watchlist",
  "addToWatchlist": "Add to watchlist",
  "watched": "Watched",
  "markAsWatched": "Mark as watched",
  "nextEpisode": "Next episode",
  "markWatched": "Mark watched",
  "youAreCaughtUp": "You're caught up",
  "nextEpisodeSubtitle": "Next episode: {info}",
  "@nextEpisodeSubtitle": {
    "placeholders": {
      "info": {"type": "String"}
    }
  },
  "caughtUpWithEverythingAired": "You're caught up with everything aired",
  "seasons": "Seasons",
  "episodeCount": "{count} episodes",
  "@episodeCount": {
    "placeholders": {
      "count": {"type": "int"}
    }
  },
  "markSeasonWatched": "Mark season watched",
  "seasonAppBarTitle": "{showName} - Season {number}",
  "@seasonAppBarTitle": {
    "placeholders": {
      "showName": {"type": "String"},
      "number": {"type": "int"}
    }
  },
  "rewatched": "Rewatched",
  "unknownAirDate": "Unknown air date",
  "notYetAiredDate": "{date} · not yet aired",
  "@notYetAiredDate": {
    "placeholders": {
      "date": {"type": "String"}
    }
  },
  "noResults": "No results",
  "mediaTypeTv": "TV Series",
  "mediaTypeMovie": "Movie",
  "signOut": "Sign out",
  "confirmSignOut": "Do you want to sign out of this account?",
  "cancel": "Cancel",
  "githubProject": "GitHub Project",
  "updateAvailableTitle": "New version available",
  "updateAvailableBody": "Version {tag} is available.",
  "@updateAvailableBody": {
    "placeholders": {
      "tag": {"type": "String"}
    }
  },
  "close": "Close",
  "download": "Download",
  "updateAvailableTooltip": "New version available: {tag}",
  "@updateAvailableTooltip": {
    "placeholders": {
      "tag": {"type": "String"}
    }
  },
  "searchHint": "Search shows or movies..."
}
```

- [ ] **Step 5: Create `lib/l10n/app_it.arb`**

```json
{
  "@@locale": "it",
  "account": "Account",
  "tagline": "Serie e film che segui, in un unico posto.",
  "signInWithGoogle": "Accedi con Google",
  "signInFailed": "Accesso non riuscito: {error}",
  "navCalendar": "Calendario",
  "tabShows": "Serie",
  "tabMovies": "Film",
  "noShowsInWatchlist": "Nessuna serie in watchlist",
  "noMoviesInWatchlist": "Nessun film in watchlist",
  "errorPrefix": "Errore: {message}",
  "watchedCount": "{watched}/{aired} episodi visti",
  "movieRelease": "Uscita film",
  "today": "Oggi",
  "tomorrow": "Domani",
  "noUpcomingReleases": "Nessuna uscita imminente per la tua watchlist",
  "inWatchlist": "Nella watchlist",
  "addToWatchlist": "Aggiungi a watchlist",
  "watched": "Visto",
  "markAsWatched": "Segna come visto",
  "nextEpisode": "Prossimo episodio",
  "markWatched": "Segna visto",
  "youAreCaughtUp": "Sei aggiornato",
  "nextEpisodeSubtitle": "Prossimo episodio: {info}",
  "caughtUpWithEverythingAired": "Sei aggiornato con tutti gli episodi usciti",
  "seasons": "Stagioni",
  "episodeCount": "{count} episodi",
  "markSeasonWatched": "Segna stagione vista",
  "seasonAppBarTitle": "{showName} - Stagione {number}",
  "rewatched": "Rivisto",
  "unknownAirDate": "Data di uscita sconosciuta",
  "notYetAiredDate": "{date} · non ancora uscito",
  "noResults": "Nessun risultato",
  "mediaTypeTv": "Serie TV",
  "mediaTypeMovie": "Film",
  "signOut": "Esci",
  "confirmSignOut": "Vuoi disconnetterti da questo account?",
  "cancel": "Annulla",
  "githubProject": "Progetto GitHub",
  "updateAvailableTitle": "Nuova versione disponibile",
  "updateAvailableBody": "È disponibile la versione {tag}.",
  "close": "Chiudi",
  "download": "Scarica",
  "updateAvailableTooltip": "Nuova versione disponibile: {tag}",
  "searchHint": "Cerca serie o film..."
}
```

- [ ] **Step 6: Gitignore the generated output**

In `.gitignore`, add a new section (anywhere after the existing `.env` line is fine):

```
# Generated by `flutter gen-l10n` (see l10n.yaml) - regenerated
# automatically on pub get/run/build/test via pubspec.yaml's generate: true.
/lib/l10n/app_localizations*.dart
```

- [ ] **Step 7: Generate and verify**

Run: `flutter gen-l10n`
Expected: creates `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_it.dart` with no errors.

Run: `flutter analyze`
Expected: `No issues found!` (nothing consumes `AppLocalizations` yet, but the generated code itself must compile and the unused-file lint doesn't flag generated code).

- [ ] **Step 8: Create the shared test helper**

```dart
// test/support/localized_test_app.dart
import 'package:episodes_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Wraps [home] in a MaterialApp with the app's localization delegates
/// registered, so widgets calling `AppLocalizations.of(context)!` don't
/// throw in tests. Defaults to Italian since every pre-existing string
/// assertion in this test suite was written against the Italian text;
/// pass `locale: const Locale('en')` explicitly to verify English output.
Widget localizedTestApp({
  required Widget home,
  Locale locale = const Locale('it'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}
```

- [ ] **Step 9: Commit**

```bash
git add pubspec.yaml pubspec.lock l10n.yaml lib/l10n/app_en.arb lib/l10n/app_it.arb .gitignore test/support/localized_test_app.dart
git commit -m "Add flutter_localizations/shared_preferences and the IT/EN ARB dictionary"
```

---

## Task 2: `LocaleController` and `LocaleControllerScope`

**Files:**
- Create: `lib/config/locale_controller.dart`
- Test: `test/config/locale_controller_test.dart`

**Interfaces:**
- Consumes: `shared_preferences`'s `SharedPreferences` (from Task 1's new dependency).
- Produces: `LocaleController extends ValueNotifier<Locale>` with `static Future<LocaleController> load({required SharedPreferences prefs, required Locale deviceLocale})` and `Future<void> setLocale(Locale locale)`. Produces `LocaleControllerScope extends InheritedWidget` with `static LocaleController of(BuildContext context)`. Task 3 constructs the controller in `main.dart`; Task 8's `AppDrawer` reads it via `LocaleControllerScope.of(context)`.

- [ ] **Step 1: Write the failing test**

```dart
// test/config/locale_controller_test.dart
import 'package:episodes_tracker/config/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocaleController.load', () {
    test(
      'uses Italian on first launch when the device locale is Italian',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final controller = await LocaleController.load(
          prefs: prefs,
          deviceLocale: const Locale('it'),
        );

        expect(controller.value, const Locale('it'));
      },
    );

    test(
      'uses English on first launch for any non-Italian device locale',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final controller = await LocaleController.load(
          prefs: prefs,
          deviceLocale: const Locale('fr'),
        );

        expect(controller.value, const Locale('en'));
      },
    );

    test('persists the first-launch resolution immediately', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await LocaleController.load(
        prefs: prefs,
        deviceLocale: const Locale('it'),
      );

      expect(prefs.getString('locale'), 'it');
    });

    test(
      'reuses a previously saved locale instead of re-resolving from the '
      'device',
      () async {
        SharedPreferences.setMockInitialValues({'locale': 'en'});
        final prefs = await SharedPreferences.getInstance();

        final controller = await LocaleController.load(
          prefs: prefs,
          // Device is Italian, but a saved preference (from an earlier
          // explicit choice) must win.
          deviceLocale: const Locale('it'),
        );

        expect(controller.value, const Locale('en'));
      },
    );
  });

  group('LocaleController.setLocale', () {
    test('updates the value and persists the new locale', () async {
      SharedPreferences.setMockInitialValues({'locale': 'it'});
      final prefs = await SharedPreferences.getInstance();
      final controller = await LocaleController.load(
        prefs: prefs,
        deviceLocale: const Locale('it'),
      );

      await controller.setLocale(const Locale('en'));

      expect(controller.value, const Locale('en'));
      expect(prefs.getString('locale'), 'en');
    });

    test('notifies listeners when the locale changes', () async {
      SharedPreferences.setMockInitialValues({'locale': 'it'});
      final prefs = await SharedPreferences.getInstance();
      final controller = await LocaleController.load(
        prefs: prefs,
        deviceLocale: const Locale('it'),
      );
      var notified = false;
      controller.addListener(() => notified = true);

      await controller.setLocale(const Locale('en'));

      expect(notified, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/config/locale_controller_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:episodes_tracker/config/locale_controller.dart'`

- [ ] **Step 3: Write the implementation**

```dart
// lib/config/locale_controller.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app's current UI language and persists it to this device's
/// local storage (not per Google account - this app runs on a shared
/// device used by 2-3 people, so the language is a device-wide setting,
/// not a per-user one).
class LocaleController extends ValueNotifier<Locale> {
  static const _prefsKey = 'locale';
  final SharedPreferences _prefs;

  LocaleController._(this._prefs, super.initial);

  /// Resolves the starting locale: whatever was explicitly saved before,
  /// or - on first launch, when nothing is saved yet - Italian if the
  /// device's own language is Italian, English otherwise (the app's
  /// default). The first-launch resolution is persisted immediately so a
  /// later device-language change doesn't retroactively change it.
  static Future<LocaleController> load({
    required SharedPreferences prefs,
    required Locale deviceLocale,
  }) async {
    final saved = prefs.getString(_prefsKey);
    if (saved != null) {
      return LocaleController._(prefs, Locale(saved));
    }
    final resolved = deviceLocale.languageCode == 'it'
        ? const Locale('it')
        : const Locale('en');
    await prefs.setString(_prefsKey, resolved.languageCode);
    return LocaleController._(prefs, resolved);
  }

  Future<void> setLocale(Locale locale) async {
    value = locale;
    await _prefs.setString(_prefsKey, locale.languageCode);
  }
}

/// Exposes an ambient [LocaleController] to descendants (e.g. the account
/// drawer's language switch) without threading it through every screen's
/// constructor - the same pattern `UpdateBanner.of` uses for release info.
class LocaleControllerScope extends InheritedWidget {
  final LocaleController controller;

  const LocaleControllerScope({
    super.key,
    required this.controller,
    required super.child,
  });

  static LocaleController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<LocaleControllerScope>();
    assert(scope != null, 'No LocaleControllerScope found in context');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(LocaleControllerScope oldWidget) =>
      oldWidget.controller != controller;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/config/locale_controller_test.dart`
Expected: `00:0X +6: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/config/locale_controller.dart test/config/locale_controller_test.dart
git commit -m "Add LocaleController: device-local IT/EN preference with first-launch device-locale detection"
```

---

## Task 3: Wire locale + `AppLocalizations` into `main.dart`/`app.dart`

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/app.dart`

**Interfaces:**
- Consumes: `LocaleController.load` (Task 2), `AppLocalizations.localizationsDelegates`/`supportedLocales` (Task 1).
- Produces: `EpisodesTrackerApp` gains a required `localeController: LocaleController` constructor param. `MaterialApp` is locale-aware; `LocaleControllerScope` wraps everything under `home:`, so any screen (Task 8's `AppDrawer`) can call `LocaleControllerScope.of(context)`. No other screen's constructor changes in this task.

`HomeShell`/`WatchlistScreen`/`CalendarScreen` constructors are untouched here — the ambient `LocaleControllerScope` means `AppDrawer` (Task 8) reaches the controller without any prop drilling.

- [ ] **Step 1: Update `lib/main.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'auth/auth_service.dart';
import 'config/env.dart';
import 'config/locale_controller.dart';
import 'data/firestore/device_token_repository.dart';
import 'data/firestore/user_profile_repository.dart';
import 'firebase_options.dart';
import 'notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  final localeController = await LocaleController.load(
    prefs: prefs,
    deviceLocale: WidgetsBinding.instance.platformDispatcher.locale,
  );

  final googleAuth = GoogleSignInTokenProvider(GoogleSignIn.instance);
  await googleAuth.initialize(
    serverClientId: Env.googleSignInServerClientId,
  );
  final authService = AuthService(
    firebaseAuth: FirebaseAuth.instance,
    googleAuth: googleAuth,
  );

  final userProfileRepository = UserProfileRepository(
    firestore: FirebaseFirestore.instance,
  );
  final notificationService = NotificationService();
  // Keep the users/{uid} profile document in sync with the signed-in
  // Google account, and register this device's FCM token, every time the
  // sign-in state changes to a real user. On sign-out, stop listening for
  // token refreshes so a stale subscription doesn't write to the
  // now-signed-out user's Firestore doc (relevant on this app's shared
  // 2-3 user devices).
  authService.authStateChanges.listen((user) async {
    if (user == null) {
      await notificationService.stopListening();
      return;
    }
    try {
      await userProfileRepository.upsertProfile(
        uid: user.uid,
        displayName: user.displayName,
        email: user.email,
        photoURL: user.photoURL,
      );
    } catch (e) {
      debugPrint('Failed to upsert user profile for ${user.uid}: $e');
    }
    try {
      await notificationService.registerDeviceToken(
        DeviceTokenRepository(
          firestore: FirebaseFirestore.instance,
          uid: user.uid,
        ),
      );
    } catch (e) {
      debugPrint('Failed to register device token for ${user.uid}: $e');
    }
  });

  runApp(
    EpisodesTrackerApp(
      authService: authService,
      notificationService: notificationService,
      localeController: localeController,
    ),
  );
}
```

- [ ] **Step 2: Update `lib/app.dart`**

```dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'auth/auth_service.dart';
import 'config/env.dart';
import 'config/locale_controller.dart';
import 'data/firestore/watched_repository.dart';
import 'data/firestore/watchlist_repository.dart';
import 'data/tmdb_client.dart';
import 'l10n/app_localizations.dart';
import 'notifications/notification_service.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'updates/update_banner.dart';
import 'updates/update_checker.dart';

class EpisodesTrackerApp extends StatefulWidget {
  final AuthService authService;
  final NotificationService notificationService;
  final LocaleController localeController;

  const EpisodesTrackerApp({
    super.key,
    required this.authService,
    required this.notificationService,
    required this.localeController,
  });

  @override
  State<EpisodesTrackerApp> createState() => _EpisodesTrackerAppState();
}

class _EpisodesTrackerAppState extends State<EpisodesTrackerApp> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  late final TmdbClient _tmdbClient;

  @override
  void initState() {
    super.initState();
    _tmdbClient = TmdbClient(
      httpClient: http.Client(),
      readAccessToken: Env.tmdbReadAccessToken,
    );
    _foregroundMessageSubscription = widget
        .notificationService
        .onForegroundMessage
        .listen(_showForegroundNotification);
  }

  void _showForegroundNotification(RemoteMessage message) {
    final title = message.notification?.title;
    final body = message.notification?.body;
    if (title == null && body == null) return;
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text([title, body].whereType<String>().join(' - '))),
    );
  }

  @override
  void dispose() {
    _foregroundMessageSubscription?.cancel();
    _tmdbClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: widget.localeController,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Episodes Tracker',
          scaffoldMessengerKey: _scaffoldMessengerKey,
          theme: AppTheme.dark,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LocaleControllerScope(
            controller: widget.localeController,
            child: UpdateBanner(
              updateChecker: UpdateChecker(
                httpClient: http.Client(),
                owner: Env.githubReleasesOwner,
                repo: Env.githubReleasesRepo,
              ),
              child: StreamBuilder(
                stream: widget.authService.authStateChanges,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final user = snapshot.data;
                  if (user == null) {
                    return LoginScreen(authService: widget.authService);
                  }

                  final firestore = FirebaseFirestore.instance;
                  return HomeShell(
                    authService: widget.authService,
                    tmdbClient: _tmdbClient,
                    watchlistRepository: WatchlistRepository(
                      firestore: firestore,
                      uid: user.uid,
                    ),
                    watchedRepository: WatchedRepository(
                      firestore: firestore,
                      uid: user.uid,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
```

`AppLocalizations.localizationsDelegates` (generated by `flutter gen-l10n`) already includes the three standard `Global*Localizations.delegate` entries, so nothing else needs to be added to the list.

- [ ] **Step 3: Verify**

Run: `flutter analyze`
Expected: `No issues found!`

There's no existing test for `main.dart`/`app.dart` (neither had one before this plan; both require full Firebase bootstrapping the test suite doesn't mock anywhere else in this project) — Task 4's `login_screen_test.dart` is what proves the `AppLocalizations` pipeline actually resolves strings end-to-end.

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart lib/app.dart
git commit -m "Wire LocaleController and AppLocalizations into MaterialApp"
```

---

## Task 4: Translate `login_screen.dart`

**Files:**
- Modify: `lib/screens/login_screen.dart`
- Test: `test/screens/login_screen_test.dart` (new)

**Interfaces:**
- Consumes: `AppLocalizations.of(context)!.tagline`, `.signInWithGoogle`, `.signInFailed(String)` (Task 1). `localizedTestApp` (Task 1).

- [ ] **Step 1: Write the failing test**

```dart
// test/screens/login_screen_test.dart
import 'package:episodes_tracker/auth/auth_service.dart';
import 'package:episodes_tracker/screens/login_screen.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/localized_test_app.dart';

class MockGoogleAuthTokenProvider extends Mock
    implements GoogleAuthTokenProvider {}

void main() {
  late AuthService authService;

  setUp(() {
    authService = AuthService(
      firebaseAuth: MockFirebaseAuth(),
      googleAuth: MockGoogleAuthTokenProvider(),
    );
  });

  testWidgets('renders the Italian tagline and sign-in button by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(home: LoginScreen(authService: authService)),
    );

    expect(
      find.text('Serie e film che segui, in un unico posto.'),
      findsOneWidget,
    );
    expect(find.text('Accedi con Google'), findsOneWidget);
  });

  testWidgets(
    'renders the English tagline and sign-in button when the locale is '
    'English',
    (tester) async {
      await tester.pumpWidget(
        localizedTestApp(
          locale: const Locale('en'),
          home: LoginScreen(authService: authService),
        ),
      );

      expect(
        find.text('Series and movies you follow, all in one place.'),
        findsOneWidget,
      );
      expect(find.text('Sign in with Google'), findsOneWidget);
    },
  );
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/login_screen_test.dart`
Expected: FAIL — `find.text('Serie e film che segui, in un unico posto.')` finds nothing (the widget still renders the old hardcoded string with no localization wiring, or, if run before Step 3, simply doesn't reflect an EN variant at all).

- [ ] **Step 3: Update `lib/screens/login_screen.dart`**

```dart
import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;

  const LoginScreen({super.key, required this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSigningIn = false;

  Future<void> _handleSignIn() async {
    setState(() => _isSigningIn = true);
    try {
      await widget.authService.signInWithGoogle();
    } on SignInCanceledException {
      // User dismissed the sign-in UI; nothing to show.
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.signInFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.live_tv, size: 72, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                // Brand name - not translated, same in both languages.
                'Episodes Tracker',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.tagline,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (_isSigningIn)
                const CircularProgressIndicator()
              else
                FilledButton.icon(
                  onPressed: _handleSignIn,
                  icon: const Icon(Icons.login),
                  label: Text(l10n.signInWithGoogle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/screens/login_screen_test.dart`
Expected: `00:0X +2: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/screens/login_screen.dart test/screens/login_screen_test.dart
git commit -m "Translate LoginScreen; add its first IT/EN widget test"
```

---

## Task 5: Translate `home_shell.dart` and `debounced_search_field.dart`; round the search bar

**Files:**
- Modify: `lib/screens/home_shell.dart`
- Modify: `lib/widgets/debounced_search_field.dart`
- Modify: `test/widgets/debounced_search_field_test.dart`

**Interfaces:**
- Consumes: `AppLocalizations.of(context)!.navCalendar`, `.searchHint` (Task 1).
- Produces: `DebouncedSearchField.hintText` becomes nullable (`String?`, default `null`) instead of a hardcoded default string — falls back to `AppLocalizations.of(context)!.searchHint` when null. Existing callers (`WatchlistScreen`, `CalendarScreen`) already omit `hintText`, so they're unaffected by the signature change.

- [ ] **Step 1: Update `lib/screens/home_shell.dart`**

```dart
import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../data/firestore/watched_repository.dart';
import '../data/firestore/watchlist_repository.dart';
import '../data/tmdb_client.dart';
import '../l10n/app_localizations.dart';
import 'calendar_screen.dart';
import 'watchlist_screen.dart';

/// Bottom-navigation shell shown once the user is signed in: Watchlist,
/// Calendar. Each tab has its own search bar in the AppBar (see
/// DebouncedSearchField) instead of a separate dedicated search tab.
class HomeShell extends StatefulWidget {
  final AuthService authService;
  final TmdbClient tmdbClient;
  final WatchlistRepository watchlistRepository;
  final WatchedRepository watchedRepository;

  const HomeShell({
    super.key,
    required this.authService,
    required this.tmdbClient,
    required this.watchlistRepository,
    required this.watchedRepository,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screens = [
      WatchlistScreen(
        authService: widget.authService,
        tmdbClient: widget.tmdbClient,
        watchlistRepository: widget.watchlistRepository,
        watchedRepository: widget.watchedRepository,
      ),
      CalendarScreen(
        authService: widget.authService,
        tmdbClient: widget.tmdbClient,
        watchlistRepository: widget.watchlistRepository,
        watchedRepository: widget.watchedRepository,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.bookmark),
            // "Watchlist" is already the same word in Italian and
            // English - not localized.
            label: 'Watchlist',
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month),
            label: l10n.navCalendar,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Update `lib/widgets/debounced_search_field.dart`**

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// A search text field meant to sit in an AppBar's `title`. Reports the
/// trimmed query 400ms after the user stops typing (not on every
/// keystroke), and an empty string immediately when cleared.
class DebouncedSearchField extends StatefulWidget {
  final ValueChanged<String> onQueryChanged;
  final String? hintText;

  const DebouncedSearchField({
    super.key,
    required this.onQueryChanged,
    this.hintText,
  });

  @override
  State<DebouncedSearchField> createState() => _DebouncedSearchFieldState();
}

class _DebouncedSearchFieldState extends State<DebouncedSearchField> {
  final _controller = TextEditingController();
  Timer? _debounce;

  void _onChanged(String value) {
    setState(() {}); // refresh the clear button's visibility
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      widget.onQueryChanged('');
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => widget.onQueryChanged(value.trim()),
    );
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    widget.onQueryChanged('');
    setState(() {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: widget.hintText ?? AppLocalizations.of(context)!.searchHint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        isDense: true,
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(icon: const Icon(Icons.clear), onPressed: _clear),
      ),
      onChanged: _onChanged,
    );
  }
}
```

- [ ] **Step 3: Update `test/widgets/debounced_search_field_test.dart`**

Add the import and replace all three `MaterialApp(` calls with `localizedTestApp(` (the rest of each call is unchanged — same `home: Scaffold(...)` argument):

```dart
import 'package:episodes_tracker/widgets/debounced_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized_test_app.dart';

void main() {
  testWidgets('reports the trimmed query 400ms after typing stops', (
    tester,
  ) async {
    final queries = <String>[];
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          appBar: AppBar(
            title: DebouncedSearchField(onQueryChanged: queries.add),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '  breaking bad  ');
    // Not yet, still within the debounce window.
    await tester.pump(const Duration(milliseconds: 100));
    expect(queries, isEmpty);

    await tester.pump(const Duration(milliseconds: 350));
    expect(queries, ['breaking bad']);
  });

  testWidgets('reports an empty string immediately when the text is cleared', (
    tester,
  ) async {
    final queries = <String>[];
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          appBar: AppBar(
            title: DebouncedSearchField(onQueryChanged: queries.add),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump(const Duration(milliseconds: 450));
    expect(queries, ['a']);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(queries.last, '');
  });

  testWidgets('the clear button appears once there is text and clears it', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          appBar: AppBar(
            title: DebouncedSearchField(onQueryChanged: (_) {}),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.clear), findsNothing);

    await tester.enterText(find.byType(TextField), 'x');
    await tester.pump();
    expect(find.byIcon(Icons.clear), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();
    expect(find.byIcon(Icons.clear), findsNothing);
    expect(find.text('x'), findsNothing);
  });
}
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/widgets/debounced_search_field_test.dart`
Expected: `00:0X +3: All tests passed!`

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/screens/home_shell.dart lib/widgets/debounced_search_field.dart test/widgets/debounced_search_field_test.dart
git commit -m "Translate HomeShell nav label; round search bar corners and localize its hint"
```

---

## Task 6: Translate `search_results_list.dart`

**Files:**
- Modify: `lib/widgets/search_results_list.dart`
- Modify: `test/widgets/search_results_list_test.dart`

**Interfaces:**
- Consumes: `AppLocalizations.of(context)!.errorPrefix(String)`, `.noResults`, `.mediaTypeTv`, `.mediaTypeMovie` (Task 1).

- [ ] **Step 1: Update `lib/widgets/search_results_list.dart`**

```dart
import 'package:flutter/material.dart';

import '../data/firestore/watched_repository.dart';
import '../data/firestore/watchlist_repository.dart';
import '../data/models/search_result.dart';
import '../data/tmdb_client.dart';
import '../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(l10n.errorPrefix(_error.toString())));
    }
    if (_results.isEmpty) {
      return Center(child: Text(l10n.noResults));
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        return PosterListTile(
          posterPath: result.posterPath,
          title: result.title,
          subtitle: result.mediaType == MediaType.tv
              ? l10n.mediaTypeTv
              : l10n.mediaTypeMovie,
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
```

- [ ] **Step 2: Update `test/widgets/search_results_list_test.dart`**

Add the import and replace all three `MaterialApp(` calls with `localizedTestApp(` (unchanged `home: Scaffold(body: SearchResultsList(...))` argument in each). The Italian-text assertions (`'Nessun risultato'`, `find.textContaining('Errore')`) are unchanged since `localizedTestApp` defaults to Italian:

```dart
import 'dart:convert';

import 'package:episodes_tracker/data/firestore/watched_repository.dart';
import 'package:episodes_tracker/data/firestore/watchlist_repository.dart';
import 'package:episodes_tracker/data/tmdb_client.dart';
import 'package:episodes_tracker/widgets/search_results_list.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/localized_test_app.dart';

http.Response _searchResponse(String query) {
  return http.Response(
    jsonEncode({
      'page': 1,
      'results': query == 'breaking'
          ? [
              {
                'id': 1396,
                'media_type': 'tv',
                'name': 'Breaking Bad',
                'poster_path': null,
                'first_air_date': '2008-01-20',
                'overview': '',
              },
            ]
          : [],
      'total_pages': 1,
      'total_results': query == 'breaking' ? 1 : 0,
    }),
    200,
  );
}

void main() {
  late WatchlistRepository watchlistRepository;
  late WatchedRepository watchedRepository;

  setUp(() {
    final firestore = FakeFirebaseFirestore();
    watchlistRepository = WatchlistRepository(
      firestore: firestore,
      uid: 'user-1',
    );
    watchedRepository = WatchedRepository(firestore: firestore, uid: 'user-1');
  });

  testWidgets('shows results for the initial query', (tester) async {
    final tmdbClient = TmdbClient(
      httpClient: MockClient(
        (request) async =>
            _searchResponse(request.url.queryParameters['query']!),
      ),
      readAccessToken: 'test-token',
    );

    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: SearchResultsList(
            query: 'breaking',
            tmdbClient: tmdbClient,
            watchlistRepository: watchlistRepository,
            watchedRepository: watchedRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Breaking Bad'), findsOneWidget);
  });

  testWidgets('re-fetches when the query changes', (tester) async {
    final tmdbClient = TmdbClient(
      httpClient: MockClient(
        (request) async =>
            _searchResponse(request.url.queryParameters['query']!),
      ),
      readAccessToken: 'test-token',
    );

    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: SearchResultsList(
            query: 'breaking',
            tmdbClient: tmdbClient,
            watchlistRepository: watchlistRepository,
            watchedRepository: watchedRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Breaking Bad'), findsOneWidget);

    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: SearchResultsList(
            query: 'nothing-matches',
            tmdbClient: tmdbClient,
            watchlistRepository: watchlistRepository,
            watchedRepository: watchedRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Breaking Bad'), findsNothing);
    expect(find.text('Nessun risultato'), findsOneWidget);
  });

  testWidgets('shows an error message when the search fails', (tester) async {
    final tmdbClient = TmdbClient(
      httpClient: MockClient(
        (request) async => http.Response('server error', 500),
      ),
      readAccessToken: 'test-token',
    );

    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: SearchResultsList(
            query: 'breaking',
            tmdbClient: tmdbClient,
            watchlistRepository: watchlistRepository,
            watchedRepository: watchedRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Errore'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run tests**

Run: `flutter test test/widgets/search_results_list_test.dart`
Expected: `00:0X +3: All tests passed!`

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/search_results_list.dart test/widgets/search_results_list_test.dart
git commit -m "Translate SearchResultsList"
```

---

## Task 7: Translate `update_banner.dart` and `update_indicator_button.dart`

**Files:**
- Modify: `lib/updates/update_banner.dart`
- Modify: `lib/widgets/update_indicator_button.dart`
- Modify: `test/updates/update_banner_test.dart`
- Modify: `test/widgets/update_indicator_button_test.dart`

**Interfaces:**
- Consumes: `AppLocalizations.of(context)!.updateAvailableTitle`, `.updateAvailableBody(String)`, `.close`, `.download`, `.updateAvailableTooltip(String)` (Task 1).

- [ ] **Step 1: Update `lib/updates/update_banner.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import 'update_checker.dart';

/// Wraps [child] and, once on startup, checks GitHub Releases for a newer
/// version. As soon as one is found it immediately opens [showUpdateDialog]
/// once, then exposes the release to descendants via [UpdateBanner.of] so a
/// small icon (e.g. UpdateIndicatorButton) can reopen the same dialog later
/// — this widget otherwise renders no persistent UI of its own.
class UpdateBanner extends StatefulWidget {
  final UpdateChecker updateChecker;
  final Widget child;

  const UpdateBanner({
    super.key,
    required this.updateChecker,
    required this.child,
  });

  /// The available newer release, or null if none is available (or the
  /// check hasn't completed yet).
  static ReleaseInfo? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_UpdateScope>()
        ?.release;
  }

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner> {
  ReleaseInfo? _newerRelease;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      final release = await widget.updateChecker.fetchLatestRelease();
      if (release == null) return;
      final currentInfo = await PackageInfo.fromPlatform();
      if (!UpdateChecker.isNewer(
        currentVersion: currentInfo.version,
        latestTag: release.tagName,
      )) {
        return;
      }
      if (!mounted) return;
      setState(() => _newerRelease = release);
      // Wait for this frame to finish building before opening the dialog -
      // showDialog needs a Navigator already present in the tree.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showUpdateDialog(context, release);
      });
    } catch (_) {
      // Update checks are best-effort; a failure here must never block
      // the app from being usable.
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UpdateScope(release: _newerRelease, child: widget.child);
  }
}

class _UpdateScope extends InheritedWidget {
  final ReleaseInfo? release;

  const _UpdateScope({required this.release, required super.child});

  @override
  bool updateShouldNotify(_UpdateScope oldWidget) =>
      oldWidget.release != release;
}

/// Opens a small centered dialog (not a full page/route) with the release
/// version and a download link. Shared by the automatic startup prompt
/// above and [UpdateIndicatorButton]'s manual reopen, so both look and
/// behave identically.
void showUpdateDialog(BuildContext context, ReleaseInfo release) {
  final l10n = AppLocalizations.of(context)!;
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.updateAvailableTitle),
      content: Text(l10n.updateAvailableBody(release.tagName)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
        if (release.apkDownloadUrl != null)
          FilledButton(
            onPressed: () => launchUrl(
              Uri.parse(release.apkDownloadUrl!),
              mode: LaunchMode.externalApplication,
            ),
            child: Text(l10n.download),
          ),
      ],
    ),
  );
}
```

- [ ] **Step 2: Update `lib/widgets/update_indicator_button.dart`**

```dart
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../updates/update_banner.dart';

/// An AppBar action that only renders when [UpdateBanner] has found a newer
/// release. [UpdateBanner] already opens the update dialog automatically
/// once, on startup; this button lets the user reopen the same dialog later
/// after closing it, from any screen that includes this button.
class UpdateIndicatorButton extends StatelessWidget {
  const UpdateIndicatorButton({super.key});

  @override
  Widget build(BuildContext context) {
    final release = UpdateBanner.of(context);
    if (release == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    return IconButton(
      icon: const Icon(Icons.system_update_outlined),
      tooltip: l10n.updateAvailableTooltip(release.tagName),
      onPressed: () => showUpdateDialog(context, release),
    );
  }
}
```

- [ ] **Step 3: Update `test/updates/update_banner_test.dart`**

Add the import, replace all five `MaterialApp(` calls with `localizedTestApp(` (unchanged arguments in each — `home: UpdateBanner(...)`):

```dart
import 'package:episodes_tracker/updates/update_banner.dart';
import 'package:episodes_tracker/updates/update_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../support/localized_test_app.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Episodes Tracker',
      packageName: 'com.mauronofrio.episodes_tracker',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  UpdateChecker checkerReturning(String tagName) {
    return UpdateChecker(
      httpClient: MockClient((request) async {
        return http.Response('{"tag_name": "$tagName", "assets": []}', 200);
      }),
      owner: 'mauronofrio',
      repo: 'EpisodesTracker',
    );
  }

  testWidgets('UpdateBanner.of exposes the release once a newer one is found', (
    tester,
  ) async {
    ReleaseInfo? seen;
    await tester.pumpWidget(
      localizedTestApp(
        home: UpdateBanner(
          updateChecker: checkerReturning('v2.0.0'),
          child: Builder(
            builder: (context) {
              seen = UpdateBanner.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(seen, isNull);

    await tester.pumpAndSettle();

    expect(seen?.tagName, 'v2.0.0');
  });

  testWidgets('UpdateBanner.of stays null when already up to date', (
    tester,
  ) async {
    ReleaseInfo? seen;
    await tester.pumpWidget(
      localizedTestApp(
        home: UpdateBanner(
          updateChecker: checkerReturning('v1.0.0'),
          child: Builder(
            builder: (context) {
              seen = UpdateBanner.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(seen, isNull);
  });

  testWidgets('automatically opens the update dialog once on startup', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: UpdateBanner(
          updateChecker: checkerReturning('v2.0.0'),
          child: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );

    expect(find.byType(AlertDialog), findsNothing);

    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('È disponibile la versione v2.0.0.'), findsOneWidget);
  });

  testWidgets('does not reopen the dialog automatically after it is closed', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: UpdateBanner(
          updateChecker: checkerReturning('v2.0.0'),
          child: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Chiudi'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('does not open a dialog when already up to date', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: UpdateBanner(
          updateChecker: checkerReturning('v1.0.0'),
          child: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
```

- [ ] **Step 4: Update `test/widgets/update_indicator_button_test.dart`**

Add the import and change the `wrap` helper's `MaterialApp(` to `localizedTestApp(` (unchanged argument):

```dart
import 'package:episodes_tracker/updates/update_banner.dart';
import 'package:episodes_tracker/updates/update_checker.dart';
import 'package:episodes_tracker/widgets/update_indicator_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../support/localized_test_app.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Episodes Tracker',
      packageName: 'com.mauronofrio.episodes_tracker',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  UpdateChecker checkerReturning(String tagName) {
    return UpdateChecker(
      httpClient: MockClient((request) async {
        return http.Response('{"tag_name": "$tagName", "assets": []}', 200);
      }),
      owner: 'mauronofrio',
      repo: 'EpisodesTracker',
    );
  }

  Widget wrap(UpdateChecker checker) {
    return localizedTestApp(
      home: UpdateBanner(
        updateChecker: checker,
        child: Scaffold(
          appBar: AppBar(actions: [const UpdateIndicatorButton()]),
        ),
      ),
    );
  }

  testWidgets('renders nothing when already up to date', (tester) async {
    await tester.pumpWidget(wrap(checkerReturning('v1.0.0')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.system_update_outlined), findsNothing);
  });

  testWidgets(
    'shows the icon when a newer release exists, and reopens the same '
    'centered dialog (not a new route) on tap after the automatic one '
    'is closed',
    (tester) async {
      await tester.pumpWidget(wrap(checkerReturning('v2.0.0')));
      await tester.pumpAndSettle();

      // UpdateBanner already auto-opened the dialog once on startup.
      expect(find.byIcon(Icons.system_update_outlined), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Chiudi'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);

      await tester.tap(find.byIcon(Icons.system_update_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('È disponibile la versione v2.0.0.'), findsOneWidget);

      await tester.tap(find.text('Chiudi'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      // The underlying screen (with the button) is still there - it was a
      // dialog, not a full-page navigation.
      expect(find.byIcon(Icons.system_update_outlined), findsOneWidget);
    },
  );
}
```

- [ ] **Step 5: Run tests**

Run: `flutter test test/updates/update_banner_test.dart test/widgets/update_indicator_button_test.dart`
Expected: `00:0X +7: All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add lib/updates/update_banner.dart lib/widgets/update_indicator_button.dart test/updates/update_banner_test.dart test/widgets/update_indicator_button_test.dart
git commit -m "Translate the update dialog and its AppBar reopen tooltip"
```

---

## Task 8: `AppDrawer` + `AccountMenuButton`; delete `SignOutButton`

**Files:**
- Create: `lib/widgets/app_drawer.dart`
- Test: `test/widgets/app_drawer_test.dart`
- Delete: `lib/widgets/sign_out_button.dart`

**Interfaces:**
- Consumes: `AuthService.currentUser`/`signOut()` (existing), `LocaleControllerScope.of(context)` (Task 2), `AppLocalizations.of(context)!.signOut/.confirmSignOut/.cancel/.githubProject/.account` (Task 1).
- Produces: `AppDrawer({required AuthService authService})` (a `Drawer` meant for `Scaffold.endDrawer`) and `AccountMenuButton` (a parameterless AppBar `IconButton` that calls `Scaffold.of(context).openEndDrawer()`). Task 9 and Task 10 wire both into `WatchlistScreen`/`CalendarScreen`, replacing `SignOutButton`.

- [ ] **Step 1: Write the failing test**

```dart
// test/widgets/app_drawer_test.dart
import 'package:episodes_tracker/auth/auth_service.dart';
import 'package:episodes_tracker/config/locale_controller.dart';
import 'package:episodes_tracker/widgets/app_drawer.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/localized_test_app.dart';

class MockGoogleAuthTokenProvider extends Mock
    implements GoogleAuthTokenProvider {}

void main() {
  late AuthService authService;
  late LocaleController localeController;

  setUp(() async {
    final firebaseAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'user-1',
        email: 'mario@example.com',
        displayName: 'Mario',
      ),
    );
    authService = AuthService(
      firebaseAuth: firebaseAuth,
      googleAuth: MockGoogleAuthTokenProvider(),
    );
    SharedPreferences.setMockInitialValues({'locale': 'it'});
    final prefs = await SharedPreferences.getInstance();
    localeController = await LocaleController.load(
      prefs: prefs,
      deviceLocale: const Locale('it'),
    );
  });

  Widget wrap() {
    return localizedTestApp(
      home: LocaleControllerScope(
        controller: localeController,
        child: Scaffold(
          endDrawer: AppDrawer(authService: authService),
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openDrawer(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the signed-in account name and email', (tester) async {
    await tester.pumpWidget(wrap());
    await openDrawer(tester);

    expect(find.text('Mario'), findsOneWidget);
    expect(find.text('mario@example.com'), findsOneWidget);
  });

  testWidgets('shows GitHub link, language switch, and sign-out tiles', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await openDrawer(tester);

    expect(find.text('Progetto GitHub'), findsOneWidget);
    expect(find.text('Italiano / English'), findsOneWidget);
    expect(find.text('Esci'), findsOneWidget);
  });

  testWidgets('tapping sign-out opens the confirmation dialog', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await openDrawer(tester);

    await tester.tap(find.text('Esci'));
    await tester.pumpAndSettle();

    expect(
      find.text('Vuoi disconnetterti da questo account?'),
      findsOneWidget,
    );
  });

  testWidgets('toggling the language switch updates the LocaleController', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await openDrawer(tester);

    expect(localeController.value, const Locale('it'));

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(localeController.value, const Locale('en'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/app_drawer_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:episodes_tracker/widgets/app_drawer.dart'`

- [ ] **Step 3: Write the implementation**

```dart
// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/auth_service.dart';
import '../config/locale_controller.dart';
import '../l10n/app_localizations.dart';

/// Account menu opened from [AccountMenuButton]: signed-in account info, a
/// link to the project's GitHub repo, the IT/EN language switch, and
/// sign-out (moved here from the old standalone SignOutButton AppBar icon).
class AppDrawer extends StatelessWidget {
  final AuthService authService;

  const AppDrawer({super.key, required this.authService});

  Future<void> _confirmAndSignOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.confirmSignOut),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await authService.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = authService.currentUser;
    final localeController = LocaleControllerScope.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.displayName ?? ''),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? const Icon(Icons.person)
                    : null,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: Text(l10n.githubProject),
              onTap: () => launchUrl(
                Uri.parse('https://github.com/mauronofrio/EpisodesTracker'),
                mode: LaunchMode.externalApplication,
              ),
            ),
            ValueListenableBuilder<Locale>(
              valueListenable: localeController,
              builder: (context, locale, _) {
                return SwitchListTile(
                  secondary: const Icon(Icons.language),
                  // Language names are shown in their own native spelling
                  // regardless of the active app language - not localized.
                  title: const Text('Italiano / English'),
                  value: locale.languageCode == 'en',
                  onChanged: (useEnglish) => localeController.setLocale(
                    Locale(useEnglish ? 'en' : 'it'),
                  ),
                );
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(l10n.signOut),
              onTap: () => _confirmAndSignOut(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// AppBar action that opens [AppDrawer] (registered as the Scaffold's
/// `endDrawer`) instead of signing out directly.
class AccountMenuButton extends StatelessWidget {
  const AccountMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      icon: const Icon(Icons.account_circle),
      tooltip: l10n.account,
      onPressed: () => Scaffold.of(context).openEndDrawer(),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widgets/app_drawer_test.dart`
Expected: `00:0X +4: All tests passed!`

- [ ] **Step 5: Delete the old `SignOutButton`**

`SignOutButton` isn't referenced from `AppDrawer` — its confirm/sign-out logic was inlined into `AppDrawer._confirmAndSignOut` in Step 3. Delete the now-unused file (its only two consumers, `WatchlistScreen`/`CalendarScreen`, are updated in Tasks 9-10, but deleting it now surfaces any missed reference immediately via `flutter analyze`):

```bash
rm lib/widgets/sign_out_button.dart
```

Run: `flutter analyze`
Expected: errors in `lib/screens/watchlist_screen.dart` and `lib/screens/calendar_screen.dart` (`Target of URI doesn't exist: '../widgets/sign_out_button.dart'`) — **expected and fine**, Tasks 9 and 10 fix both in the next two tasks. Do not leave this task half-done past the commit below; Tasks 9/10 must follow immediately.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/app_drawer.dart test/widgets/app_drawer_test.dart
git rm lib/widgets/sign_out_button.dart
git commit -m "Add AppDrawer (account header, GitHub link, language switch, sign-out); remove SignOutButton"
```

---

## Task 9: Wire `AppDrawer` into `WatchlistScreen`; translate its own strings

**Files:**
- Modify: `lib/screens/watchlist_screen.dart`

**Interfaces:**
- Consumes: `AppDrawer`, `AccountMenuButton` (Task 8), `AppLocalizations.of(context)!.tabShows/.tabMovies/.noShowsInWatchlist/.noMoviesInWatchlist/.errorPrefix/.watchedCount` (Task 1).

This task doesn't add a new test file — `WatchlistScreen` had no existing test before this plan (confirmed: only `detail_screen_test.dart`, `caught_up_indicator_test.dart`, `debounced_search_field_test.dart`, `poster_list_tile_test.dart`, `search_results_list_test.dart`, `update_indicator_button_test.dart` exist under `test/screens`/`test/widgets`), and adding full Firestore/TMDB-backed watchlist screen test scaffolding is out of scope for this plan (would require its own set of fakes/fixtures beyond what translating existing strings needs). Verify via `flutter analyze` + the existing test suite staying green, and via manual on-device check per the project's established workflow.

- [ ] **Step 1: Update `lib/screens/watchlist_screen.dart`**

```dart
import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../data/firestore/watched_repository.dart';
import '../data/firestore/watchlist_repository.dart';
import '../data/models/movie_details.dart';
import '../data/models/search_result.dart';
import '../data/models/tv_show_details.dart';
import '../data/resilient_fetch.dart';
import '../data/show_progress.dart';
import '../data/tmdb_client.dart';
import '../l10n/app_localizations.dart';
import '../widgets/app_drawer.dart';
import '../widgets/caught_up_indicator.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/poster_list_tile.dart';
import '../widgets/search_results_list.dart';
import '../widgets/update_indicator_button.dart';
import 'detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  final AuthService authService;
  final TmdbClient tmdbClient;
  final WatchlistRepository watchlistRepository;
  final WatchedRepository watchedRepository;

  const WatchlistScreen({
    super.key,
    required this.authService,
    required this.tmdbClient,
    required this.watchlistRepository,
    required this.watchedRepository,
  });

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  String _query = '';
  // Bumped to force DebouncedSearchField to rebuild with a fresh, empty
  // TextEditingController when search is dismissed via the back arrow/
  // system back (as opposed to the user clearing the field themselves).
  int _searchFieldGeneration = 0;

  void _exitSearch() {
    setState(() {
      _query = '';
      _searchFieldGeneration++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final searching = _query.isNotEmpty;
    return PopScope(
      canPop: !searching,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && searching) _exitSearch();
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          endDrawer: AppDrawer(authService: widget.authService),
          appBar: AppBar(
            titleSpacing: 8,
            leading: searching
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _exitSearch,
                  )
                : null,
            title: DebouncedSearchField(
              key: ValueKey(_searchFieldGeneration),
              onQueryChanged: (query) => setState(() => _query = query),
            ),
            actions: const [UpdateIndicatorButton(), AccountMenuButton()],
            bottom: searching
                ? null
                : TabBar(
                    tabs: [
                      Tab(text: l10n.tabShows),
                      Tab(text: l10n.tabMovies),
                    ],
                  ),
          ),
          body: searching
              ? SearchResultsList(
                  query: _query,
                  tmdbClient: widget.tmdbClient,
                  watchlistRepository: widget.watchlistRepository,
                  watchedRepository: widget.watchedRepository,
                )
              : TabBarView(
                  children: [
                    _WatchlistShowsTab(
                      tmdbClient: widget.tmdbClient,
                      watchlistRepository: widget.watchlistRepository,
                      watchedRepository: widget.watchedRepository,
                    ),
                    _WatchlistMoviesTab(
                      tmdbClient: widget.tmdbClient,
                      watchlistRepository: widget.watchlistRepository,
                      watchedRepository: widget.watchedRepository,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _WatchlistShowsTab extends StatefulWidget {
  final TmdbClient tmdbClient;
  final WatchlistRepository watchlistRepository;
  final WatchedRepository watchedRepository;

  const _WatchlistShowsTab({
    required this.tmdbClient,
    required this.watchlistRepository,
    required this.watchedRepository,
  });

  @override
  State<_WatchlistShowsTab> createState() => _WatchlistShowsTabState();
}

class _WatchlistShowsTabState extends State<_WatchlistShowsTab> {
  Future<void> _openDetail(BuildContext context, int showId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailScreen(
          tmdbId: showId,
          mediaType: MediaType.tv,
          tmdbClient: widget.tmdbClient,
          watchlistRepository: widget.watchlistRepository,
          watchedRepository: widget.watchedRepository,
        ),
      ),
    );
    // Watched state may have changed inside DetailScreen; rebuild so every
    // ShowProgress FutureBuilder below re-fetches instead of showing what
    // was cached before the user navigated away.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<int>>(
      stream: widget.watchlistRepository.watchShowIds(),
      builder: (context, idsSnapshot) {
        final ids = idsSnapshot.data ?? [];
        if (ids.isEmpty) {
          return Center(child: Text(l10n.noShowsInWatchlist));
        }
        return FutureBuilder<List<TvShowDetails?>>(
          future: Future.wait(
            ids.map(
              (id) => fetchOrNull(() => widget.tmdbClient.getTvShowDetails(id)),
            ),
          ),
          builder: (context, detailsSnapshot) {
            if (detailsSnapshot.hasError) {
              return Center(
                child: Text(l10n.errorPrefix(detailsSnapshot.error.toString())),
              );
            }
            if (!detailsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final shows = detailsSnapshot.data!
                .whereType<TvShowDetails>()
                .toList();
            return ListView.builder(
              itemCount: shows.length,
              itemBuilder: (context, index) {
                final show = shows[index];
                return FutureBuilder<ShowProgress>(
                  future: computeShowProgress(
                    tmdbClient: widget.tmdbClient,
                    watchedRepository: widget.watchedRepository,
                    show: show,
                  ),
                  builder: (context, progressSnapshot) {
                    final progress = progressSnapshot.data;
                    final subtitle = progress == null
                        ? show.status
                        : l10n.watchedCount(
                            progress.watchedCount,
                            progress.airedCount,
                          );
                    final isComplete =
                        progress?.isShowComplete(show.seasons) ?? false;
                    final isCaughtUpButOngoing =
                        progress?.isShowCaughtUpButOngoing(show.seasons) ??
                        false;
                    return PosterListTile(
                      posterPath: show.posterPath,
                      title: show.name,
                      subtitle: subtitle,
                      titleSuffix: isComplete
                          ? const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 18,
                            )
                          : isCaughtUpButOngoing
                          ? const CaughtUpIndicator(size: 18)
                          : null,
                      onTap: () => _openDetail(context, show.id),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _WatchlistMoviesTab extends StatelessWidget {
  final TmdbClient tmdbClient;
  final WatchlistRepository watchlistRepository;
  final WatchedRepository watchedRepository;

  const _WatchlistMoviesTab({
    required this.tmdbClient,
    required this.watchlistRepository,
    required this.watchedRepository,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<int>>(
      stream: watchlistRepository.watchMovieIds(),
      builder: (context, idsSnapshot) {
        final ids = idsSnapshot.data ?? [];
        if (ids.isEmpty) {
          return Center(child: Text(l10n.noMoviesInWatchlist));
        }
        return FutureBuilder<List<MovieDetails?>>(
          future: Future.wait(
            ids.map((id) => fetchOrNull(() => tmdbClient.getMovieDetails(id))),
          ),
          builder: (context, detailsSnapshot) {
            if (detailsSnapshot.hasError) {
              return Center(
                child: Text(l10n.errorPrefix(detailsSnapshot.error.toString())),
              );
            }
            if (!detailsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final movies = detailsSnapshot.data!
                .whereType<MovieDetails>()
                .toList();
            return ListView.builder(
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movie = movies[index];
                return PosterListTile(
                  posterPath: movie.posterPath,
                  title: movie.title,
                  subtitle: movie.status,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DetailScreen(
                        tmdbId: movie.id,
                        mediaType: MediaType.movie,
                        tmdbClient: tmdbClient,
                        watchlistRepository: watchlistRepository,
                        watchedRepository: watchedRepository,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
```

- [ ] **Step 2: Run analyze and the full suite**

Run: `flutter analyze`
Expected: no errors referencing `watchlist_screen.dart` (the `calendar_screen.dart` error from Task 8 Step 5 is still expected until Task 10).

Run: `flutter test`
Expected: all currently-passing tests stay green (none directly exercise `WatchlistScreen`).

- [ ] **Step 3: Commit**

```bash
git add lib/screens/watchlist_screen.dart
git commit -m "Wire AppDrawer/AccountMenuButton into WatchlistScreen; translate its strings"
```

---

## Task 10: Wire `AppDrawer` into `CalendarScreen`; translate its own strings

**Files:**
- Modify: `lib/screens/calendar_screen.dart`

**Interfaces:**
- Consumes: `AppDrawer`, `AccountMenuButton` (Task 8), `AppLocalizations.of(context)!.movieRelease/.today/.tomorrow/.errorPrefix/.noUpcomingReleases` (Task 1).

Same testing note as Task 9: `CalendarScreen` had no existing test before this plan; verified via `flutter analyze` + full suite staying green + manual on-device check.

- [ ] **Step 1: Update `lib/screens/calendar_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../auth/auth_service.dart';
import '../data/firestore/watched_repository.dart';
import '../data/firestore/watchlist_repository.dart';
import '../data/models/movie_details.dart';
import '../data/models/search_result.dart';
import '../data/models/tv_show_details.dart';
import '../data/resilient_fetch.dart';
import '../data/tmdb_client.dart';
import '../l10n/app_localizations.dart';
import '../widgets/app_drawer.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/poster_list_tile.dart';
import '../widgets/search_results_list.dart';
import '../widgets/update_indicator_button.dart';
import 'detail_screen.dart';

class _UpcomingItem {
  final int tmdbId;
  final MediaType mediaType;
  final String title;
  final String? posterPath;
  final DateTime date;
  final String subtitle;

  const _UpcomingItem({
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    required this.posterPath,
    required this.date,
    required this.subtitle,
  });
}

class CalendarScreen extends StatefulWidget {
  final AuthService authService;
  final TmdbClient tmdbClient;
  final WatchlistRepository watchlistRepository;
  final WatchedRepository watchedRepository;

  const CalendarScreen({
    super.key,
    required this.authService,
    required this.tmdbClient,
    required this.watchlistRepository,
    required this.watchedRepository,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  Future<List<_UpcomingItem>>? _future;
  String _query = '';
  int _searchFieldGeneration = 0;

  @override
  void initState() {
    super.initState();
    _future = _loadUpcoming();
  }

  void _exitSearch() {
    setState(() {
      _query = '';
      _searchFieldGeneration++;
    });
  }

  Future<List<_UpcomingItem>> _loadUpcoming() async {
    final showIds = await widget.watchlistRepository.watchShowIds().first;
    final movieIds = await widget.watchlistRepository.watchMovieIds().first;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final items = <_UpcomingItem>[];

    final shows = (await Future.wait(
      showIds.map(
        (id) => fetchOrNull(() => widget.tmdbClient.getTvShowDetails(id)),
      ),
    )).whereType<TvShowDetails>();
    for (final show in shows) {
      final next = show.nextEpisodeToAir;
      if (next?.airDate == null) continue;
      if (next!.airDate!.isBefore(today)) continue;
      items.add(
        _UpcomingItem(
          tmdbId: show.id,
          mediaType: MediaType.tv,
          title: show.name,
          posterPath: show.posterPath,
          date: next.airDate!,
          subtitle:
              'S${next.seasonNumber.toString().padLeft(2, '0')}E${next.episodeNumber.toString().padLeft(2, '0')} - ${next.name}',
        ),
      );
    }

    final movies = (await Future.wait(
      movieIds.map(
        (id) => fetchOrNull(() => widget.tmdbClient.getMovieDetails(id)),
      ),
    )).whereType<MovieDetails>();
    for (final movie in movies) {
      if (movie.releaseDate == null) continue;
      if (movie.releaseDate!.isBefore(today)) continue;
      items.add(
        _UpcomingItem(
          tmdbId: movie.id,
          mediaType: MediaType.movie,
          title: movie.title,
          posterPath: movie.posterPath,
          date: movie.releaseDate!,
          subtitle: '__MOVIE_RELEASE__',
        ),
      );
    }

    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }

  String _formatDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = date.difference(today).inDays;
    if (diff == 0) return l10n.today;
    if (diff == 1) return l10n.tomorrow;
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final searching = _query.isNotEmpty;
    return PopScope(
      canPop: !searching,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && searching) _exitSearch();
      },
      child: Scaffold(
        endDrawer: AppDrawer(authService: widget.authService),
        appBar: AppBar(
          titleSpacing: 8,
          leading: searching
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _exitSearch,
                )
              : null,
          title: DebouncedSearchField(
            key: ValueKey(_searchFieldGeneration),
            onQueryChanged: (query) => setState(() => _query = query),
          ),
          actions: const [UpdateIndicatorButton(), AccountMenuButton()],
        ),
        body: searching
            ? SearchResultsList(
                query: _query,
                tmdbClient: widget.tmdbClient,
                watchlistRepository: widget.watchlistRepository,
                watchedRepository: widget.watchedRepository,
              )
            : FutureBuilder<List<_UpcomingItem>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(l10n.errorPrefix(snapshot.error.toString())),
                    );
                  }
                  final items = snapshot.data!;
                  if (items.isEmpty) {
                    return Center(child: Text(l10n.noUpcomingReleases));
                  }
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final subtitle = item.subtitle == '__MOVIE_RELEASE__'
                          ? l10n.movieRelease
                          : item.subtitle;
                      return PosterListTile(
                        posterPath: item.posterPath,
                        title: item.title,
                        subtitle:
                            '${_formatDate(context, item.date)} • $subtitle',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(
                              tmdbId: item.tmdbId,
                              mediaType: item.mediaType,
                              tmdbClient: widget.tmdbClient,
                              watchlistRepository: widget.watchlistRepository,
                              watchedRepository: widget.watchedRepository,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
```

The `subtitle: '__MOVIE_RELEASE__'` sentinel keeps `_UpcomingItem` (a plain data holder built in `_loadUpcoming`, which has no `BuildContext`) from needing a `BuildContext` just to resolve one translated string; the sentinel is swapped for `l10n.movieRelease` where it's actually rendered, in `build`, where a context is available. The episode-code subtitle (`'S03E04 - Episode 4'`) stays as-is — it's structured notation plus TMDB episode/show names, not natural-language UI text.

- [ ] **Step 2: Run analyze and the full suite**

Run: `flutter analyze`
Expected: `No issues found!` (this was the last consumer with the dangling `sign_out_button.dart` import from Task 8).

Run: `flutter test`
Expected: all tests green.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/calendar_screen.dart
git commit -m "Wire AppDrawer/AccountMenuButton into CalendarScreen; translate its strings"
```

---

## Task 11: Translate `detail_screen.dart`

**Files:**
- Modify: `lib/screens/detail_screen.dart`
- Modify: `test/screens/detail_screen_test.dart`

**Interfaces:**
- Consumes: `AppLocalizations.of(context)!.errorPrefix/.inWatchlist/.addToWatchlist/.watched/.markAsWatched/.watchedCount/.nextEpisode/.markWatched/.youAreCaughtUp/.nextEpisodeSubtitle/.caughtUpWithEverythingAired/.seasons/.episodeCount/.markSeasonWatched` (Task 1).

- [ ] **Step 1: Update `lib/screens/detail_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/firestore/watched_repository.dart';
import '../data/firestore/watchlist_repository.dart';
import '../data/models/episode.dart';
import '../data/models/movie_details.dart';
import '../data/models/search_result.dart';
import '../data/models/season_summary.dart';
import '../data/models/tv_show_details.dart';
import '../data/show_progress.dart';
import '../data/tmdb_client.dart';
import '../l10n/app_localizations.dart';
import '../widgets/caught_up_indicator.dart';
import 'season_episodes_screen.dart';

class DetailScreen extends StatefulWidget {
  final int tmdbId;
  final MediaType mediaType;
  final TmdbClient tmdbClient;
  final WatchlistRepository watchlistRepository;
  final WatchedRepository watchedRepository;

  const DetailScreen({
    super.key,
    required this.tmdbId,
    required this.mediaType,
    required this.tmdbClient,
    required this.watchlistRepository,
    required this.watchedRepository,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  TvShowDetails? _showDetails;
  MovieDetails? _movieDetails;
  bool _loading = true;
  Object? _error;
  bool _inWatchlist = false;
  bool _isWatched = false;
  ShowProgress? _progress;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (widget.mediaType == MediaType.tv) {
        final details = await widget.tmdbClient.getTvShowDetails(
          widget.tmdbId,
        );
        final inWatchlist = await widget.watchlistRepository
            .isShowInWatchlist(widget.tmdbId);
        if (!mounted) return;
        setState(() {
          _showDetails = details;
          _inWatchlist = inWatchlist;
          _loading = false;
        });
        await _refreshProgress();
      } else {
        final details = await widget.tmdbClient.getMovieDetails(
          widget.tmdbId,
        );
        final inWatchlist = await widget.watchlistRepository
            .isMovieInWatchlist(widget.tmdbId);
        final watched = await widget.watchedRepository.isMovieWatched(
          widget.tmdbId,
        );
        if (!mounted) return;
        setState(() {
          _movieDetails = details;
          _inWatchlist = inWatchlist;
          _isWatched = watched;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _toggleWatchlist() async {
    final adding = !_inWatchlist;
    setState(() => _inWatchlist = adding);
    try {
      if (widget.mediaType == MediaType.tv) {
        await (adding
            ? widget.watchlistRepository.addShow(widget.tmdbId)
            : widget.watchlistRepository.removeShow(widget.tmdbId));
      } else {
        await (adding
            ? widget.watchlistRepository.addMovie(widget.tmdbId)
            : widget.watchlistRepository.removeMovie(widget.tmdbId));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _inWatchlist = !adding);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorPrefix(e.toString()))),
      );
    }
  }

  Future<void> _toggleMovieWatched() async {
    final watching = !_isWatched;
    setState(() => _isWatched = watching);
    try {
      await (watching
          ? widget.watchedRepository.markMovieWatched(widget.tmdbId)
          : widget.watchedRepository.markMovieUnwatched(widget.tmdbId));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isWatched = !watching);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorPrefix(e.toString()))),
      );
    }
  }

  /// Recomputes watched/aired counts and the next episode to watch. Runs
  /// after the initial load and after marking the next episode watched.
  /// Best-effort: a failure here (e.g. one season's TMDB call failing)
  /// shouldn't block the rest of the detail screen from working.
  Future<void> _refreshProgress() async {
    final show = _showDetails;
    if (show == null) return;
    try {
      final progress = await computeShowProgress(
        tmdbClient: widget.tmdbClient,
        watchedRepository: widget.watchedRepository,
        show: show,
      );
      if (!mounted) return;
      setState(() => _progress = progress);
    } catch (_) {
      // Leave the previous (or null) progress in place.
    }
  }

  Future<void> _markNextEpisodeWatched(Episode episode) async {
    final id = WatchedEpisodeId(
      showId: widget.tmdbId,
      season: episode.seasonNumber,
      episode: episode.episodeNumber,
    );
    try {
      await widget.watchedRepository.markEpisodeWatched(id);
      await _refreshProgress();
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorPrefix(e.toString()))),
      );
    }
  }

  Future<void> _markSeasonWatchedFromSummary(SeasonSummary season) async {
    try {
      final episodes = await widget.tmdbClient.getSeasonEpisodes(
        widget.tmdbId,
        season.seasonNumber,
      );
      await widget.watchedRepository.markSeasonWatched(
        widget.tmdbId,
        season.seasonNumber,
        airedEpisodeNumbers(episodes),
      );
      await _refreshProgress();
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorPrefix(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: Center(child: Text(l10n.errorPrefix(_error.toString()))),
      );
    }

    // Exactly one of these is populated at this point (widget.mediaType
    // determines which, per _load()). Using `??` here would be wrong: a
    // real, legitimately-null field on the loaded entity (e.g. a show
    // with no poster on TMDB) must not fall through to the other
    // entity's (nonexistent) data.
    final isTv = widget.mediaType == MediaType.tv;
    final title = isTv ? _showDetails!.name : _movieDetails!.title;
    final overview = isTv ? _showDetails!.overview : _movieDetails!.overview;
    final posterPath = isTv
        ? _showDetails!.posterPath
        : _movieDetails!.posterPath;
    final showIsComplete =
        _showDetails != null &&
        (_progress?.isShowComplete(_showDetails!.seasons) ?? false);
    final showIsCaughtUpButOngoing =
        _showDetails != null &&
        (_progress?.isShowCaughtUpButOngoing(_showDetails!.seasons) ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
            if (showIsComplete) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: Colors.green),
            ] else if (showIsCaughtUpButOngoing) ...[
              const SizedBox(width: 8),
              const CaughtUpIndicator(),
            ],
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                height: 150,
                child: posterPath == null
                    ? const ColoredBox(color: Color(0xFFE0E0E0))
                    : Image.network(
                        'https://image.tmdb.org/t/p/w300$posterPath',
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FilledButton.icon(
                      onPressed: _toggleWatchlist,
                      icon: Icon(
                        _inWatchlist ? Icons.check : Icons.add,
                      ),
                      label: Text(
                        _inWatchlist ? l10n.inWatchlist : l10n.addToWatchlist,
                      ),
                    ),
                    if (widget.mediaType == MediaType.movie) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _toggleMovieWatched,
                        icon: Icon(
                          _isWatched
                              ? Icons.visibility
                              : Icons.visibility_outlined,
                        ),
                        label: Text(
                          _isWatched ? l10n.watched : l10n.markAsWatched,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(overview),
          if (_showDetails != null) ...[
            const SizedBox(height: 16),
            if (_progress case final progress?) ...[
              Text(
                l10n.watchedCount(progress.watchedCount, progress.airedCount),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (progress.nextToWatch case final next?)
                Card(
                  child: ListTile(
                    title: Text(l10n.nextEpisode),
                    subtitle: Text(
                      'S${next.seasonNumber.toString().padLeft(2, '0')}'
                      'E${next.episodeNumber.toString().padLeft(2, '0')} - ${next.name}'
                      '${next.airDate == null ? '' : ' (${DateFormat('yyyy-MM-dd').format(next.airDate!)})'}',
                    ),
                    trailing: FilledButton(
                      onPressed: () => _markNextEpisodeWatched(next),
                      child: Text(l10n.markWatched),
                    ),
                  ),
                )
              else if (_showDetails!.nextEpisodeToAir case final upcoming?)
                Card(
                  child: ListTile(
                    title: Text(l10n.youAreCaughtUp),
                    subtitle: Text(
                      l10n.nextEpisodeSubtitle(
                        'S${upcoming.seasonNumber.toString().padLeft(2, '0')}'
                        'E${upcoming.episodeNumber.toString().padLeft(2, '0')} - ${upcoming.name}'
                        '${upcoming.airDate == null ? '' : ' (${DateFormat('yyyy-MM-dd').format(upcoming.airDate!)})'}',
                      ),
                    ),
                  ),
                )
              else
                Text(l10n.caughtUpWithEverythingAired),
            ],
            const SizedBox(height: 16),
            Text(
              l10n.seasons,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ..._showDetails!.seasons.map((season) {
              final watchedInSeason =
                  _progress?.watchedCountBySeason[season.seasonNumber];
              final subtitle = watchedInSeason == null
                  ? l10n.episodeCount(season.episodeCount)
                  : l10n.watchedCount(watchedInSeason, season.episodeCount);
              final isComplete =
                  _progress?.isSeasonComplete(
                    season.seasonNumber,
                    season.episodeCount,
                  ) ??
                  false;
              final isCaughtUpButOngoing =
                  _progress?.isSeasonCaughtUpButOngoing(
                    season.seasonNumber,
                    season.episodeCount,
                  ) ??
                  false;
              return ListTile(
                leading: isComplete
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : isCaughtUpButOngoing
                    ? const CaughtUpIndicator()
                    : null,
                title: Text(season.name),
                subtitle: Text(subtitle),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.playlist_add_check),
                      tooltip: l10n.markSeasonWatched,
                      onPressed: () => _markSeasonWatchedFromSummary(season),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SeasonEpisodesScreen(
                        showId: widget.tmdbId,
                        showName: _showDetails!.name,
                        seasonNumber: season.seasonNumber,
                        tmdbClient: widget.tmdbClient,
                        watchedRepository: widget.watchedRepository,
                      ),
                    ),
                  );
                  // The user may have marked episodes watched/rewatched
                  // inside the season screen; refresh counts on return.
                  await _refreshProgress();
                },
              );
            }),
          ],
        ],
      ),
    );
  }
}
```

Note: the `next`/`upcoming` subtitle strings (`'S03E04 - Episode 4 (2026-07-19)'`) are structured episode notation plus TMDB names/dates, not natural-language text — they stay as raw Dart string interpolation, same as the calendar screen's episode subtitle in Task 10. Only the surrounding sentence (`l10n.nextEpisodeSubtitle('...')` for the "you're caught up but here's what's coming" card, and the literal card titles `l10n.nextEpisode`/`l10n.youAreCaughtUp`) are localized. The `progress.nextToWatch` branch's card title uses `l10n.nextEpisode` directly (its subtitle is pure episode notation, no "Prossimo episodio:" prefix in the original code) — only the second (`upcoming`) branch had that prefix, which is why only it uses `nextEpisodeSubtitle`.

- [ ] **Step 2: Update `test/screens/detail_screen_test.dart`**

Add the import, replace the three `MaterialApp(` calls with `localizedTestApp(` (unchanged `home: DetailScreen(...)` argument in each), and update the string assertions to match the new Italian ARB values (the values are identical to what was hardcoded before, so the *values* in the three affected `expect`s don't change — only the wrapper needs updating):

```dart
import 'dart:async';
import 'dart:convert';

import 'package:episodes_tracker/data/firestore/watched_repository.dart';
import 'package:episodes_tracker/data/firestore/watchlist_repository.dart';
import 'package:episodes_tracker/data/models/search_result.dart';
import 'package:episodes_tracker/data/tmdb_client.dart';
import 'package:episodes_tracker/screens/detail_screen.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

import '../support/localized_test_app.dart';

class MockWatchlistRepository extends Mock implements WatchlistRepository {}

void main() {
  testWidgets(
    'does not call setState after the widget is disposed mid-load',
    (tester) async {
      final completer = Completer<http.Response>();
      final mockClient = MockClient((request) => completer.future);
      final tmdbClient = TmdbClient(
        httpClient: mockClient,
        readAccessToken: 'test-token',
      );
      final firestore = FakeFirebaseFirestore();
      final watchlistRepository = WatchlistRepository(
        firestore: firestore,
        uid: 'user-1',
      );
      final watchedRepository = WatchedRepository(
        firestore: firestore,
        uid: 'user-1',
      );

      await tester.pumpWidget(
        localizedTestApp(
          home: DetailScreen(
            tmdbId: 1399,
            mediaType: MediaType.tv,
            tmdbClient: tmdbClient,
            watchlistRepository: watchlistRepository,
            watchedRepository: watchedRepository,
          ),
        ),
      );

      // Simulate the user navigating away before the TMDB call resolves:
      // replace the whole widget tree, disposing DetailScreen.
      await tester.pumpWidget(const SizedBox());

      // Now the in-flight HTTP call fails (or succeeds) after disposal.
      completer.completeError(Exception('network error'));
      await tester.pump();

      // Before the fix, this throws "setState() called after dispose()".
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reverts the optimistic watchlist toggle and shows an error when the write fails',
    (tester) async {
      final mockClient = MockClient(
        (request) async => http.Response(
          jsonEncode({
            'id': 550,
            'title': 'Fight Club',
            'overview': 'An insomniac office worker...',
            'poster_path': null,
            'backdrop_path': null,
            'release_date': '1999-10-15',
            'runtime': 139,
            'status': 'Released',
          }),
          200,
        ),
      );
      final tmdbClient = TmdbClient(
        httpClient: mockClient,
        readAccessToken: 'test-token',
      );
      final watchlistRepository = MockWatchlistRepository();
      when(
        () => watchlistRepository.isMovieInWatchlist(550),
      ).thenAnswer((_) async => false);
      when(
        () => watchlistRepository.addMovie(550),
      ).thenThrow(Exception('offline'));
      final watchedRepository = WatchedRepository(
        firestore: FakeFirebaseFirestore(),
        uid: 'user-1',
      );

      await tester.pumpWidget(
        localizedTestApp(
          home: DetailScreen(
            tmdbId: 550,
            mediaType: MediaType.movie,
            tmdbClient: tmdbClient,
            watchlistRepository: watchlistRepository,
            watchedRepository: watchedRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aggiungi a watchlist'), findsOneWidget);

      await tester.tap(find.text('Aggiungi a watchlist'));
      await tester.pumpAndSettle();

      // The optimistic flip to "Nella watchlist" is reverted once the
      // write fails, and the failure is surfaced instead of silently
      // leaving the UI stuck on the wrong (never-persisted) state.
      expect(find.text('Aggiungi a watchlist'), findsOneWidget);
      expect(find.text('Nella watchlist'), findsNothing);
      expect(find.textContaining('Errore'), findsOneWidget);
    },
  );

  testWidgets(
    'shows the upcoming episode when caught up but TMDB has one scheduled',
    (tester) async {
      final mockClient = MockClient(
        (request) async => http.Response(
          jsonEncode({
            'id': 94997,
            'name': 'House of the Dragon',
            'overview': 'Targaryen civil war.',
            'poster_path': null,
            'backdrop_path': null,
            'number_of_seasons': 0,
            'number_of_episodes': 0,
            'status': 'Returning Series',
            // No aired-but-unwatched episode (no seasons listed at all
            // here, so computeShowProgress's nextToWatch is null), but
            // TMDB still reports a scheduled next episode.
            'next_episode_to_air': {
              'id': 7196567,
              'name': 'Episode 4',
              'overview': '',
              'air_date': '2026-07-19',
              'episode_number': 4,
              'season_number': 3,
            },
            'last_episode_to_air': null,
            'seasons': [],
          }),
          200,
        ),
      );
      final tmdbClient = TmdbClient(
        httpClient: mockClient,
        readAccessToken: 'test-token',
      );
      final watchlistRepository = MockWatchlistRepository();
      when(
        () => watchlistRepository.isShowInWatchlist(94997),
      ).thenAnswer((_) async => false);
      final watchedRepository = WatchedRepository(
        firestore: FakeFirebaseFirestore(),
        uid: 'user-1',
      );

      await tester.pumpWidget(
        localizedTestApp(
          home: DetailScreen(
            tmdbId: 94997,
            mediaType: MediaType.tv,
            tmdbClient: tmdbClient,
            watchlistRepository: watchlistRepository,
            watchedRepository: watchedRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sei aggiornato'), findsOneWidget);
      expect(
        find.text('Prossimo episodio: S03E04 - Episode 4 (2026-07-19)'),
        findsOneWidget,
      );
      expect(
        find.text('Sei aggiornato con tutti gli episodi usciti'),
        findsNothing,
      );
    },
  );
}
```

- [ ] **Step 3: Run tests**

Run: `flutter test test/screens/detail_screen_test.dart`
Expected: `00:0X +3: All tests passed!`

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/screens/detail_screen.dart test/screens/detail_screen_test.dart
git commit -m "Translate DetailScreen"
```

---

## Task 12: Translate `season_episodes_screen.dart`

**Files:**
- Modify: `lib/screens/season_episodes_screen.dart`

**Interfaces:**
- Consumes: `AppLocalizations.of(context)!.errorPrefix/.seasonAppBarTitle/.markSeasonWatched/.rewatched/.unknownAirDate/.notYetAiredDate` (Task 1).

`SeasonEpisodesScreen` has no existing test (confirmed in the earlier file survey); verified via `flutter analyze` + full suite staying green + manual on-device check, consistent with Tasks 9-10.

- [ ] **Step 1: Update `lib/screens/season_episodes_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/firestore/watched_repository.dart';
import '../data/models/episode.dart';
import '../data/show_progress.dart';
import '../data/tmdb_client.dart';
import '../l10n/app_localizations.dart';

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
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorPrefix(e.toString()))),
      );
    }
  }

  Future<void> _toggleRewatched(WatchedEpisodeId id, bool rewatched) async {
    try {
      await widget.watchedRepository.setEpisodeRewatched(id, rewatched);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorPrefix(e.toString()))),
      );
    }
  }

  Future<void> _markSeasonWatched() async {
    final episodes = _loadedEpisodes;
    if (episodes == null) return;
    try {
      await widget.watchedRepository.markSeasonWatched(
        widget.showId,
        widget.seasonNumber,
        airedEpisodeNumbers(episodes),
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorPrefix(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.seasonAppBarTitle(widget.showName, widget.seasonNumber)),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add_check),
            tooltip: l10n.markSeasonWatched,
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
            return Center(
              child: Text(l10n.errorPrefix(snapshot.error.toString())),
            );
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
                  final aired = hasAired(episode);
                  return CheckboxListTile(
                    value: isWatched,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text('${episode.episodeNumber}. ${episode.name}'),
                    subtitle: Text(
                      episode.airDate == null
                          ? l10n.unknownAirDate
                          : aired
                          ? DateFormat('yyyy-MM-dd').format(episode.airDate!)
                          : l10n.notYetAiredDate(
                              DateFormat('yyyy-MM-dd').format(episode.airDate!),
                            ),
                    ),
                    secondary: IconButton(
                      icon: Icon(
                        Icons.replay_circle_filled,
                        color: isRewatched
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      tooltip: l10n.rewatched,
                      onPressed: isWatched
                          ? () => _toggleRewatched(id, !isRewatched)
                          : null,
                    ),
                    onChanged: aired
                        ? (checked) => _toggleWatched(id, checked == true)
                        : null,
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
```

- [ ] **Step 2: Run analyze and the full suite**

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: all tests green.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/season_episodes_screen.dart
git commit -m "Translate SeasonEpisodesScreen"
```

---

## Task 13: Final sweep — verify no hardcoded strings remain

**Files:**
- None expected (verification-only); fix inline if the grep below finds anything.

**Interfaces:** none (this task consumes nothing new and produces no new interface — it's a completeness check over every task above).

- [ ] **Step 1: Grep for leftover hardcoded Italian UI strings**

Run:
```bash
grep -rnE "Text\('[A-ZÀ-ÖØ-Þ]" lib/ --include=*.dart
```
Expected: no matches other than the two intentionally-hardcoded literals — `'Episodes Tracker'` (brand name, in `login_screen.dart`) and `'Italiano / English'` (language names, in `app_drawer.dart`), and `'Watchlist'` (identical word in both languages, in `home_shell.dart`). If anything else turns up, add the missing ARB key(s) to both `lib/l10n/app_en.arb` and `lib/l10n/app_it.arb` and wire it in, following the same pattern as the rest of this plan.

- [ ] **Step 2: Confirm `sign_out_button.dart` has no leftover references**

Run:
```bash
grep -rn "sign_out_button\|SignOutButton" lib/ test/
```
Expected: no matches (deleted in Task 8, last two consumers updated in Tasks 9-10).

- [ ] **Step 3: Full verification pass**

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: all tests green (baseline before this plan was 108; this plan adds `locale_controller_test.dart` (6), `login_screen_test.dart` (2), `app_drawer_test.dart` (4) = 120 total, assuming no other test files were added).

- [ ] **Step 4: Manual on-device check**

Per the project's established workflow, build and install the debug APK on the connected device and hand off to the user for visual verification — do not attempt to verify the UI via screenshots:

```bash
flutter build apk --debug --dart-define-from-file=.env
```

Then install with `adb install -r` on the connected device (serial `3B15A600T7L00000`) and report to the user what to check: the account icon opens the drawer with account info/GitHub link/language switch/logout, toggling the switch changes every screen's language live, the search bar has rounded corners with less gap to the action icons, and English is used by default (unless the device's own language is Italian).

- [ ] **Step 5: Commit (only if Step 1 found and fixed something)**

```bash
git add -A
git commit -m "Fill in ARB keys missed by earlier tasks (final localization sweep)"
```
