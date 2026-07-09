import 'package:flutter/material.dart';

import '../auth/auth_service.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Accesso non riuscito: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('EpisodesTracker', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 32),
            if (_isSigningIn)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _handleSignIn,
                child: const Text('Accedi con Google'),
              ),
          ],
        ),
      ),
    );
  }
}
