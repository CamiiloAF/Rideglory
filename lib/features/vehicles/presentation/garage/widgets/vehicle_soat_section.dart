import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/soat/domain/usecases/get_soat_usecase.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class VehicleSoatSection extends StatefulWidget {
  const VehicleSoatSection({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  State<VehicleSoatSection> createState() => _VehicleSoatSectionState();
}

class _VehicleSoatSectionState extends State<VehicleSoatSection> {
  late Future<SoatModel?> _soatFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _soatFuture = getIt<GetSoatUseCase>()(widget.vehicle.id ?? '').then(
      (result) => result.fold((_) => null, (soat) => soat),
    );
  }

  DocumentSlotState _toSlotState(SoatStatus status) {
    return switch (status) {
      SoatStatus.noSoat => DocumentSlotState.empty,
      SoatStatus.valid => DocumentSlotState.valid,
      SoatStatus.expiringSoon => DocumentSlotState.expiringSoon,
      SoatStatus.expired => DocumentSlotState.expired,
    };
  }

  String _stateLabel(BuildContext context, SoatStatus status) {
    return switch (status) {
      SoatStatus.noSoat => context.l10n.soat_status_no_soat,
      SoatStatus.valid => context.l10n.soat_status_valid,
      SoatStatus.expiringSoon => context.l10n.soat_status_expiring_soon,
      SoatStatus.expired => context.l10n.soat_status_expired,
    };
  }

  void _onSoatTap(BuildContext context, SoatModel? soat) {
    if (soat == null) {
      context.pushNamed(AppRoutes.vehicleSoat, extra: widget.vehicle).then(
        (_) {
          if (mounted) setState(_load);
        },
      );
    } else {
      context.pushNamed(AppRoutes.soatStatus, extra: widget.vehicle).then(
        (_) {
          if (mounted) setState(_load);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SoatModel?>(
      future: _soatFuture,
      builder: (context, snapshot) {
        final soat = snapshot.data;
        final status = soat?.status ?? SoatStatus.noSoat;

        return GestureDetector(
          onTap: () => _onSoatTap(context, soat),
          child: DocumentSlotPill(
            slots: [
              DocumentSlot(
                name: context.l10n.vehicle_doc_soat_label,
                state: _toSlotState(status),
                stateLabel: _stateLabel(context, status),
                expiryLabel: soat != null
                    ? _expiryLabel(context, soat)
                    : null,
                isInfoType: true,
              ),
            ],
            totalSlots: 1,
            isOptional: false,
          ),
        );
      },
    );
  }

  String? _expiryLabel(BuildContext context, SoatModel soat) {
    final days = soat.daysUntilExpiry;
    return switch (soat.status) {
      SoatStatus.valid => context.l10n.soat_valid_days_remaining(days),
      SoatStatus.expiringSoon =>
        context.l10n.soat_expiring_days_remaining(days),
      SoatStatus.expired =>
        context.l10n.soat_expired_days_ago(days.abs()),
      SoatStatus.noSoat => null,
    };
  }
}
