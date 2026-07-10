import 'package:flutter/material.dart';

/// Exposes a way to open [HomeShell]'s single `endDrawer` from anywhere
/// inside its two tabs (WatchlistScreen, CalendarScreen). Each tab has its
/// own nested Scaffold (for its own AppBar), so a plain
/// `Scaffold.of(context).openEndDrawer()` called from within one of them
/// would open that tab's own (drawer-less) Scaffold instead of HomeShell's -
/// this ambient scope lets [AccountMenuButton] reach the right one.
class HomeDrawerScope extends InheritedWidget {
  final VoidCallback openDrawer;

  const HomeDrawerScope({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  static VoidCallback of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<HomeDrawerScope>();
    assert(scope != null, 'No HomeDrawerScope found in context');
    return scope!.openDrawer;
  }

  @override
  bool updateShouldNotify(HomeDrawerScope oldWidget) =>
      oldWidget.openDrawer != openDrawer;
}
