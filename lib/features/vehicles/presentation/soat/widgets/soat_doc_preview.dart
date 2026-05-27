import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class SoatDocPreview extends StatelessWidget {
  const SoatDocPreview({super.key, required this.imageFile});

  final XFile imageFile;

  bool get _isPdf => imageFile.path.toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    if (_isPdf) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.picture_as_pdf_outlined,
              size: 44,
              color: AppColors.info,
            ),
            const SizedBox(height: 8),
            Text(
              imageFile.path.split('/').last,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textOnDarkSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 180,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(imageFile.path),
              fit: BoxFit.cover,
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.darkCard],
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  context.l10n.vehicle_soat_doc_uploaded,
                  style: const TextStyle(
                    color: AppColors.textOnDarkSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
