import 'package:flutter/material.dart';

class HomeEventGradientOverlay extends StatelessWidget {
  const HomeEventGradientOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0xDD000000)],
          stops: [0.3, 1.0],
        ),
      ),
    );
  }
}
