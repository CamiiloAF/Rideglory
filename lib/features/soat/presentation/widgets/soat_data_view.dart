import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_detail_row.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';

class SoatDataView extends StatelessWidget {
  const SoatDataView({
    super.key,
    required this.vehicle,
    required this.soat,
  });

  final VehicleModel vehicle;
  final SoatModel soat;

  Color _heroColor() {
    return switch (soat.status) {
      SoatStatus.valid => AppColors.success,
      SoatStatus.expiringSoon => AppColors.warning,
      SoatStatus.expired => AppColors.error,
      SoatStatus.noSoat => AppColors.textOnDarkSecondary,
    };
  }

  String _heroTitle(BuildContext context) {
    return switch (soat.status) {
      SoatStatus.valid => context.l10n.soat_valid_title,
      SoatStatus.expiringSoon => context.l10n.soat_expiring_title,
      SoatStatus.expired => context.l10n.soat_expired_title,
      SoatStatus.noSoat => context.l10n.soat_status_no_soat,
    };
  }

  String _daysChip(BuildContext context) {
    final days = soat.daysUntilExpiry;
    return switch (soat.status) {
      SoatStatus.valid => context.l10n.soat_valid_days_remaining(days),
      SoatStatus.expiringSoon =>
        context.l10n.soat_expiring_days_remaining(days),
      SoatStatus.expired => context.l10n.soat_expired_days_ago(days.abs()),
      SoatStatus.noSoat => '',
    };
  }

  String? _warningText(BuildContext context) {
    return switch (soat.status) {
      SoatStatus.expiringSoon => context.l10n.soat_expiring_warning,
      SoatStatus.expired => context.l10n.soat_expired_warning,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final heroColor = _heroColor();
    final daysText = _daysChip(context);
    final warningText = _warningText(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero status card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: heroColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: heroColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.verified_outlined, color: heroColor, size: 48),
                const SizedBox(height: 12),
                Text(
                  _heroTitle(context),
                  style: TextStyle(
                    color: heroColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (daysText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: heroColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      daysText,
                      style: TextStyle(
                        color: heroColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (warningText != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (soat.status == SoatStatus.expired
                        ? AppColors.error
                        : AppColors.warning)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (soat.status == SoatStatus.expired
                          ? AppColors.error
                          : AppColors.warning)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: soat.status == SoatStatus.expired
                        ? AppColors.error
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warningText,
                      style: TextStyle(
                        color: soat.status == SoatStatus.expired
                            ? AppColors.error
                            : AppColors.warning,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          // Details card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorderPrimary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (soat.policyNumber != null)
                  SoatDetailRow(
                    label: context.l10n.soat_field_policy_number,
                    value: soat.policyNumber!,
                  ),
                if (soat.insurer != null)
                  SoatDetailRow(
                    label: context.l10n.soat_field_insurer,
                    value: soat.insurer!,
                  ),
                if (soat.startDate != null)
                  SoatDetailRow(
                    label: context.l10n.soat_field_start_date,
                    value: dateFormat.format(soat.startDate!),
                  ),
                SoatDetailRow(
                  label: context.l10n.soat_field_expiry_date,
                  value: dateFormat.format(soat.expiryDate),
                  isLast: true,
                ),
              ],
            ),
          ),
          if (soat.documentUrl != null) ...[
            const SizedBox(height: 16),
            AppButton(
              label: context.l10n.soat_view_document,
              onPressed: () => launchUrl(Uri.parse(soat.documentUrl!)),
              isFullWidth: true,
            ),
          ],
          const SizedBox(height: 12),
          if (soat.status == SoatStatus.expired)
            AppButton(
              label: context.l10n.soat_renew_btn,
              onPressed: () => context.pushNamed(
                AppRoutes.soatUpload,
                extra: vehicle,
              ),
              isFullWidth: true,
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
