import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/vehicle_documents/presentation/widgets/validity_card_expired.dart';
import 'package:rideglory/features/vehicle_documents/presentation/widgets/validity_card_invalid_dates.dart';
import 'package:rideglory/features/vehicle_documents/presentation/widgets/validity_card_pending.dart';
import 'package:rideglory/features/vehicle_documents/presentation/widgets/validity_card_valid.dart';

/// Generic validity card shown inside vehicle document forms.
///
/// Receives [startDate] and [expiryDate] directly from form state and
/// renders the appropriate status (pending, invalid, expired, valid).
/// Does not depend on any BLoC.
class DocumentValidityCard extends StatelessWidget {
  const DocumentValidityCard({
    super.key,
    required this.startDate,
    required this.expiryDate,
  });

  final DateTime? startDate;
  final DateTime? expiryDate;

  @override
  Widget build(BuildContext context) {
    if (startDate == null || expiryDate == null) {
      return ValidityCardPending(label: context.l10n.vehicle_soat_status_pending);
    }

    if (!startDate!.isBefore(expiryDate!)) {
      return ValidityCardInvalidDates(
        title: context.l10n.vehicle_soat_status_invalid_dates_title,
        desc: context.l10n.vehicle_soat_status_invalid_dates_desc,
      );
    }

    final daysRemaining = expiryDate!
        .difference(
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
        )
        .inDays;

    if (daysRemaining < 0) {
      return ValidityCardExpired(
        title: context.l10n.vehicle_soat_status_expired_title,
        desc: context.l10n.vehicle_soat_status_expired_desc(daysRemaining.abs()),
      );
    }

    return ValidityCardValid(
      title: context.l10n.vehicle_soat_status_valid,
      desc: daysRemaining == 0
          ? context.l10n.vehicle_soat_status_expires_today
          : context.l10n.vehicle_soat_status_valid_desc(daysRemaining),
    );
  }
}
