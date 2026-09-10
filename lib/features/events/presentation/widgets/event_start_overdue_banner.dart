import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_banner.dart';
import '../../../../l10n/l10n_extensions.dart';

/// EV7: banner que ve el organizador cuando `start_at` ya pasó y la
/// rodada sigue `published`.
class EventStartOverdueBanner extends StatelessWidget {
  const EventStartOverdueBanner({required this.startAt, super.key});

  final DateTime startAt;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.jm('es').format(startAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppBanner(
        icon: LucideIcons.alarmClock,
        title: context.l10n.events_detail_start_overdue_title(time),
        body: context.l10n.events_detail_start_overdue_body,
      ),
    );
  }
}
