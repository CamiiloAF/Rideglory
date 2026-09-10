import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_radii.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Portada opcional de la rodada (paso 1). Sin mapa ni recorte: solo
/// elegir una foto de la galería.
class CreateEventPhotoPicker extends StatelessWidget {
  const CreateEventPhotoPicker({
    required this.localImagePath,
    required this.onPicked,
    super.key,
  });

  final String? localImagePath;
  final ValueChanged<String?> onPicked;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.md),
      onTap: () async {
        final picked = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        if (picked != null) onPicked(picked.path);
      },
      child: Container(
        height: 120,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: colors.borderStrong),
          image: localImagePath == null
              ? null
              : DecorationImage(
                  image: FileImage(File(localImagePath!)),
                  fit: BoxFit.cover,
                ),
        ),
        child: localImagePath != null
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.imagePlus,
                    size: 24,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.events_create_photo_cta,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
