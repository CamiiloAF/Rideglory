import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';
import 'package:rideglory/shared/widgets/form/app_text_field_label.dart';

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
    var labelText = 'Kilometraje actual';
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        AppTextFieldLabel(labelText: labelText, isRequired: widget.isRequired),
        const SizedBox(height: 8),
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
              child: FormBuilderDropdown<DistanceUnit>(
                name: widget.distanceUnitFieldName,
                decoration: InputDecoration(
                  labelText: 'Unidad',
                  border: OutlineInputBorder(),
                ),
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
            errorText: 'El kilometraje es requerido',
          ),
          FormBuilderValidators.numeric(errorText: 'Debe ser un número'),
          FormBuilderValidators.min(0, errorText: 'Debe ser mayor a 0'),
        ];
      case MileageValidatorsType.nextMileageMaintenance:
        return [
          FormBuilderValidators.numeric(errorText: 'Debe ser un número'),
          FormBuilderValidators.min(
            currentMileage ?? 0,
            errorText: 'Debe ser mayor a ${currentMileage ?? 0}',
          ),
        ];
      case MileageValidatorsType.noRequired:
        return [];
    }
  }
}
