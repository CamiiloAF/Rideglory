import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_form_fields.dart';

class MaintenanceNextDatePill extends StatefulWidget {
  final void Function(DateTime?)? onChanged;

  const MaintenanceNextDatePill({super.key, this.onChanged});

  @override
  State<MaintenanceNextDatePill> createState() =>
      _MaintenanceNextDatePillState();
}

class _MaintenanceNextDatePillState extends State<MaintenanceNextDatePill> {
  DateTime? _selectedDate;

  Future<void> _pickDate(FormFieldState<DateTime> field) async {
    final now = DateTime.now();
    final current = _selectedDate ?? field.value;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      field.didChange(picked);
      widget.onChanged?.call(picked);
    }
  }

  void _clearDate(FormFieldState<DateTime> field) {
    setState(() => _selectedDate = null);
    field.didChange(null);
    widget.onChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<DateTime>(
      name: MaintenanceFormFields.nextMaintenanceDate,
      builder: (field) {
        final displayDate = _selectedDate ?? field.value;
        final hasDate = displayDate != null;
        final label = hasDate
            ? DateFormat('dd MMM yyyy', 'es').format(displayDate)
            : '—';

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _pickDate(field),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.darkBgSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasDate ? AppColors.primary : AppColors.darkBorderPrimary,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: hasDate ? AppColors.primary : AppColors.darkTextSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: hasDate ? AppColors.darkTextPrimary : AppColors.darkTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (hasDate) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _clearDate(field),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: AppColors.textOnDarkTertiary,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
