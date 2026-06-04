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
import 'package:rideglory/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit.dart';
import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_kind.dart';
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
  });

  final VehicleDocumentKind kind;
  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      VehicleDocumentKind.soat => BlocProvider(
        create: (_) => getIt<SoatCubit>()..load(vehicle.id ?? ''),
        child: _SoatDocumentCardBody(vehicle: vehicle),
      ),
      VehicleDocumentKind.rtm => BlocProvider(
        create: (_) => getIt<TecnomecanicaCubit>()..load(vehicle.id ?? ''),
        child: _RtmDocumentCardBody(vehicle: vehicle),
      ),
    };
  }
}

class _SoatDocumentCardBody extends StatelessWidget {
  const _SoatDocumentCardBody({required this.vehicle});

  final VehicleModel vehicle;

  Future<void> _onTap(BuildContext context, ResultState<SoatModel> state) async {
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
      SoatStatus.expired => context.l10n.maintenance_expired_label,
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
                                context.l10n.vehicle_doc_expires_on(
                                  DateFormat.yMMMd('es').format(soat!.expiryDate),
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
  const _RtmDocumentCardBody({required this.vehicle});

  final VehicleModel vehicle;

  Future<void> _onTap(BuildContext context) async {
    await context.pushNamed(
      AppRoutes.tecnomecanicaStatus,
      extra: vehicle,
    );
    if (context.mounted) {
      context.read<TecnomecanicaCubit>().load(vehicle.id ?? '');
    }
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
      child: InkWell(
        onTap: () => _onTap(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.textOnDarkSecondary.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  size: 18,
                  color: AppColors.textOnDarkSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.tecnomecanica_page_status_title,
                      style: const TextStyle(
                        color: AppColors.textOnDarkTertiary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.tecnomecanica_status_no_rtm,
                      style: const TextStyle(
                        color: AppColors.textOnDarkSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
      ),
    );
  }
}
