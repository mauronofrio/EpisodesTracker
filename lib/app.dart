import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'auth/auth_service.dart';
import 'config/env.dart';
import 'data/firestore/watched_repository.dart';
import 'data/firestore/watchlist_repository.dart';
import 'data/tmdb_client.dart';
import 'notifications/notification_service.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';

class EpisodesTrackerApp extends StatefulWidget {
  final AuthService authService;
  final NotificationService notificationService;

  const EpisodesTrackerApp({
    super.key,
    required this.authService,
    required this.notificationService,
  });

  @override
  State<EpisodesTrackerApp> createState() => _EpisodesTrackerAppState();
}

class _EpisodesTrackerAppState extends State<EpisodesTrackerApp> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;

  @override
  void initState() {
    super.initState();
    _foregroundMessageSubscription = widget.notificationService
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EpisodesTracker',
      scaffoldMessengerKey: _scaffoldMessengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: StreamBuilder(
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

          final tmdbClient = TmdbClient(
            httpClient: http.Client(),
            readAccessToken: Env.tmdbReadAccessToken,
          );
          final firestore = FirebaseFirestore.instance;
          return HomeShell(
            authService: widget.authService,
            tmdbClient: tmdbClient,
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
    );
  }
}
