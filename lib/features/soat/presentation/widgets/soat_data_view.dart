import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/soat/presentation/cubit/soat_cubit.dart';
import 'package:rideglory/features/soat/presentation/scan/soat_entry_flow.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_action_tile.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_detail_row.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/helpers/document_downloader.dart';

class SoatDataView extends StatefulWidget {
  const SoatDataView({super.key, required this.vehicle, required this.soat});

  final VehicleModel vehicle;
  final SoatModel soat;

  @override
  State<SoatDataView> createState() => _SoatDataViewState();
}

class _SoatDataViewState extends State<SoatDataView> {
  bool _openingDocument = false;
  bool _deleting = false;

  Future<void> _confirmAndDelete() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: context.l10n.soat_delete_confirm_title,
      content: context.l10n.soat_delete_confirm_message,
      confirmLabel: context.l10n.soat_delete_button,
      confirmType: DialogActionType.danger,
      icon: Icons.delete_outline,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    final success = await context.read<SoatCubit>().delete(
      widget.vehicle.id ?? '',
    );
    if (!mounted) return;

    if (success) {
      final vehicleId = widget.vehicle.id;
      if (vehicleId != null) {
        context.read<VehicleCubit>().clearSoatLocally(vehicleId);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.soat_deleted_success)),
      );
      context.pop();
    } else {
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errorOccurred)),
      );
    }
  }

  Color _heroColor() {
    return switch (widget.soat.status) {
      SoatStatus.valid => AppColors.success,
      SoatStatus.expiringSoon => AppColors.warning,
      SoatStatus.expired => AppColors.error,
      SoatStatus.noSoat => AppColors.textOnDarkSecondary,
    };
  }

  String _heroTitle(BuildContext context) {
    return switch (widget.soat.status) {
      SoatStatus.valid => context.l10n.soat_valid_title,
      SoatStatus.expiringSoon => context.l10n.soat_expiring_title,
      SoatStatus.expired => context.l10n.soat_expired_title,
      SoatStatus.noSoat => context.l10n.soat_status_no_soat,
    };
  }

  String _daysChip(BuildContext context) {
    final days = widget.soat.daysUntilExpiry;
    return switch (widget.soat.status) {
      SoatStatus.valid => context.l10n.soat_valid_days_remaining(days),
      SoatStatus.expiringSoon => context.l10n.soat_expiring_days_remaining(
        days,
      ),
      SoatStatus.expired => context.l10n.soat_expired_days_ago(days.abs()),
      SoatStatus.noSoat => '',
    };
  }

  String? _warningText(BuildContext context) {
    return switch (widget.soat.status) {
      SoatStatus.expiringSoon => context.l10n.soat_expiring_warning,
      SoatStatus.expired => context.l10n.soat_expired_warning,
      _ => null,
    };
  }

  Future<void> _openDocument() async {
    if (_openingDocument) return;
    setState(() => _openingDocument = true);
    try {
      final url = widget.soat.documentUrl!;
      await DocumentDownloader.openRemote(
        url,
        DocumentDownloader.fileNameFromUrl(url),
      );
    } finally {
      if (mounted) setState(() => _openingDocument = false);
    }
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
                color:
                    (widget.soat.status == SoatStatus.expired
                            ? AppColors.error
                            : AppColors.warning)
                        .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      (widget.soat.status == SoatStatus.expired
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
                    color: widget.soat.status == SoatStatus.expired
                        ? AppColors.error
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warningText,
                      style: TextStyle(
                        color: widget.soat.status == SoatStatus.expired
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
                if (widget.soat.policyNumber != null)
                  SoatDetailRow(
                    label: context.l10n.soat_field_policy_number,
                    value: widget.soat.policyNumber!,
                  ),
                if (widget.soat.insurer != null)
                  SoatDetailRow(
                    label: context.l10n.soat_field_insurer,
                    value: widget.soat.insurer!,
                  ),
                if (widget.soat.startDate != null)
                  SoatDetailRow(
                    label: context.l10n.soat_field_start_date,
                    value: dateFormat.format(widget.soat.startDate!),
                  ),
                SoatDetailRow(
                  label: context.l10n.soat_field_expiry_date,
                  value: dateFormat.format(widget.soat.expiryDate),
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Única acción principal: renovar cuando el SOAT está vencido.
          if (widget.soat.status == SoatStatus.expired) ...[
            AppButton(
              label: context.l10n.soat_renew_btn,
              onPressed: () => SoatEntryFlow.start(
                context,
                vehicle: widget.vehicle,
                onSaved: () {
                  if (context.mounted) {
                    context.read<SoatCubit>().load(widget.vehicle.id ?? '');
                  }
                },
              ),
              isFullWidth: true,
            ),
            const SizedBox(height: 16),
          ],
          // Acciones secundarias agrupadas en una lista discreta para no
          // saturar la pantalla de botones de color.
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorderPrimary),
            ),
            child: Column(
              children: [
                if (widget.soat.documentUrl != null)
                  SoatActionTile(
                    icon: Icons.description_outlined,
                    label: context.l10n.soat_view_document,
                    loading: _openingDocument,
                    onTap: _openDocument,
                  ),
                SoatActionTile(
                  icon: Icons.delete_outline_rounded,
                  label: context.l10n.soat_delete_button,
                  color: AppColors.error,
                  loading: _deleting,
                  showDivider: widget.soat.documentUrl != null,
                  onTap: _confirmAndDelete,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
