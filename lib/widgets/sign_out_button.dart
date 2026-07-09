import 'package:flutter/material.dart';

import '../auth/auth_service.dart';

/// An AppBar action that confirms, then calls [AuthService.signOut]. Shared
/// by every top-level tab screen so sign-out is reachable from anywhere in
/// the app.
class SignOutButton extends StatelessWidget {
  final AuthService authService;

  const SignOutButton({super.key, required this.authService});

  Future<void> _confirmAndSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Esci'),
        content: const Text('Vuoi disconnetterti da questo account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Esci'),
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
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Esci',
      onPressed: () => _confirmAndSignOut(context),
    );
  }
}
