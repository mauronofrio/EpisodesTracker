import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../data/firestore/watched_repository.dart';
import '../data/firestore/watchlist_repository.dart';
import '../data/tmdb_client.dart';
import '../l10n/app_localizations.dart';
import '../widgets/app_drawer.dart';
import '../widgets/home_drawer_scope.dart';
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
  final _scaffoldKey = GlobalKey<ScaffoldState>();

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

    // The account drawer lives on this single outer Scaffold (not on each
    // tab's own nested Scaffold) so it renders full-height and covers the
    // bottom navigation bar below, instead of being clipped to a tab's body.
    return HomeDrawerScope(
      openDrawer: () => _scaffoldKey.currentState?.openEndDrawer(),
      child: Scaffold(
        key: _scaffoldKey,
        endDrawer: AppDrawer(authService: widget.authService),
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
      ),
    );
  }
}
