import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../l10n/l10n_extensions.dart';
import '../../../../shared/widgets/states/empty_state_view.dart';

/// Perfil del rider. Placeholder de F3 — el contenido real llega en F4.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: EmptyStateView(
          icon: LucideIcons.user,
          title: context.l10n.profile_empty_title,
          body: context.l10n.profile_empty_body,
        ),
      ),
    );
  }
}
