import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_action_tile.dart';
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';
import 'package:rideglory/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit.dart';
import 'package:rideglory/features/tecnomecanica/presentation/flow/tecnomecanica_entry_flow.dart';
import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_status.dart';
import 'package:rideglory/features/vehicle_documents/presentation/widgets/detail_row.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/shared/helpers/document_downloader.dart';

class TecnomecanicaDataView extends StatefulWidget {
  const TecnomecanicaDataView({
    super.key,
    required this.vehicle,
    required this.rtm,
  });

  final VehicleModel vehicle;
  final TecnomecanicaModel rtm;

  @override
  State<TecnomecanicaDataView> createState() => _TecnomecanicaDataViewState();
}

class _TecnomecanicaDataViewState extends State<TecnomecanicaDataView> {
  bool _deleting = false;
  bool _openingDocument = false;

  Future<void> _openDocument() async {
    if (_openingDocument) return;
    setState(() => _openingDocument = true);
    try {
      final url = widget.rtm.documentUrl!;
      await DocumentDownloader.openRemote(
        url,
        DocumentDownloader.fileNameFromUrl(url),
      );
    } finally {
      if (mounted) setState(() => _openingDocument = false);
    }
  }

  Future<void> _confirmAndDelete() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: context.l10n.tecnomecanica_delete_confirm_title,
      content: context.l10n.tecnomecanica_delete_confirm_message,
      confirmLabel: context.l10n.tecnomecanica_delete_button,
      confirmType: DialogActionType.danger,
      icon: Icons.delete_outline,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    final success = await context.read<TecnomecanicaCubit>().delete(
      widget.vehicle.id ?? '',
    );
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tecnomecanica_deleted_success)),
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
    return switch (widget.rtm.documentStatus) {
      VehicleDocumentStatus.valid => AppColors.success,
      VehicleDocumentStatus.expiringSoon => AppColors.warning,
      VehicleDocumentStatus.expired => AppColors.error,
      VehicleDocumentStatus.none => AppColors.textOnDarkSecondary,
    };
  }

  String _heroTitle(BuildContext context) {
    return switch (widget.rtm.documentStatus) {
      VehicleDocumentStatus.valid => context.l10n.tecnomecanica_valid_title,
      VehicleDocumentStatus.expiringSoon =>
        context.l10n.tecnomecanica_expiring_title,
      VehicleDocumentStatus.expired => context.l10n.tecnomecanica_expired_title,
      VehicleDocumentStatus.none =>
        context.l10n.tecnomecanica_status_no_rtm,
    };
  }

  String _daysChip(BuildContext context) {
    final days = widget.rtm.daysUntilExpiry;
    return switch (widget.rtm.documentStatus) {
      VehicleDocumentStatus.valid =>
        context.l10n.tecnomecanica_valid_days_remaining(days),
      VehicleDocumentStatus.expiringSoon =>
        context.l10n.tecnomecanica_valid_days_remaining(days),
      VehicleDocumentStatus.expired =>
        context.l10n.tecnomecanica_expired_days_ago(days.abs()),
      VehicleDocumentStatus.none => '',
    };
  }

  String? _warningText(BuildContext context) {
    return switch (widget.rtm.documentStatus) {
      VehicleDocumentStatus.expiringSoon =>
        context.l10n.tecnomecanica_expiring_warning,
      VehicleDocumentStatus.expired =>
        context.l10n.tecnomecanica_expired_warning,
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
                color: (widget.rtm.documentStatus == VehicleDocumentStatus.expired
                        ? AppColors.error
                        : AppColors.warning)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (widget.rtm.documentStatus ==
                              VehicleDocumentStatus.expired
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
                    color: widget.rtm.documentStatus ==
                            VehicleDocumentStatus.expired
                        ? AppColors.error
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warningText,
                      style: TextStyle(
                        color: widget.rtm.documentStatus ==
                                VehicleDocumentStatus.expired
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
                DocumentDetailRow(
                  label: context.l10n.tecnomecanica_field_cda_name,
                  value: widget.rtm.cdaName,
                ),
                DocumentDetailRow(
                  label: context.l10n.tecnomecanica_field_start_date,
                  value: dateFormat.format(widget.rtm.startDate),
                ),
                DocumentDetailRow(
                  label: context.l10n.tecnomecanica_field_expiry_date,
                  value: dateFormat.format(widget.rtm.expiryDate),
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // CTA when expired
          if (widget.rtm.documentStatus == VehicleDocumentStatus.expired) ...[
            AppButton(
              label: context.l10n.tecnomecanica_renew_btn,
              onPressed: () =>
                  TecnomecanicaEntryFlow.start(context, widget.vehicle),
              isFullWidth: true,
            ),
            const SizedBox(height: 16),
          ],
          // Actions card
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorderPrimary),
            ),
            child: Column(
              children: [
                if (widget.rtm.documentUrl != null)
                  SoatActionTile(
                    icon: Icons.description_outlined,
                    label: context.l10n.soat_view_document,
                    loading: _openingDocument,
                    onTap: _openDocument,
                  ),
                SoatActionTile(
                  icon: Icons.delete_outline_rounded,
                  label: context.l10n.tecnomecanica_delete_button,
                  color: AppColors.error,
                  loading: _deleting,
                  showDivider: widget.rtm.documentUrl != null,
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
