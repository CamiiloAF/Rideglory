import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class HomeEventDefaultBackground extends StatelessWidget {
  const HomeEventDefaultBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D1A0A), Color(0xFF1A0D05)],
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
