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
