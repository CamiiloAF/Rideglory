import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class HomeEventDefaultBackground extends StatelessWidget {
  const HomeEventDefaultBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkCard, AppColors.darkCard],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.landscape_outlined,
          size: 60,
          color: context.colorScheme.outlineVariant,
        ),
      ),
    );
  }
}
