import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/shared/widgets/form/app_dropdown.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';
import 'package:rideglory/shared/widgets/form/app_text_field_label.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_strings.dart';

class MileagesAndUnitFields extends StatefulWidget {
  const MileagesAndUnitFields({
    super.key,
    this.currentMileage,
    required this.mileageFieldName,
    required this.distanceUnitFieldName,
    this.validatorsType = MileageValidatorsType.noRequired,
    this.isRequired = true,
  });

  final int? currentMileage;
  final String mileageFieldName;
  final String distanceUnitFieldName;
  final MileageValidatorsType validatorsType;
  final bool isRequired;

  @override
  State<MileagesAndUnitFields> createState() => _MileagesAndUnitFieldsState();
}

class _MileagesAndUnitFieldsState extends State<MileagesAndUnitFields> {
  @override
  Widget build(BuildContext context) {
    var labelText = MaintenanceStrings.currentMileage;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        AppTextFieldLabel(labelText: labelText, isRequired: widget.isRequired),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: AppTextField(
                isRequired: widget.isRequired,
                name: widget.mileageFieldName,
                initialValue: widget.currentMileage?.toString(),
                hintText: labelText,
                prefixIcon: Icons.speed,
                keyboardType: TextInputType.number,
                validator: FormBuilderValidators.compose(
                  widget.validatorsType.getValidators(widget.currentMileage),
                ),

                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppDropdown<DistanceUnit>(
                name: widget.distanceUnitFieldName,
                items: DistanceUnit.values
                    .map(
                      (unit) => DropdownMenuItem(
                        value: unit,
                        child: Text(unit.label),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum MileageValidatorsType {
  currentMileage,
  nextMileageMaintenance,
  noRequired;

  const MileageValidatorsType();

  List<String? Function(String?)> getValidators(int? currentMileage) {
    switch (this) {
      case MileageValidatorsType.currentMileage:
        return [
          FormBuilderValidators.required(
            errorText: '${MaintenanceStrings.mileage} ${AppStrings.required}',
          ),
          FormBuilderValidators.numeric(errorText: AppStrings.mustBeNumber),
          FormBuilderValidators.min(
            0,
            errorText: AppStrings.mustBeGreaterThanZero,
          ),
        ];
      case MileageValidatorsType.nextMileageMaintenance:
        return [
          FormBuilderValidators.numeric(errorText: AppStrings.mustBeNumber),
          FormBuilderValidators.min(
            currentMileage ?? 0,
            errorText: '${AppStrings.mustBeGreaterThan} ${currentMileage ?? 0}',
          ),
        ];
      case MileageValidatorsType.noRequired:
        return [];
    }
  }
}
