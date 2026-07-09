import 'package:flutter/material.dart';

import '../updates/update_banner.dart';

/// An AppBar action that only renders when [UpdateBanner] has found a newer
/// release. [UpdateBanner] already opens the update dialog automatically
/// once, on startup; this button lets the user reopen the same dialog later
/// after closing it, from any screen that includes this button.
class UpdateIndicatorButton extends StatelessWidget {
  const UpdateIndicatorButton({super.key});

  @override
  Widget build(BuildContext context) {
    final release = UpdateBanner.of(context);
    if (release == null) return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.system_update_outlined),
      tooltip: 'Nuova versione disponibile: ${release.tagName}',
      onPressed: () => showUpdateDialog(context, release),
    );
  }
}
