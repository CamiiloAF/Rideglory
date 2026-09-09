import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/vehicle_form_cubit.dart';
import '../cubit/vehicle_form_state.dart';

/// Fila "Agregar foto (opcional)": la moto se puede crear sin foto y
/// agregarla después desde editar.
///
/// Pencil: e0fmR › Agregar foto
class VehiclePhotoPickerRow extends StatelessWidget {
  const VehiclePhotoPickerRow({super.key});

  Future<void> _pickImage(BuildContext context) async {
    final cubit = context.read<VehicleFormCubit>();
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final extension = picked.path.split('.').last.toLowerCase();
    if (context.mounted) cubit.imagePicked(bytes, extension);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return InkWell(
      onTap: () => _pickImage(context),
      borderRadius: BorderRadius.circular(16),
      child: BlocBuilder<VehicleFormCubit, VehicleFormState>(
        buildWhen: (previous, current) => previous.imageBytes != current.imageBytes,
        builder: (context, state) {
          final hasImage = state.imageBytes != null;
          return Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  hasImage ? LucideIcons.checkCircle2 : LucideIcons.camera,
                  size: 20,
                  color: colors.text,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasImage
                            ? context.l10n.garage_photo_selected_label
                            : context.l10n.garage_photo_add_label,
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: colors.text),
                      ),
                      Text(
                        context.l10n.garage_photo_add_hint,
                        style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, size: 18, color: colors.textSecondary),
              ],
            ),
          );
        },
      ),
    );
  }
}
