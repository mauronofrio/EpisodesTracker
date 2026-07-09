import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'auth/auth_service.dart';
import 'config/env.dart';
import 'data/firestore/watched_repository.dart';
import 'data/firestore/watchlist_repository.dart';
import 'data/tmdb_client.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';

class EpisodesTrackerApp extends StatelessWidget {
  final AuthService authService;

  const EpisodesTrackerApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EpisodesTracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: StreamBuilder(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final user = snapshot.data;
          if (user == null) {
            return LoginScreen(authService: authService);
          }

          final tmdbClient = TmdbClient(
            httpClient: http.Client(),
            readAccessToken: Env.tmdbReadAccessToken,
          );
          final firestore = FirebaseFirestore.instance;
          return HomeShell(
            authService: authService,
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
