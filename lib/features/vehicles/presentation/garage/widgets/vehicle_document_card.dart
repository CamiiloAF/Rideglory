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
import 'package:rideglory/features/soat/presentation/scan/soat_entry_flow.dart';
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';
import 'package:rideglory/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit.dart';
import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_kind.dart';
import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_status.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/shared/router/app_routes.dart';

/// Card that shows the status of a vehicle document (e.g. SOAT) inside the
/// vehicle detail screen.
///
/// Uses a local [BlocProvider] so it is self-contained and does not rely on
/// any ancestor BLoC. No `getIt` calls in the widget body — DI only in the
/// [BlocProvider.create] factory.
class VehicleDocumentCard extends StatelessWidget {
  const VehicleDocumentCard({
    super.key,
    required this.kind,
    required this.vehicle,
    this.isArchived = false,
  });

  final VehicleDocumentKind kind;
  final VehicleModel vehicle;
  final bool isArchived;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      VehicleDocumentKind.soat => BlocProvider(
        create: (_) => getIt<SoatCubit>()..load(vehicle.id ?? ''),
        child: _SoatDocumentCardBody(vehicle: vehicle, isArchived: isArchived),
      ),
      VehicleDocumentKind.rtm => BlocProvider(
        create: (_) => getIt<TecnomecanicaCubit>()..load(vehicle.id ?? ''),
        child: _RtmDocumentCardBody(vehicle: vehicle, isArchived: isArchived),
      ),
    };
  }
}

class _SoatDocumentCardBody extends StatelessWidget {
  const _SoatDocumentCardBody({required this.vehicle, this.isArchived = false});

  final VehicleModel vehicle;
  final bool isArchived;

  Future<void> _onTap(
    BuildContext context,
    ResultState<SoatModel> state,
  ) async {
    if (state is Data<SoatModel>) {
      await context.pushNamed(AppRoutes.soatStatus, extra: vehicle);
    } else {
      await SoatEntryFlow.start(context, vehicle: vehicle);
    }
    if (context.mounted) {
      context.read<SoatCubit>().load(vehicle.id ?? '');
    }
  }

  Color _statusColor(SoatStatus? status) {
    return switch (status) {
      SoatStatus.valid => AppColors.statusGreen,
      SoatStatus.expiringSoon => AppColors.statusWarning,
      SoatStatus.expired => AppColors.statusError,
      _ => AppColors.textOnDarkSecondary,
    };
  }

  String _statusLabel(BuildContext context, SoatStatus? status) {
    return switch (status) {
      SoatStatus.valid => context.l10n.soat_status_valid,
      SoatStatus.expiringSoon => context.l10n.soat_status_expiring_soon,
      SoatStatus.expired => context.l10n.soat_status_expired,
      _ => context.l10n.vehicle_soat_tap_to_add,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: AppColors.textOnDarkTertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.vehicle_soat_section_title.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textOnDarkTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.darkBorderPrimary,
          ),
          BlocBuilder<SoatCubit, ResultState<SoatModel>>(
            builder: (context, state) {
              if (state is Initial || state is Loading) {
                return const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    height: 36,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                );
              }

              final soat = state is Data<SoatModel> ? state.data : null;

              if (isArchived) {
                return Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.darkBorderPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.assignment_outlined,
                          size: 18,
                          color: AppColors.textOnDarkTertiary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.vehicle_doc_soat_label,
                              style: const TextStyle(
                                color: AppColors.textOnDarkTertiary,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (soat != null) ...[
                              if (soat.insurer != null)
                                Text(
                                  soat.insurer!,
                                  style: const TextStyle(
                                    color: AppColors.textOnDarkPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Text(
                                context.l10n.vehicle_doc_expires_on(
                                  DateFormat.yMMMd('es').format(soat.expiryDate),
                                ),
                                style: const TextStyle(
                                  color: AppColors.textOnDarkTertiary,
                                  fontSize: 11,
                                ),
                              ),
                            ] else
                              Text(
                                context.l10n.vehicle_soat_tap_to_add,
                                style: const TextStyle(
                                  color: AppColors.textOnDarkSecondary,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              final soatStatus = soat?.status;
              final statusColor = _statusColor(soatStatus);

              return InkWell(
                onTap: () => _onTap(context, state),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.assignment_outlined,
                          size: 18,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.vehicle_doc_soat_label,
                              style: const TextStyle(
                                color: AppColors.textOnDarkTertiary,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _statusLabel(context, soatStatus),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (soat?.expiryDate != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                soatStatus == SoatStatus.expired
                                    ? context.l10n.soat_expired_days_ago(
                                        soat!.daysUntilExpiry.abs(),
                                      )
                                    : context.l10n.vehicle_doc_expires_on(
                                        DateFormat.yMMMd(
                                          'es',
                                        ).format(soat!.expiryDate),
                                      ),
                                style: const TextStyle(
                                  color: AppColors.textOnDarkTertiary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.textOnDarkTertiary,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RtmDocumentCardBody extends StatelessWidget {
  const _RtmDocumentCardBody({required this.vehicle, this.isArchived = false});

  final VehicleModel vehicle;
  final bool isArchived;

  Future<void> _onTap(BuildContext context) async {
    await context.pushNamed(AppRoutes.tecnomecanicaStatus, extra: vehicle);
    if (context.mounted) {
      context.read<TecnomecanicaCubit>().load(vehicle.id ?? '');
    }
  }

  Color _statusColor(VehicleDocumentStatus? status) {
    return switch (status) {
      VehicleDocumentStatus.valid => AppColors.statusGreen,
      VehicleDocumentStatus.expiringSoon => AppColors.statusWarning,
      VehicleDocumentStatus.expired => AppColors.statusError,
      _ => AppColors.textOnDarkSecondary,
    };
  }

  String _statusLabel(BuildContext context, VehicleDocumentStatus? status) {
    return switch (status) {
      VehicleDocumentStatus.valid => context.l10n.vehicle_doc_rtm_status_valid,
      VehicleDocumentStatus.expiringSoon =>
        context.l10n.vehicle_doc_rtm_status_expiring_soon,
      VehicleDocumentStatus.expired =>
        context.l10n.vehicle_doc_rtm_status_expired,
      _ => context.l10n.tecnomecanica_status_no_rtm,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.build_circle_outlined,
                  size: 14,
                  color: AppColors.textOnDarkTertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.vehicle_doc_techreview_label.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textOnDarkTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.darkBorderPrimary,
          ),
          BlocBuilder<TecnomecanicaCubit, ResultState<TecnomecanicaModel>>(
            builder: (context, state) {
              if (state is Initial || state is Loading) {
                return const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    height: 36,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                );
              }

              final rtm = state is Data<TecnomecanicaModel> ? state.data : null;

              if (isArchived) {
                return Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.darkBorderPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.assignment_outlined,
                          size: 18,
                          color: AppColors.textOnDarkTertiary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.vehicle_doc_techreview_label,
                              style: const TextStyle(
                                color: AppColors.textOnDarkTertiary,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (rtm != null) ...[
                              Text(
                                rtm.cdaName,
                                style: const TextStyle(
                                  color: AppColors.textOnDarkPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                context.l10n.vehicle_doc_expires_on(
                                  DateFormat.yMMMd('es').format(rtm.expiryDate),
                                ),
                                style: const TextStyle(
                                  color: AppColors.textOnDarkTertiary,
                                  fontSize: 11,
                                ),
                              ),
                            ] else
                              Text(
                                context.l10n.tecnomecanica_status_no_rtm,
                                style: const TextStyle(
                                  color: AppColors.textOnDarkSecondary,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              final rtmStatus = rtm?.documentStatus;
              final statusColor = _statusColor(rtmStatus);

              return InkWell(
                onTap: () => _onTap(context),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.assignment_outlined,
                          size: 18,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.vehicle_doc_techreview_label,
                              style: const TextStyle(
                                color: AppColors.textOnDarkTertiary,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _statusLabel(context, rtmStatus),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (rtm?.expiryDate != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                rtmStatus == VehicleDocumentStatus.expired
                                    ? context.l10n
                                          .tecnomecanica_expired_days_ago(
                                            rtm!.daysUntilExpiry.abs(),
                                          )
                                    : context.l10n.vehicle_doc_expires_on(
                                        DateFormat.yMMMd(
                                          'es',
                                        ).format(rtm!.expiryDate),
                                      ),
                                style: const TextStyle(
                                  color: AppColors.textOnDarkTertiary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.textOnDarkTertiary,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
