import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

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
      labelText: context.l10n.maintenance_nextMaintenanceMileage,
      keyboardType: TextInputType.number,
      prefixIcon: Icons.speed,
      suffixText: 'km',
      textInputAction: TextInputAction.done,
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
              FormBuilderValidators.numeric(errorText: context.l10n.mustBeNumber),
              (value) {
                if (value == null || value.isEmpty) return null;
                final mileage = int.tryParse(value);
                if (mileage != null &&
                    widget.currentMileage != null &&
                    mileage <= widget.currentMileage!) {
                  return '${context.l10n.mustBeGreaterThan} ${context.l10n.maintenance_currentMileage} (${widget.currentMileage})';
                }
                return null;
              },
            ])
          : null,
    );
  }
}
