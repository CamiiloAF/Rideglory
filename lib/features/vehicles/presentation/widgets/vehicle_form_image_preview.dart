import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';

class VehicleFormImagePreview extends StatelessWidget {
  const VehicleFormImagePreview({
    super.key,
    required this.imageData,
    required this.isLocal,
    required this.onClear,
  });

  final FormImageData imageData;
  final bool isLocal;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        isLocal
            ? Image.file(
                File(imageData.localImagePath!),
                fit: BoxFit.cover,
              )
            : Image.network(
                imageData.remoteImageUrl!,
                fit: BoxFit.cover,
              ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
