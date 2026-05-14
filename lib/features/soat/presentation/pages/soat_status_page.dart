import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/soat/presentation/cubit/soat_cubit.dart';
import 'package:rideglory/features/soat/presentation/pages/soat_manual_form_page.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';

class SoatStatusPage extends StatelessWidget {
  const SoatStatusPage({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SoatCubit>()..load(vehicle.id ?? ''),
      child: _SoatStatusView(vehicle: vehicle),
    );
  }
}

class _SoatStatusView extends StatelessWidget {
  const _SoatStatusView({required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppBar(
        title: Text(
          context.l10n.soat_page_status_title,
          style: const TextStyle(
            color: AppColors.textOnDarkPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.darkBgPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textOnDarkPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          BlocBuilder<SoatCubit, ResultState<SoatModel>>(
            builder: (context, state) {
              if (state is! Data<SoatModel>) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _navigateToEdit(context, state.data),
                child: Text(
                  context.l10n.soat_edit_btn,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<SoatCubit, ResultState<SoatModel>>(
        builder: (context, state) {
          if (state is Initial || state is Loading) {
            return const AppLoadingIndicator(
              variant: AppLoadingIndicatorVariant.page,
            );
          } else if (state is Empty) {
            return _SoatEmptyState(vehicle: vehicle);
          } else if (state is Data) {
            return _SoatDataView(
              vehicle: vehicle,
              soat: (state as Data<SoatModel>).data,
            );
          } else if (state is Error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 48,
                    ),
                    AppSpacing.gapLg,
                    Text(
                      (state as Error<SoatModel>).error.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textOnDarkSecondary,
                        fontSize: 14,
                      ),
                    ),
                    AppSpacing.gapLg,
                    AppButton(
                      label: context.l10n.soat_retry,
                      onPressed: () =>
                          context.read<SoatCubit>().load(vehicle.id ?? ''),
                      isFullWidth: false,
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _navigateToEdit(BuildContext context, SoatModel soat) {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => SoatManualFormPage(
          vehicle: vehicle,
          existingSoat: soat,
        ),
      ),
    ).then((result) {
      if (result == true && context.mounted) {
        context.read<SoatCubit>().load(vehicle.id ?? '');
      }
    });
  }
}

class _SoatEmptyState extends StatelessWidget {
  const _SoatEmptyState({required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.darkBorderPrimary),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: AppColors.textOnDarkTertiary,
                size: 40,
              ),
            ),
            AppSpacing.gapXxl,
            Text(
              context.l10n.soat_status_no_soat,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            AppSpacing.gapSm,
            Text(
              context.l10n.soat_manual_note,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textOnDarkSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            AppSpacing.gapXxl,
            AppButton(
              label: context.l10n.soat_renew_btn,
              onPressed: () => context.pushNamed(
                AppRoutes.soatUpload,
                extra: vehicle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoatDataView extends StatelessWidget {
  const _SoatDataView({
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
      SoatStatus.valid =>
        context.l10n.soat_valid_days_remaining(days),
      SoatStatus.expiringSoon =>
        context.l10n.soat_expiring_days_remaining(days),
      SoatStatus.expired =>
        context.l10n.soat_expired_days_ago(days.abs()),
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
                  _DetailRow(
                    label: context.l10n.soat_field_policy_number,
                    value: soat.policyNumber!,
                  ),
                if (soat.insurer != null)
                  _DetailRow(
                    label: context.l10n.soat_field_insurer,
                    value: soat.insurer!,
                  ),
                if (soat.startDate != null)
                  _DetailRow(
                    label: context.l10n.soat_field_start_date,
                    value: dateFormat.format(soat.startDate!),
                  ),
                _DetailRow(
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textOnDarkSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
