import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_form_fields.dart';

class MaintenanceNextKmPill extends StatelessWidget {
  const MaintenanceNextKmPill({super.key, this.onChanged});

  final void Function(int?)? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      width: 110,
      child: FormBuilderTextField(
        name: MaintenanceFormFields.nextMaintenanceMileage,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.right,
        onChanged: (value) => onChanged?.call(int.tryParse(value ?? '')),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return null;
          if (int.tryParse(value) == null) return 'Debe ser un número';
          return null;
        },
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: const Color(0xFF1A1A1F),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.darkBorderPrimary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.darkBorderPrimary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          hintText: '—',
          hintStyle: const TextStyle(
            color: AppColors.darkTextSecondary,
            fontSize: 13,
          ),
          suffixIcon: const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Align(
              widthFactor: 1,
              alignment: Alignment.centerRight,
              child: Text(
                'km',
                style: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
