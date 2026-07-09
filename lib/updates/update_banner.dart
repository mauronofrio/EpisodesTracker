import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'update_checker.dart';

/// Wraps [child] and, once on startup, checks GitHub Releases for a newer
/// version. As soon as one is found it immediately opens [showUpdateDialog]
/// once, then exposes the release to descendants via [UpdateBanner.of] so a
/// small icon (e.g. UpdateIndicatorButton) can reopen the same dialog later
/// — this widget otherwise renders no persistent UI of its own.
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
      if (!mounted) return;
      setState(() => _newerRelease = release);
      // Wait for this frame to finish building before opening the dialog -
      // showDialog needs a Navigator already present in the tree.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showUpdateDialog(context, release);
      });
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

/// Opens a small centered dialog (not a full page/route) with the release
/// version and a download link. Shared by the automatic startup prompt
/// above and [UpdateIndicatorButton]'s manual reopen, so both look and
/// behave identically.
void showUpdateDialog(BuildContext context, ReleaseInfo release) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Nuova versione disponibile'),
      content: Text('È disponibile la versione ${release.tagName}.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Chiudi'),
        ),
        if (release.apkDownloadUrl != null)
          FilledButton(
            onPressed: () => launchUrl(
              Uri.parse(release.apkDownloadUrl!),
              mode: LaunchMode.externalApplication,
            ),
            child: const Text('Scarica'),
          ),
      ],
    ),
  );
}
