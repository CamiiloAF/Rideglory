import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/vehicle_document_default_icon_slot.dart';

class VehicleDocumentIconSlot extends StatelessWidget {
  const VehicleDocumentIconSlot({
    super.key,
    required this.hasDocument,
    this.localPath,
  });

  final bool hasDocument;
  final String? localPath;

  @override
  Widget build(BuildContext context) {
    if (hasDocument && localPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Image.file(
            File(localPath!),
            fit: BoxFit.cover,
            errorBuilder: (ctx, e, s) =>
                const VehicleDocumentDefaultIconSlot(hasDocument: true),
          ),
        ),
      );
    }
    return VehicleDocumentDefaultIconSlot(hasDocument: hasDocument);
  }
}
