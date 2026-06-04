import 'package:flutter/material.dart';
import 'package:rideglory/features/vehicle_documents/presentation/widgets/validity_card.dart';

/// Thin wrapper over [DocumentValidityCard] for use in SOAT form screens.
///
/// Preserves the same public API ([startDate], [expiryDate]) so that existing
/// callers (SOAT form, tests) require no changes.
class SoatValidityCard extends StatelessWidget {
  const SoatValidityCard({
    super.key,
    required this.startDate,
    required this.expiryDate,
  });

  final DateTime? startDate;
  final DateTime? expiryDate;

  @override
  Widget build(BuildContext context) {
    return DocumentValidityCard(startDate: startDate, expiryDate: expiryDate);
  }
}
