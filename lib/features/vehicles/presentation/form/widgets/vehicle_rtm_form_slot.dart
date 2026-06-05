import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';
import 'package:rideglory/features/tecnomecanica/domain/usecases/get_tecnomecanica_usecase.dart';
import 'package:rideglory/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit.dart';
import 'package:rideglory/features/tecnomecanica/presentation/pages/tecnomecanica_manual_capture_params.dart';
import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_status.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/shared/router/app_routes.dart';

/// Slot del formulario de edición de vehículo para la RTM.
///
/// Carga el estado real de la RTM desde la API, muestra la píldora de estado
/// y navega a la pantalla correcta al tocarlo. Se refresca automáticamente
/// al regresar de cualquier pantalla de RTM.
///
/// Solo se usa cuando el vehículo ya existe (tiene `id`).
class VehicleRtmFormSlot extends StatefulWidget {
  const VehicleRtmFormSlot({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  State<VehicleRtmFormSlot> createState() => _VehicleRtmFormSlotState();
}

class _VehicleRtmFormSlotState extends State<VehicleRtmFormSlot> {
  TecnomecanicaModel? _rtm;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRtm();
  }

  Future<void> _loadRtm() async {
    final result = await getIt<GetTecnomecanicaUseCase>()(
      widget.vehicle.id!,
    );
    if (mounted) {
      setState(() {
        _rtm = result.fold((_) => null, (rtm) => rtm);
        _loading = false;
      });
    }
  }

  Future<void> _onTap() async {
    if (_rtm != null) {
      await context.pushNamed(
        AppRoutes.tecnomecanicaStatus,
        extra: widget.vehicle,
      );
    } else {
      final cubit = getIt<TecnomecanicaCubit>()..load(widget.vehicle.id!);
      await context.push<bool>(
        AppRoutes.tecnomecanicaManualCapture,
        extra: TecnomecanicaManualCaptureParams(
          cubit: cubit,
          vehicle: widget.vehicle,
        ),
      );
    }
    if (mounted) {
      setState(() {
        _loading = true;
        _rtm = null;
      });
      _loadRtm();
    }
  }

  Color _statusColor() {
    return switch (_rtm?.documentStatus) {
      VehicleDocumentStatus.valid => AppColors.success,
      VehicleDocumentStatus.expiringSoon => AppColors.warning,
      VehicleDocumentStatus.expired => AppColors.error,
      _ => AppColors.textOnDarkSecondary,
    };
  }

  String _statusLabel(BuildContext context) {
    return switch (_rtm?.documentStatus) {
      VehicleDocumentStatus.valid =>
        context.l10n.vehicle_doc_rtm_status_valid,
      VehicleDocumentStatus.expiringSoon =>
        context.l10n.vehicle_doc_rtm_status_expiring_soon,
      VehicleDocumentStatus.expired =>
        context.l10n.vehicle_doc_rtm_status_expired,
      _ => context.l10n.tecnomecanica_status_no_rtm,
    };
  }

  String? _expiryLabel(BuildContext context) {
    if (_rtm == null) return null;
    final days = _rtm!.daysUntilExpiry;
    return switch (_rtm!.documentStatus) {
      VehicleDocumentStatus.expired =>
        context.l10n.tecnomecanica_expired_days_ago(days.abs()),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorderPrimary),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final statusColor = _statusColor();
    final expiryLabel = _expiryLabel(context);

    return GestureDetector(
      onTap: _onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorderPrimary),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.build_outlined,
                size: 20,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnDarkPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _statusLabel(context),
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (expiryLabel != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      expiryLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textOnDarkTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textOnDarkTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
