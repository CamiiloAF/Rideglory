import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicle_documents/presentation/widgets/detail_row.dart';

/// Details card listing [DocumentDetailRow] entries in [DocumentDataView].
class DataViewDetailsCard extends StatelessWidget {
  const DataViewDetailsCard({super.key, required this.rows});

  final List<DocumentDetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }
}
