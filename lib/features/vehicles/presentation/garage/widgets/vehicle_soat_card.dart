import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/soat/domain/usecases/delete_soat_usecase.dart';
import 'package:rideglory/features/soat/domain/usecases/get_soat_usecase.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class VehicleSoatCard extends StatefulWidget {
  const VehicleSoatCard({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  State<VehicleSoatCard> createState() => _VehicleSoatCardState();
}

class _VehicleSoatCardState extends State<VehicleSoatCard> {
  SoatModel? _soat;
  bool _isLoading = true;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _loadSoat();
  }

  Future<void> _loadSoat() async {
    final vehicleId = widget.vehicle.id;
    if (vehicleId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final result = await getIt<GetSoatUseCase>()(vehicleId);
    if (mounted) {
      setState(() {
        _soat = result.fold((_) => null, (soat) => soat);
        _isLoading = false;
      });
    }
  }

  Future<void> _onTap(BuildContext context) async {
    if (_soat != null) {
      await context.pushNamed(AppRoutes.soatStatus, extra: widget.vehicle);
    } else {
      await context.pushNamed(AppRoutes.vehicleSoat, extra: widget.vehicle);
    }
    if (mounted) {
      setState(() => _isLoading = true);
      _loadSoat();
    }
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final vehicleId = widget.vehicle.id;
    if (vehicleId == null) return;

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
    final result = await getIt<DeleteSoatUseCase>()(vehicleId);
    if (!mounted) return;

    result.fold(
      (_) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorOccurred)),
        );
      },
      (_) {
        context.read<VehicleCubit>().clearSoatLocally(vehicleId);
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

  @override
  Widget build(BuildContext context) {
    final soatStatus = _soat?.status;

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
          InkWell(
            onTap: _isLoading ? null : () => _onTap(context),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: _isLoading
                  ? const SizedBox(
                      height: 36,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _statusColor(soatStatus).withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.assignment_outlined,
                            size: 18,
                            color: _statusColor(soatStatus),
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
                                  color: _statusColor(soatStatus),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_soat?.expiryDate != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Vence ${DateFormat.yMMMd('es').format(_soat!.expiryDate)}',
                                  style: const TextStyle(
                                    color: AppColors.textOnDarkTertiary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (_soat != null) ...[
                          GestureDetector(
                            onTap: _deleting
                                ? null
                                : () => _confirmAndDelete(context),
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
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.textOnDarkTertiary,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(SoatStatus? status) {
    switch (status) {
      case SoatStatus.valid:
        return AppColors.statusGreen;
      case SoatStatus.expiringSoon:
        return AppColors.statusWarning;
      case SoatStatus.expired:
        return AppColors.statusError;
      case SoatStatus.noSoat:
      case null:
        return AppColors.textOnDarkSecondary;
    }
  }

  String _statusLabel(BuildContext context, SoatStatus? status) {
    switch (status) {
      case SoatStatus.valid:
        return 'Vigente';
      case SoatStatus.expiringSoon:
        return 'Por vencer';
      case SoatStatus.expired:
        return context.l10n.maintenance_expired_label;
      case SoatStatus.noSoat:
      case null:
        return context.l10n.vehicle_soat_tap_to_add;
    }
  }
}
