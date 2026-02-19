import 'package:flutter/material.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

class MaintenanceNotesSection extends StatelessWidget {
  final MaintenanceModel maintenance;

  const MaintenanceNotesSection({super.key, required this.maintenance});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.notes_rounded, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                maintenance.notes!,
                style: context.bodySmall?.copyWith(height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
