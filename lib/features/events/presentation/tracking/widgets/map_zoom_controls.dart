import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/live_map_widget.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/zoom_button.dart';

class MapZoomControls extends StatelessWidget {
  const MapZoomControls({
    super.key,
    required this.controller,
  });

  final LiveMapController? controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ZoomButton(
            icon: Icons.add,
            onTap: controller == null ? null : () => controller!.zoomIn(),
          ),
          Container(height: 1, color: AppColors.darkBorder),
          ZoomButton(
            icon: Icons.remove,
            onTap: controller == null ? null : () => controller!.zoomOut(),
          ),
        ],
      ),
    );
  }
}

