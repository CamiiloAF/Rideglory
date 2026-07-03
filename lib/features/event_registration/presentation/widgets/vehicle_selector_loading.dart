import 'package:flutter/material.dart';

class VehicleSelectorLoading extends StatelessWidget {
  const VehicleSelectorLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
