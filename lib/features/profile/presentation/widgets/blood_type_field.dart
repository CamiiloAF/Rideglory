import 'package:flutter/material.dart';

import '../../../../design_system/components/app_text_field.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/blood_type.dart';
import '../blood_type_label.dart';
import 'blood_type_picker_sheet.dart';

/// Selector de tipo de sangre: abre una hoja con las 8 opciones. Sin frame
/// propio en el `.pen` — reutiliza `AppTextField` en modo solo-lectura como
/// disparador (decisión de F4).
class BloodTypeField extends StatelessWidget {
  const BloodTypeField({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final BloodType? value;
  final ValueChanged<BloodType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: value != null ? bloodTypeLabel(context, value!) : '',
    );
    return AppTextField(
      label: context.l10n.profile_field_blood_type,
      controller: controller,
      readOnly: true,
      onTap: () async {
        final selected = await showModalBottomSheet<BloodType>(
          context: context,
          builder: (context) => BloodTypePickerSheet(selected: value),
        );
        if (selected != null) {
          onChanged(selected);
        }
      },
    );
  }
}
