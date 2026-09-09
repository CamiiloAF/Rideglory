import 'package:flutter/material.dart';

import '../../../../design_system/components/app_text_field.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/maintenance_type_suggestion.dart';
import '../cubit/register_maintenance_cubit.dart';
import '../cubit/register_maintenance_state.dart';
import '../widgets/maintenance_type_labels.dart';
import '../widgets/maintenance_type_option_row.dart';

/// Paso 1: elegir el tipo de mantenimiento, o escribirlo libre si elige
/// "Otro" (Pencil `Yhgp2` / `oMSFa`).
class RegisterMaintenanceStep1 extends StatelessWidget {
  const RegisterMaintenanceStep1({
    required this.state,
    required this.cubit,
    super.key,
  });

  final RegisterMaintenanceState state;
  final RegisterMaintenanceCubit cubit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = context.l10n;

    if (state.isOtherType) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.maintenance_register_step1_other_question,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: l10n.maintenance_type_other_field_label,
              helperText: l10n.maintenance_type_other_field_hint,
              onChanged: cubit.updateCustomType,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.maintenance_register_step1_question,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 14),
          for (final suggestion
              in MaintenanceTypeSuggestion.orderedChoices) ...[
            MaintenanceTypeOptionRow(
              icon: maintenanceTypeSuggestionIcon(suggestion),
              label: maintenanceTypeSuggestionLabel(context, suggestion),
              selected: state.typeSuggestion == suggestion,
              onTap: () => cubit.selectTypeSuggestion(
                suggestion,
                maintenanceTypeSuggestionLabel(context, suggestion),
              ),
            ),
            if (suggestion != MaintenanceTypeSuggestion.orderedChoices.last)
              const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
