import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../l10n/l10n_extensions.dart';
import '../../../../shared/widgets/states/empty_state_view.dart';

/// Lista de rodadas. Placeholder de F3 — el contenido real llega en F7.
class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: EmptyStateView(
          icon: LucideIcons.calendarDays,
          title: context.l10n.events_empty_title,
          body: context.l10n.events_empty_body,
        ),
      ),
    );
  }
}
