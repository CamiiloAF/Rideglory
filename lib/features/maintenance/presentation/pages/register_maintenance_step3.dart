import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/utils/spanish_date_format.dart';
import '../../../../core/utils/thousands_input_formatter.dart';
import '../../../../design_system/components/app_text_field.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/maintenance_reminder.dart';
import '../cubit/register_maintenance_cubit.dart';
import '../cubit/register_maintenance_state.dart';
import '../widgets/maintenance_interval_sheet.dart';
import '../widgets/maintenance_reminder_row.dart';
import '../widgets/maintenance_reminder_summary.dart';
import '../widgets/maintenance_section_title.dart';

/// Paso 3: detalles opcionales y recordatorio del próximo servicio
/// (Pencil `g3rONd` / `B8OGu`).
class RegisterMaintenanceStep3 extends StatefulWidget {
  const RegisterMaintenanceStep3({
    required this.state,
    required this.cubit,
    super.key,
  });

  final RegisterMaintenanceState state;
  final RegisterMaintenanceCubit cubit;

  @override
  State<RegisterMaintenanceStep3> createState() =>
      _RegisterMaintenanceStep3State();
}

class _RegisterMaintenanceStep3State extends State<RegisterMaintenanceStep3> {
  late final TextEditingController _workshopController;
  late final TextEditingController _costController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _workshopController = TextEditingController(
      text: widget.state.workshop ?? '',
    );
    _costController = TextEditingController(
      text: ThousandsInputFormatter.format(widget.state.cost) ?? '',
    );
    _notesController = TextEditingController(text: widget.state.notes ?? '');
  }

  @override
  void dispose() {
    _workshopController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = context.l10n;
    final reminder = widget.state.reminder;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.maintenance_register_step3_question,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.maintenance_register_step3_subtitle,
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: l10n.maintenance_field_date,
            icon: LucideIcons.calendar,
            trailingIcon: LucideIcons.chevronDown,
            readOnly: true,
            controller: TextEditingController(
              text: SpanishDateFormat.short(
                widget.state.serviceDate ?? DateTime.now(),
              ),
            ),
            onTap: () => _pickDate(context),
          ),
          const SizedBox(height: 10),
          AppTextField(
            label: l10n.maintenance_field_workshop,
            icon: LucideIcons.store,
            controller: _workshopController,
            onChanged: widget.cubit.updateWorkshop,
          ),
          const SizedBox(height: 10),
          AppTextField(
            label: l10n.maintenance_field_cost,
            icon: LucideIcons.banknote,
            controller: _costController,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsInputFormatter()],
            onChanged: (value) =>
                widget.cubit.updateCost(ThousandsInputFormatter.parse(value)),
          ),
          const SizedBox(height: 10),
          AppTextField(
            label: l10n.maintenance_field_note,
            icon: LucideIcons.stickyNote,
            controller: _notesController,
            onChanged: widget.cubit.updateNotes,
          ),
          const SizedBox(height: 16),
          MaintenanceSectionTitle(l10n.maintenance_section_reminder),
          const SizedBox(height: 6),
          MaintenanceReminderRow(
            label: l10n.maintenance_reminder_toggle_label,
            subtitle:
                widget.state.reminderEnabled &&
                    reminder != null &&
                    !reminder.isEmpty
                ? l10n.maintenance_reminder_toggle_on(
                    maintenanceReminderSummary(context, reminder),
                  )
                : l10n.maintenance_reminder_toggle_off,
            switchValue: widget.state.reminderEnabled,
            onSwitchChanged: (value) {
              widget.cubit.toggleReminder(value);
              if (value) _openIntervalSheet(context);
            },
            onTap: widget.state.reminderEnabled
                ? () => _openIntervalSheet(context)
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.state.serviceDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) widget.cubit.updateServiceDate(picked);
  }

  void _openIntervalSheet(BuildContext context) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => MaintenanceIntervalSheet(
        subtitle: l10n.maintenance_interval_sheet_subtitle(
          widget.cubit.resolveType(),
          widget.state.vehicle.displayName,
        ),
        initial: widget.state.reminder ?? const MaintenanceReminder(),
        onSave: widget.cubit.setReminder,
      ),
    );
  }
}
