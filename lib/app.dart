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
