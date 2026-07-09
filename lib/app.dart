import 'package:flutter/material.dart';

import 'auth/auth_service.dart';
import 'screens/home_placeholder_screen.dart';
import 'screens/login_screen.dart';

class EpisodesTrackerApp extends StatelessWidget {
  final AuthService authService;

  const EpisodesTrackerApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EpisodesTracker',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
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
          return HomePlaceholderScreen(authService: authService, user: user);
        },
      ),
    );
  }
}
