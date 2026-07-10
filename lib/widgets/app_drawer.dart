// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/auth_service.dart';
import '../config/locale_controller.dart';
import '../l10n/app_localizations.dart';
import 'home_drawer_scope.dart';

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
                // Swallows load failures (e.g. offline, broken URL, or the
                // network-blocked test environment) instead of letting them
                // surface as an uncaught FlutterError.
                onBackgroundImageError: user?.photoURL != null
                    ? (_, _) {}
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

/// AppBar action that opens [AppDrawer] (registered as HomeShell's single
/// `endDrawer`, reached via [HomeDrawerScope] rather than
/// `Scaffold.of(context)` since this button lives inside a tab's own
/// nested Scaffold, not HomeShell's). Shows the signed-in account's Google
/// profile photo when available, falling back to a generic account icon.
class AccountMenuButton extends StatelessWidget {
  final AuthService authService;

  const AccountMenuButton({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final photoURL = authService.currentUser?.photoURL;
    return IconButton(
      icon: photoURL == null
          ? const Icon(Icons.account_circle, size: 30)
          : CircleAvatar(
              radius: 15,
              backgroundImage: NetworkImage(photoURL),
              onBackgroundImageError: (_, _) {},
            ),
      tooltip: l10n.account,
      onPressed: HomeDrawerScope.of(context),
    );
  }
}
