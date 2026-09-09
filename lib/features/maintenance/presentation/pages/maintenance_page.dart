import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../l10n/l10n_extensions.dart';
import '../../../../shared/widgets/states/empty_state_view.dart';

/// Pestaña de entrada de la app (D4): agenda e historial de mantenimiento.
///
/// Placeholder de F3 — el contenido real llega en F6.
class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: EmptyStateView(
          icon: LucideIcons.wrench,
          title: context.l10n.maintenance_empty_title,
          body: context.l10n.maintenance_empty_body,
        ),
      ),
    );
  }
}
