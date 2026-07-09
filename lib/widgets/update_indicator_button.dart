import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../updates/update_banner.dart';
import '../updates/update_checker.dart';

/// An AppBar action that only renders when [UpdateBanner] has found a newer
/// release; tapping it opens a small centered dialog (not a full page/route)
/// with the version and a download link, so it can be triggered the same
/// way from any screen that includes this button.
class UpdateIndicatorButton extends StatelessWidget {
  const UpdateIndicatorButton({super.key});

  @override
  Widget build(BuildContext context) {
    final release = UpdateBanner.of(context);
    if (release == null) return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.system_update_outlined),
      tooltip: 'Nuova versione disponibile: ${release.tagName}',
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => _UpdateDialog(release: release),
      ),
    );
  }
}

class _UpdateDialog extends StatelessWidget {
  final ReleaseInfo release;

  const _UpdateDialog({required this.release});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
    );
  }
}
