import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_form_fields.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';

class MaintenanceNextKmPill extends StatelessWidget {
  const MaintenanceNextKmPill({super.key, this.onChanged});

  final void Function(int?)? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: AppTextField(
        name: MaintenanceFormFields.nextMaintenanceMileage,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) => onChanged?.call(int.tryParse(value ?? '')),
        validator: (value) {
          if (value == null || value.isEmpty) return null;
          if (int.tryParse(value) == null) return 'Debe ser un número';
          return null;
        },
        hintText: '—',
        suffixIcon: const Padding(
          padding: EdgeInsets.only(right: 8),
          child: Align(
            widthFactor: 1,
            alignment: Alignment.centerRight,
            child: Text(
              'km',
              style: TextStyle(
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
