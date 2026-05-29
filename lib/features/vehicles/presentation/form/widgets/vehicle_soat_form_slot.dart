import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/soat/domain/usecases/delete_soat_usecase.dart';
import 'package:rideglory/features/soat/domain/usecases/get_soat_usecase.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';

/// Slot del formulario de edición de vehículo para el SOAT.
///
/// Carga el estado real del SOAT desde la API, muestra la píldora de estado
/// y navega a la pantalla correcta al tocarlo. Se refresca automáticamente
/// al regresar de cualquier pantalla de SOAT.
///
/// Solo se usa cuando el vehículo ya existe (tiene `id`).
class VehicleSoatFormSlot extends StatefulWidget {
  const VehicleSoatFormSlot({super.key, required this.vehicle});

  /// Vehículo existente. Siempre tiene `id`.
  final VehicleModel vehicle;

  @override
  State<VehicleSoatFormSlot> createState() => _VehicleSoatFormSlotState();
}

class _VehicleSoatFormSlotState extends State<VehicleSoatFormSlot> {
  SoatModel? _soat;
  bool _loading = true;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _loadSoat();
  }

  Future<void> _loadSoat() async {
    final result = await getIt<GetSoatUseCase>()(widget.vehicle.id!);
    if (mounted) {
      setState(() {
        _soat = result.fold((_) => null, (soat) => soat);
        _loading = false;
      });
    }
  }

  Future<void> _onTap() async {
    final hasSoat = _soat != null && _soat!.status != SoatStatus.noSoat;
    if (hasSoat) {
      await context.pushNamed(AppRoutes.soatStatus, extra: widget.vehicle);
    } else {
      await context.pushNamed(AppRoutes.vehicleSoat, extra: widget.vehicle);
    }
    if (mounted) {
      setState(() {
        _loading = true;
        _soat = null;
      });
      _loadSoat();
    }
  }

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
    final result = await getIt<DeleteSoatUseCase>()(widget.vehicle.id!);
    if (!mounted) return;

    result.fold(
      (_) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorOccurred)),
        );
      },
      (_) {
        context.read<VehicleCubit>().clearSoatLocally(widget.vehicle.id!);
        setState(() {
          _soat = null;
          _deleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.soat_deleted_success)),
        );
      },
    );
  }

  Color _statusColor() {
    return switch (_soat?.status) {
      SoatStatus.valid => AppColors.success,
      SoatStatus.expiringSoon => AppColors.warning,
      SoatStatus.expired => AppColors.error,
      _ => AppColors.textOnDarkSecondary,
    };
  }

  String _statusLabel(BuildContext context) {
    return switch (_soat?.status) {
      SoatStatus.valid => context.l10n.soat_status_valid,
      SoatStatus.expiringSoon => context.l10n.soat_status_expiring_soon,
      SoatStatus.expired => context.l10n.soat_status_expired,
      _ => context.l10n.soat_status_no_soat,
    };
  }

  String? _expiryLabel(BuildContext context) {
    if (_soat == null) return null;
    final days = _soat!.daysUntilExpiry;
    return switch (_soat!.status) {
      SoatStatus.valid => context.l10n.soat_valid_days_remaining(days),
      SoatStatus.expiringSoon => context.l10n.soat_expiring_days_remaining(
        days,
      ),
      SoatStatus.expired => context.l10n.soat_expired_days_ago(days.abs()),
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
                Icons.description_outlined,
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
                    context.l10n.vehicle_doc_soat_label,
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
            if (_soat != null && _soat!.status != SoatStatus.noSoat) ...[
              GestureDetector(
                onTap: _deleting ? null : _confirmAndDelete,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.darkTertiary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _deleting
                      ? const Padding(
                          padding: EdgeInsets.all(7),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.error,
                          ),
                        )
                      : const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: AppColors.error,
                        ),
                ),
              ),
              const SizedBox(width: 10),
            ],
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
