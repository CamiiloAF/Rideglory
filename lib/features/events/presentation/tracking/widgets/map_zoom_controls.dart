import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/live_map_widget.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/zoom_button.dart';

class MapZoomControls extends StatelessWidget {
  const MapZoomControls({super.key, required this.controller});

  final LiveMapController? controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.darkCard.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
          Container(height: 1, color: AppColors.darkBorderPrimary),
          ZoomButton(
            icon: Icons.remove,
            onTap: controller == null ? null : () => controller!.zoomOut(),
          ),
        ],
      ),
    );
  }
}
