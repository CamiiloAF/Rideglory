import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleDetailRowDivider extends StatelessWidget {
  const VehicleDetailRowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.darkBorderPrimary);
  }
}
