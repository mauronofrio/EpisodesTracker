import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'update_checker.dart';

/// Wraps [child] and, once on startup, checks GitHub Releases for a newer
/// version; if found, shows a dismissible top banner linking to the APK.
class UpdateBanner extends StatefulWidget {
  final UpdateChecker updateChecker;
  final Widget child;

  const UpdateBanner({
    super.key,
    required this.updateChecker,
    required this.child,
  });

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner> {
  ReleaseInfo? _newerRelease;
  bool _bannerDismissed = false;

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
    final release = _newerRelease;
    if (release == null) return widget.child;

    // Dismissing the banner only hides it for the rest of this session —
    // it must not forget the update exists, or there'd be no way back to
    // it short of restarting the app. Instead, replace the banner with a
    // small persistent icon that reopens it.
    if (_bannerDismissed) {
      return Stack(
        children: [
          widget.child,
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: Material(
              color: Theme.of(context).colorScheme.primary,
              shape: const CircleBorder(),
              elevation: 2,
              child: IconButton(
                icon: const Icon(Icons.system_update),
                color: Theme.of(context).colorScheme.onPrimary,
                tooltip: 'Nuova versione disponibile: ${release.tagName}',
                onPressed: () => setState(() => _bannerDismissed = false),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        MaterialBanner(
          content: Text('Nuova versione disponibile: ${release.tagName}'),
          actions: [
            TextButton(
              onPressed: () => setState(() => _bannerDismissed = true),
              child: const Text('Più tardi'),
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
        Expanded(child: widget.child),
      ],
    );
  }
}
