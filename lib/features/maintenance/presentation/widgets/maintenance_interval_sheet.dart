import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/utils/thousands_input_formatter.dart';
import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/components/app_text_field.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/maintenance_reminder.dart';

/// Hoja de intervalo del recordatorio: "cada X km" y/o "cada Y meses"
/// (Pencil `Z6b3T`).
class MaintenanceIntervalSheet extends StatefulWidget {
  const MaintenanceIntervalSheet({
    required this.subtitle,
    required this.initial,
    required this.onSave,
    super.key,
  });

  final String subtitle;
  final MaintenanceReminder initial;
  final ValueChanged<MaintenanceReminder> onSave;

  @override
  State<MaintenanceIntervalSheet> createState() =>
      _MaintenanceIntervalSheetState();
}

class _MaintenanceIntervalSheetState extends State<MaintenanceIntervalSheet> {
  late final TextEditingController _kmController;
  late final TextEditingController _monthsController;

  @override
  void initState() {
    super.initState();
    _kmController = TextEditingController(
      text: ThousandsInputFormatter.format(widget.initial.everyKm) ?? '',
    );
    _monthsController = TextEditingController(
      text: widget.initial.everyMonths?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _kmController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              l10n.maintenance_interval_sheet_title,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              style: TextStyle(fontSize: 13.5, color: colors.textSecondary),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: l10n.maintenance_interval_km_label,
                    controller: _kmController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsInputFormatter()],
                    suffixText: l10n.maintenance_interval_km_suffix,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: l10n.maintenance_interval_months_label,
                    controller: _monthsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    suffixText: l10n.maintenance_interval_months_suffix,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.info, size: 15, color: colors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.maintenance_interval_helper,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppPrimaryButton(
              label: l10n.maintenance_action_save,
              onPressed: () {
                final km = ThousandsInputFormatter.parse(
                  _kmController.text,
                )?.toInt();
                final months = int.tryParse(_monthsController.text);
                widget.onSave(
                  MaintenanceReminder(everyKm: km, everyMonths: months),
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
