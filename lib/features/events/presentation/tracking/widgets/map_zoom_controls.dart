import 'package:flutter/material.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/live_map_widget.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/zoom_button.dart';
import 'package:rideglory/design_system/design_system.dart';

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
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colorScheme.outlineVariant),
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
          Container(height: 1, color: context.colorScheme.outlineVariant),
          ZoomButton(
            icon: Icons.remove,
            onTap: controller == null ? null : () => controller!.zoomOut(),
          ),
        ],
      ),
    );
  }
}

