import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

class HomeVehiclePlaceholderImage extends StatelessWidget {
  const HomeVehiclePlaceholderImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      color: context.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.two_wheeler,
        size: 64,
        color: context.colorScheme.outlineVariant,
      ),
    );
  }
}
