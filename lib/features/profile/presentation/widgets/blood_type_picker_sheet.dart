import 'package:flutter/material.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../domain/blood_type.dart';
import '../blood_type_label.dart';

/// Hoja de selección de tipo de sangre, disparada por [BloodTypeField].
class BloodTypePickerSheet extends StatelessWidget {
  const BloodTypePickerSheet({this.selected, super.key});

  final BloodType? selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SafeArea(
      child: Wrap(
        children: BloodType.values.map((bloodType) {
          final isSelected = bloodType == selected;
          return ListTile(
            title: Text(
              bloodTypeLabel(context, bloodType),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? colors.accent : colors.text,
              ),
            ),
            onTap: () => Navigator.of(context).pop(bloodType),
          );
        }).toList(),
      ),
    );
  }
}
