import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleCardPlaceholderIcon extends StatelessWidget {
  const VehicleCardPlaceholderIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.two_wheeler_rounded,
      color: context.colorScheme.primary,
      size: 28,
    );
  }
}
