import 'package:flutter/material.dart';

class EventDetailHeaderOverlayGradient extends StatelessWidget {
  const EventDetailHeaderOverlayGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 300,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Color(0xE0000000)],
          ),
        ),
      ),
    );
  }
}
