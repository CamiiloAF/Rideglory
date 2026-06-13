import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';

/// Animated pulsing ring (44 px) + orange center dot (14 px).
///
/// Visible only when there are 0 waypoints, hinting the user to add a route
/// point by tapping on the map.
///
/// Uses an [AnimationController] — [dispose] is called automatically via
/// [State.dispose].
class PulsingMapDot extends StatefulWidget {
  const PulsingMapDot({super.key});

  @override
  State<PulsingMapDot> createState() => _PulsingMapDotState();
}

class _PulsingMapDotState extends State<PulsingMapDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnim = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing ring
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Opacity(
                opacity: _opacityAnim.value,
                child: Transform.scale(
                  scale: _scaleAnim.value,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Center dot
          Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
