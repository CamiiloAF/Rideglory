import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenances_by_vehicle_id_use_case.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_empty_state.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class GarageVehiclesContent extends StatelessWidget {
  const GarageVehiclesContent({
    super.key,
    required this.loadVehicles,
    required this.onSelectVehicle,
    required this.onMaintenanceCreated,
    required this.onMaintenanceRefreshRequested,
    this.openWithVehicleId,
  });

  final Future<void> Function() loadVehicles;
  final ValueChanged<VehicleModel> onSelectVehicle;
  final ValueChanged<MaintenanceModel> onMaintenanceCreated;
  final ValueChanged<String> onMaintenanceRefreshRequested;
  final String? openWithVehicleId;

  Future<void> _addVehicle(BuildContext context) async {
    final result = await context.pushNamed(AppRoutes.createVehicle);
    if (!context.mounted || result == null) return;
    context.read<VehicleCubit>().fetchMyVehicles();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VehicleCubit>().state;
    final vehicles = state is Data<List<VehicleModel>>
        ? state.data.where((v) => !v.isArchived).toList(growable: false)
        : const <VehicleModel>[];

    if (vehicles.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.darkBgPrimary,
        body: SafeArea(
          child: Column(
            children: [
              _GarageHeader(onAdd: () => _addVehicle(context)),
              Expanded(child: GarageEmptyState(onVehicleSavedLocally: ([_]) => loadVehicles())),
            ],
          ),
        ),
      );
    }

    final mainVehicle = vehicles.firstWhere(
      (v) => v.isMainVehicle,
      orElse: () => vehicles.first,
    );
    final otherVehicles = vehicles.where((v) => v.id != mainVehicle.id).toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.darkCard,
          onRefresh: loadVehicles,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _GarageHeader(onAdd: () => _addVehicle(context))),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _MainVehicleCard(
                      vehicle: mainVehicle,
                      onTap: () => onSelectVehicle(mainVehicle),
                      onOptionsTap: () => GarageOptionsBottomSheet.show(
                        context,
                        mainVehicle,
                        onGarageListUpdatedLocally: ([_]) => loadVehicles(),
                        onMaintenanceCreated: onMaintenanceCreated,
                        onMaintenanceRefreshRequested: onMaintenanceRefreshRequested,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _StatsCards(vehicle: mainVehicle),
                    const SizedBox(height: 16),
                    _QuickActions(
                      vehicle: mainVehicle,
                      onViewMaintenancesTap: () => context.pushNamed(
                        AppRoutes.maintenances,
                        extra: mainVehicle.id,
                      ),
                      onCreateMaintenanceTap: () async {
                        final result = await context.pushNamed<dynamic>(
                          AppRoutes.createMaintenance,
                          extra: mainVehicle,
                        );
                        if (!context.mounted || result == null) return;
                        if (result is MaintenanceModel) {
                          onMaintenanceCreated(result);
                        } else if (mainVehicle.id != null) {
                          onMaintenanceRefreshRequested(mainVehicle.id!);
                        }
                      },
                    ),
                    if (otherVehicles.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const _OtherVehiclesHeader(),
                      ...otherVehicles.map(
                        (v) => Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _OtherVehicleItem(
                            vehicle: v,
                            onTap: () => onSelectVehicle(v),
                            onOptionsTap: () => GarageOptionsBottomSheet.show(
                              context,
                              v,
                              onGarageListUpdatedLocally: ([_]) => loadVehicles(),
                              onMaintenanceCreated: onMaintenanceCreated,
                              onMaintenanceRefreshRequested: onMaintenanceRefreshRequested,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────────────

class _GarageHeader extends StatelessWidget {
  const _GarageHeader({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Text(
            context.l10n.vehicle_myGarage,
            style: const TextStyle(
              color: AppColors.textOnDarkPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16, color: AppColors.darkBgPrimary),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.vehicle_addShort,
                    style: const TextStyle(
                      color: AppColors.darkBgPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Main Vehicle Card ───────────────────────────────────────────────────────

class _MainVehicleCard extends StatelessWidget {
  const _MainVehicleCard({
    required this.vehicle,
    required this.onTap,
    required this.onOptionsTap,
  });

  final VehicleModel vehicle;
  final VoidCallback onTap;
  final VoidCallback onOptionsTap;

  String get _subtitle {
    final parts = <String>[];
    if (vehicle.year != null) parts.add('${vehicle.year}');
    if (vehicle.model != null) parts.add(vehicle.model!);
    if (vehicle.licensePlate != null) parts.add(vehicle.licensePlate!);
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            vehicle.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: vehicle.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const _VehiclePlaceholder(),
                    errorWidget: (_, _, _) => const _VehiclePlaceholder(),
                  )
                : const _VehiclePlaceholder(),
            // Gradient overlay
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xDD0D0D0F),
                    Color(0xFF0D0D0F),
                  ],
                  stops: [0.2, 0.75, 1.0],
                ),
              ),
            ),
            // "Moto principal" badge — top left
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 6,
                      height: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.darkBgPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Moto principal',
                      style: TextStyle(
                        color: AppColors.darkBgPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Options button — top right
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: onOptionsTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.53),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.more_horiz,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            // Bottom info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            vehicle.name,
                            style: const TextStyle(
                              color: AppColors.textOnDarkPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _subtitle,
                              style: const TextStyle(
                                color: AppColors.textOnDarkSecondary,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Row(
                      children: [
                        Text(
                          'Ver detalle',
                          style: TextStyle(
                            color: AppColors.textOnDarkSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.chevron_right, size: 14, color: AppColors.textOnDarkSecondary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehiclePlaceholder extends StatelessWidget {
  const _VehiclePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkBgSecondary,
      child: const Center(
        child: Icon(Icons.two_wheeler, size: 56, color: AppColors.darkBorderLight),
      ),
    );
  }
}

// ─── Stats Cards ─────────────────────────────────────────────────────────────

typedef _MaintenanceSummary = ({MaintenanceModel? last, MaintenanceModel? next});

class _StatsCards extends StatelessWidget {
  const _StatsCards({required this.vehicle});

  final VehicleModel vehicle;

  String _formatKm(int km) {
    return km.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  Future<_MaintenanceSummary> _loadSummary() async {
    final vehicleId = vehicle.id;
    if (vehicleId == null) return (last: null, next: null);

    final useCase = getIt<GetMaintenancesByVehicleIdUseCase>();
    final result = await useCase.execute(vehicleId);

    return result.fold(
      (_) => (last: null, next: null),
      (page) {
        final completed = page.items
            .where((m) => m.mode == MaintenanceMode.completed)
            .toList()
          ..sort((a, b) {
            final dateA = a.serviceDate ?? a.createdDate ?? DateTime(0);
            final dateB = b.serviceDate ?? b.createdDate ?? DateTime(0);
            return dateB.compareTo(dateA);
          });

        final scheduled = page.items
            .where((m) => m.mode == MaintenanceMode.scheduled)
            .toList()
          ..sort((a, b) {
            if (a.nextDate != null && b.nextDate != null) {
              return a.nextDate!.compareTo(b.nextDate!);
            }
            if (a.nextDate != null) return -1;
            if (b.nextDate != null) return 1;
            final aKm = a.nextOdometer ?? 0;
            final bKm = b.nextOdometer ?? 0;
            return aKm.compareTo(bKm);
          });

        return (last: completed.firstOrNull, next: scheduled.firstOrNull);
      },
    );
  }

  String _lastServiceValue(MaintenanceModel? m) {
    if (m == null) return '—';
    final date = m.serviceDate;
    if (date != null) return DateFormat('d MMM. yyyy', 'es').format(date);
    final km = m.odometerAtService;
    if (km != null) return '${_formatKm(km)} km';
    return '—';
  }

  String _nextServiceValue(MaintenanceModel? m) {
    if (m == null) return '—';
    final km = m.nextOdometer;
    if (km != null) return '${_formatKm(km)} km';
    final date = m.nextDate;
    if (date != null) return DateFormat('d MMM. yyyy', 'es').format(date);
    return '—';
  }

  bool _isNextOverdue(MaintenanceModel? m) {
    if (m == null) return false;
    return MaintenanceModel.calculateStatus(m, vehicle.currentMileage) ==
        MaintenanceStatus.overdue;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_MaintenanceSummary>(
      future: _loadSummary(),
      builder: (context, snapshot) {
        final last = snapshot.data?.last;
        final next = snapshot.data?.next;
        final nextOverdue = _isNextOverdue(next);

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.speed,
                iconColor: AppColors.primary,
                value: _formatKm(vehicle.currentMileage),
                label: context.l10n.home_statKmTotal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.build,
                iconColor: nextOverdue ? AppColors.error : const Color(0xFFEAB308),
                value: _nextServiceValue(next),
                label: context.l10n.home_statPromService,
                backgroundColor: nextOverdue ? const Color(0x1AEF4444) : null,
                borderColor: nextOverdue ? const Color(0x40EF4444) : null,
                valueColor: nextOverdue ? AppColors.error : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_today,
                iconColor: AppColors.info,
                value: _lastServiceValue(last),
                label: context.l10n.home_statLastService,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.backgroundColor,
    this.borderColor,
    this.valueColor,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textOnDarkPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textOnDarkTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions ───────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.vehicle,
    required this.onViewMaintenancesTap,
    required this.onCreateMaintenanceTap,
  });

  final VehicleModel vehicle;
  final VoidCallback onViewMaintenancesTap;
  final VoidCallback onCreateMaintenanceTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionBtn(
            icon: Icons.build_outlined,
            label: context.l10n.home_vehicleMaintenance,
            onTap: onViewMaintenancesTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBtn(
            icon: Icons.add_circle_outline,
            label: context.l10n.vehicle_addMaintenance,
            onTap: onCreateMaintenanceTap,
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.darkBorderPrimary),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Other Vehicles ──────────────────────────────────────────────────────────

class _OtherVehiclesHeader extends StatelessWidget {
  const _OtherVehiclesHeader();

  @override
  Widget build(BuildContext context) {
    return Text(
      context.l10n.vehicle_otherVehicles,
      style: const TextStyle(
        color: AppColors.textOnDarkPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _OtherVehicleItem extends StatelessWidget {
  const _OtherVehicleItem({
    required this.vehicle,
    required this.onTap,
    required this.onOptionsTap,
  });

  final VehicleModel vehicle;
  final VoidCallback onTap;
  final VoidCallback onOptionsTap;

  String _formatKm(int km) {
    return km.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  String get _subtitle {
    final parts = <String>[];
    if (vehicle.year != null) parts.add('${vehicle.year}');
    if (vehicle.model != null) parts.add(vehicle.model!);
    parts.add('${_formatKm(vehicle.currentMileage)} km');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorderPrimary),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.darkBgSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.hardEdge,
              child: vehicle.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: vehicle.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const _SmallPlaceholder(),
                      errorWidget: (_, _, _) => const _SmallPlaceholder(),
                    )
                  : const _SmallPlaceholder(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.name,
                    style: const TextStyle(
                      color: AppColors.textOnDarkPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitle,
                    style: const TextStyle(
                      color: AppColors.textOnDarkTertiary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textOnDarkTertiary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SmallPlaceholder extends StatelessWidget {
  const _SmallPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.two_wheeler, size: 24, color: AppColors.darkBorderLight);
  }
}
