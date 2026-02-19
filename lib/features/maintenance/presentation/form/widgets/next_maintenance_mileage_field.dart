import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_strings.dart';
import 'package:rideglory/core/constants/app_strings.dart';

class NextMaintenanceMileageField extends StatefulWidget {
  final int? currentMileage;
  final Function(bool) onValidationChanged;

  const NextMaintenanceMileageField({
    super.key,
    required this.currentMileage,
    required this.onValidationChanged,
  });

  @override
  State<NextMaintenanceMileageField> createState() =>
      _NextMaintenanceMileageFieldState();
}

class _NextMaintenanceMileageFieldState
    extends State<NextMaintenanceMileageField> {
  bool _shouldValidate = false;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      name: 'nextMaintenanceMileage',
      labelText: MaintenanceStrings.nextMaintenanceMileage,
      keyboardType: TextInputType.number,
      prefixIcon: Icons.speed,
      onChanged: (value) {
        final shouldValidate = value != null && value.isNotEmpty;
        if (_shouldValidate != shouldValidate) {
          setState(() {
            _shouldValidate = shouldValidate;
          });
          widget.onValidationChanged(shouldValidate);
        }
      },
      validator: _shouldValidate
          ? FormBuilderValidators.compose([
              FormBuilderValidators.numeric(errorText: AppStrings.mustBeNumber),
              (value) {
                if (value == null || value.isEmpty) return null;
                final mileage = int.tryParse(value);
                if (mileage != null &&
                    widget.currentMileage != null &&
                    mileage <= widget.currentMileage!) {
                  return '${AppStrings.mustBeGreaterThan} ${MaintenanceStrings.currentMileage} (${widget.currentMileage})';
                }
                return null;
              },
            ])
          : null,
    );
  }
}
