import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleDocumentUploadButton extends StatelessWidget {
  const VehicleDocumentUploadButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.darkTertiary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.darkBorderLight),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload, size: 14, color: AppColors.textOnDarkSecondary),
            SizedBox(width: 6),
            Text(
              'Subir',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnDarkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
