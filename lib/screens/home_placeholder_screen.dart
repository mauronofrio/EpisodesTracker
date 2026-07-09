import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/auth_service.dart';

/// Temporary landing screen shown after sign-in, until the real
/// watchlist/calendar navigation (Tasks 5-8) replaces it.
class HomePlaceholderScreen extends StatelessWidget {
  final AuthService authService;
  final User user;

  const HomePlaceholderScreen({
    super.key,
    required this.authService,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EpisodesTracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: authService.signOut,
          ),
        ],
      ),
      body: Center(
        child: Text('Bentornato, ${user.displayName ?? user.email}'),
      ),
    );
  }
}
