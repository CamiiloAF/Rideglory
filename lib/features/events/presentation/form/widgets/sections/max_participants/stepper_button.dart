import 'package:flutter/material.dart';

class StepperButton extends StatelessWidget {
  const StepperButton({super.key, required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(width: 40, height: 40, child: Center(child: child)),
    );
  }
}
