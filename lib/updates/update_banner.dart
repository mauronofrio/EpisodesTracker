import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'update_checker.dart';

/// Wraps [child] and, once on startup, checks GitHub Releases for a newer
/// version. Renders no UI of its own — it exposes the result to descendants
/// via [UpdateBanner.of], so a small icon (e.g. [UpdateIndicatorButton]) can
/// be placed wherever makes sense (next to sign-out, in an AppBar) instead
/// of this widget imposing its own banner/overlay on every screen.
class UpdateBanner extends StatefulWidget {
  final UpdateChecker updateChecker;
  final Widget child;

  const UpdateBanner({
    super.key,
    required this.updateChecker,
    required this.child,
  });

  /// The available newer release, or null if none is available (or the
  /// check hasn't completed yet).
  static ReleaseInfo? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_UpdateScope>()
        ?.release;
  }

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner> {
  ReleaseInfo? _newerRelease;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      final release = await widget.updateChecker.fetchLatestRelease();
      if (release == null) return;
      final currentInfo = await PackageInfo.fromPlatform();
      if (!UpdateChecker.isNewer(
        currentVersion: currentInfo.version,
        latestTag: release.tagName,
      )) {
        return;
      }
      if (mounted) setState(() => _newerRelease = release);
    } catch (_) {
      // Update checks are best-effort; a failure here must never block
      // the app from being usable.
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UpdateScope(release: _newerRelease, child: widget.child);
  }
}

class _UpdateScope extends InheritedWidget {
  final ReleaseInfo? release;

  const _UpdateScope({required this.release, required super.child});

  @override
  bool updateShouldNotify(_UpdateScope oldWidget) =>
      oldWidget.release != release;
}
