import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/constants/registration_form_fields.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';

/// Blood type picker rendered as a grid of selectable chips (4 per row),
/// matching the Pencil `bts` design instead of a dropdown.
class RegistrationBloodTypeSelector extends StatelessWidget {
  const RegistrationBloodTypeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<BloodType>(
      name: RegistrationFormFields.bloodType,
      validator: FormBuilderValidators.required(
        errorText: context.l10n.registration_bloodTypeRequired,
      ),
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.registration_bloodType,
                  style: const TextStyle(
                    color: AppColors.textOnDarkSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  context.l10n.registration_bloodTypeSelectHint,
                  style: const TextStyle(
                    color: AppColors.textOnDarkTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            AppSpacing.gapSm,
            _BloodTypeChipRow(
              types: const [
                BloodType.aPositive,
                BloodType.aNegative,
                BloodType.bPositive,
                BloodType.bNegative,
              ],
              selected: field.value,
              onSelected: field.didChange,
            ),
            AppSpacing.gapSm,
            _BloodTypeChipRow(
              types: const [
                BloodType.abPositive,
                BloodType.abNegative,
                BloodType.oPositive,
                BloodType.oNegative,
              ],
              selected: field.value,
              onSelected: field.didChange,
            ),
            if (field.hasError) ...[
              AppSpacing.gapXs,
              Text(
                field.errorText ?? '',
                style: TextStyle(
                  color: context.colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BloodTypeChipRow extends StatelessWidget {
  const _BloodTypeChipRow({
    required this.types,
    required this.selected,
    required this.onSelected,
  });

  final List<BloodType> types;
  final BloodType? selected;
  final ValueChanged<BloodType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < types.length; index++) ...[
          if (index > 0) AppSpacing.hGapSm,
          Expanded(
            child: _BloodTypeChip(
              type: types[index],
              isSelected: types[index] == selected,
              onTap: () => onSelected(types[index]),
            ),
          ),
        ],
      ],
    );
  }
}

class _BloodTypeChip extends StatelessWidget {
  const _BloodTypeChip({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final BloodType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.darkTertiary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.darkBorderPrimary,
          ),
        ),
        child: Text(
          type.label,
          style: TextStyle(
            color: isSelected
                ? AppColors.darkBgPrimary
                : AppColors.textOnDarkSecondary,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
