import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/cover_overlay_button.dart';

/// Cover image preview with edit and optional delete overlay buttons.
class CoverPreviewWrapper extends StatelessWidget {
  const CoverPreviewWrapper({
    super.key,
    this.imageUrl,
    this.localImagePath,
    required this.onChangeTap,
    this.onRemoveTap,
  });

  final String? imageUrl;
  final String? localImagePath;
  final VoidCallback onChangeTap;
  final VoidCallback? onRemoveTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: localImagePath != null
              ? Image.file(
                  File(localImagePath!),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, err, stack) => _fallbackBox(),
                )
              : Image.network(
                  imageUrl ?? '',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, err, stack) => _fallbackBox(),
                ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              if (onRemoveTap != null) ...[
                CoverOverlayButton(
                  icon: Icons.delete_outline,
                  onTap: onRemoveTap!,
                ),
                const SizedBox(width: 8),
              ],
              CoverOverlayButton(
                icon: Icons.edit_outlined,
                onTap: onChangeTap,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fallbackBox() {
    return Container(
      height: 180,
      color: AppColors.darkCard,
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.textOnDarkTertiary,
        ),
      ),
    );
  }
}
