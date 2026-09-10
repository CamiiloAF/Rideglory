import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/domain/result_state.dart';
import '../../../../core/utils/spanish_date_format.dart';
import '../../../../core/utils/thousands_input_formatter.dart';
import '../../../../design_system/components/app_banner.dart';
import '../../../../design_system/components/app_outlined_card.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/maintenance_detail_state.dart';
import '../widgets/maintenance_average_note.dart';
import '../widgets/maintenance_data_row.dart';
import '../widgets/maintenance_previous_row.dart';
import '../widgets/maintenance_reminder_row.dart';
import '../widgets/maintenance_section_title.dart';
import '../widgets/maintenance_see_more_row.dart';
import '../widgets/maintenance_ticket.dart';

/// Cuerpo del detalle: tiquete, datos, recordatorio y anteriores.
class MaintenanceDetailContent extends StatelessWidget {
  const MaintenanceDetailContent({
    required this.state,
    required this.onTogglePrevious,
    required this.onEditReminder,
    super.key,
  });

  final MaintenanceDetailState state;
  final VoidCallback onTogglePrevious;
  final VoidCallback onEditReminder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maintenance = state.maintenance;
    final dataRows = <Widget>[
      if (maintenance.workshop?.trim().isNotEmpty == true)
        MaintenanceDataRow(
          icon: LucideIcons.store,
          label: l10n.maintenance_detail_field_workshop,
          value: maintenance.workshop!,
        ),
      if (maintenance.cost != null)
        MaintenanceDataRow(
          icon: LucideIcons.banknote,
          label: l10n.maintenance_detail_field_cost,
          value: ThousandsInputFormatter.formatCurrency(maintenance.cost!),
        ),
      if (maintenance.notes?.trim().isNotEmpty == true)
        MaintenanceDataRow(
          icon: LucideIcons.stickyNote,
          label: l10n.maintenance_detail_field_note,
          value: maintenance.notes!,
        ),
    ];

    final averageKm = state.averageDurationKm;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
      children: [
        if (state.reminderUpdate is Error<Unit>) ...[
          AppBanner(
            title: l10n.maintenance_reminder_update_error_title,
            body: l10n.maintenance_reminder_update_error_body,
          ),
          const SizedBox(height: 14),
        ],
        MaintenanceTicket(
          odometerLabel: l10n.maintenance_value_km(
            ThousandsInputFormatter.format(maintenance.odometer) ??
                '${maintenance.odometer}',
          ),
          subtitle:
              '${maintenance.vehicleDisplayName} · ${SpanishDateFormat.long(maintenance.serviceDate)}',
        ),
        if (dataRows.isNotEmpty) ...[
          const SizedBox(height: 10),
          AppOutlinedCard(children: dataRows),
        ],
        if (maintenance.hasReminder) ...[
          const SizedBox(height: 14),
          MaintenanceSectionTitle(l10n.maintenance_section_reminder),
          const SizedBox(height: 6),
          MaintenanceReminderRow(
            label: maintenance.nextOdometer != null
                ? l10n.maintenance_detail_reminder_next_km(
                    ThousandsInputFormatter.format(maintenance.nextOdometer) ??
                        '${maintenance.nextOdometer}',
                  )
                : l10n.maintenance_detail_reminder_next_date(
                    SpanishDateFormat.short(maintenance.nextDate!),
                  ),
            subtitle:
                maintenance.nextOdometer != null && maintenance.nextDate != null
                ? l10n.maintenance_detail_reminder_next_date(
                    SpanishDateFormat.short(maintenance.nextDate!),
                  )
                : '',
            switchValue: true,
            showChevron: true,
            onTap: onEditReminder,
          ),
        ],
        if (state.previousEntries.isNotEmpty) ...[
          const SizedBox(height: 14),
          MaintenanceSectionTitle(l10n.maintenance_detail_previous_section),
          const SizedBox(height: 6),
          AppOutlinedCard(
            children: [
              for (final entry in state.visiblePreviousEntries)
                MaintenancePreviousRow(
                  odometerLabel: l10n.maintenance_value_km(
                    ThousandsInputFormatter.format(
                          entry.maintenance.odometer,
                        ) ??
                        '${entry.maintenance.odometer}',
                  ),
                  dateLabel: SpanishDateFormat.short(
                    entry.maintenance.serviceDate,
                  ),
                  durationLabel: entry.durationKm != null
                      ? l10n.maintenance_detail_duration(
                          ThousandsInputFormatter.format(entry.durationKm) ??
                              '${entry.durationKm}',
                        )
                      : null,
                ),
              if (state.hasMorePrevious)
                MaintenanceSeeMoreRow(
                  label: state.showAllPrevious
                      ? l10n.maintenance_detail_see_less
                      : l10n.maintenance_detail_see_more(
                          state.hiddenPreviousCount,
                        ),
                  expanded: state.showAllPrevious,
                  onTap: onTogglePrevious,
                ),
            ],
          ),
          if (averageKm != null)
            MaintenanceAverageNote(
              text: l10n.maintenance_detail_average(
                ThousandsInputFormatter.format(averageKm) ?? '$averageKm',
              ),
            ),
        ],
      ],
    );
  }
}
