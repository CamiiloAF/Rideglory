import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../l10n/l10n_extensions.dart';
import '../../../../shared/widgets/states/empty_state_view.dart';

/// Galería del garaje. Placeholder de F3 — el contenido real llega en F5.
class GaragePage extends StatelessWidget {
  const GaragePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: EmptyStateView(
          icon: LucideIcons.bike,
          title: context.l10n.garage_empty_title,
          body: context.l10n.garage_empty_body,
        ),
      ),
    );
  }
}
