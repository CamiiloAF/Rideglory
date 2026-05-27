import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleDocumentDefaultIconSlot extends StatelessWidget {
  const VehicleDocumentDefaultIconSlot({super.key, required this.hasDocument});

  final bool hasDocument;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: hasDocument ? AppColors.primarySubtle : AppColors.darkTertiary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.description_outlined,
        size: 20,
        color: hasDocument
            ? AppColors.primary
            : AppColors.textOnDarkSecondary,
      ),
    );
  }
}
