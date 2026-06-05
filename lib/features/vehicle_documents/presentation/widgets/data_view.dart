import 'package:flutter/material.dart';
import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_model.dart';
import 'package:rideglory/features/vehicle_documents/presentation/widgets/data_view_details_card.dart';
import 'package:rideglory/features/vehicle_documents/presentation/widgets/data_view_hero_card.dart';
import 'package:rideglory/features/vehicle_documents/presentation/widgets/data_view_warning_banner.dart';
import 'package:rideglory/features/vehicle_documents/presentation/widgets/detail_row.dart';

/// Generic data view for a vehicle document.
///
/// Renders a hero status card followed by a details card built from
/// [DocumentDetailRow] entries. SOAT-specific CTAs are passed in via
/// [heroFooter] and [actions].
class DocumentDataView<T extends VehicleDocumentModel> extends StatelessWidget {
  const DocumentDataView({
    super.key,
    required this.document,
    required this.heroColor,
    required this.heroIcon,
    required this.heroTitle,
    required this.heroDaysChip,
    this.heroWarning,
    required this.detailRows,
    this.heroFooter,
    this.actions,
  });

  final T document;
  final Color heroColor;
  final IconData heroIcon;
  final String heroTitle;
  final String? heroDaysChip;
  final String? heroWarning;

  /// List of [DocumentDetailRow] widgets for the details card.
  final List<DocumentDetailRow> detailRows;

  /// Optional widget rendered below the hero days chip (e.g. renew button).
  final Widget? heroFooter;

  /// Optional widget rendered below the details card (e.g. action list).
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DataViewHeroCard(
            heroColor: heroColor,
            heroIcon: heroIcon,
            heroTitle: heroTitle,
            heroDaysChip: heroDaysChip,
          ),
          if (heroWarning != null) ...[
            const SizedBox(height: 16),
            DataViewWarningBanner(
              warning: heroWarning!,
              color: heroColor,
            ),
          ],
          const SizedBox(height: 24),
          DataViewDetailsCard(rows: detailRows),
          if (heroFooter != null) ...[
            const SizedBox(height: 20),
            heroFooter!,
          ],
          if (actions != null) ...[
            const SizedBox(height: 16),
            actions!,
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
