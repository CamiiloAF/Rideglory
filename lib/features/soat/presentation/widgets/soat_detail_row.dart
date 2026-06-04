import 'package:flutter/material.dart';
import 'package:rideglory/features/vehicle_documents/presentation/widgets/detail_row.dart';

/// Thin wrapper over [DocumentDetailRow] with SOAT-specific defaults.
class SoatDetailRow extends StatelessWidget {
  const SoatDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return DocumentDetailRow(label: label, value: value, isLast: isLast);
  }
}
