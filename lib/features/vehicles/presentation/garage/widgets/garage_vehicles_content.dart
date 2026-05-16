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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
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
                    const SizedBox(height: 20),
                    _MaintenanceWidget(
                      vehicle: mainVehicle,
                      onViewHistoryTap: () => context.pushNamed(
                        AppRoutes.maintenances,
                        extra: mainVehicle.id,
                      ),
                    ),
                    if (otherVehicles.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _OtherVehiclesSectionHeader(count: otherVehicles.length),
                      const SizedBox(height: 12),
                      ...otherVehicles.map(
                        (vehicle) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _OtherVehicleItem(
                            vehicle: vehicle,
                            onTap: () => onSelectVehicle(vehicle),
                            onOptionsTap: () => GarageOptionsBottomSheet.show(
                              context,
                              vehicle,
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

typedef _HealthCounts = ({int overdue, int upcoming, int onTime});

class _MainVehicleCard extends StatefulWidget {
  const _MainVehicleCard({
    required this.vehicle,
    required this.onTap,
    required this.onOptionsTap,
  });

  final VehicleModel vehicle;
  final VoidCallback onTap;
  final VoidCallback onOptionsTap;

  @override
  State<_MainVehicleCard> createState() => _MainVehicleCardState();
}

class _MainVehicleCardState extends State<_MainVehicleCard> {
  bool _healthExpanded = true;
  late final Future<_HealthCounts> _healthFuture;

  @override
  void initState() {
    super.initState();
    _healthFuture = _loadHealthCounts();
  }

  Future<_HealthCounts> _loadHealthCounts() async {
    final vehicleId = widget.vehicle.id;
    if (vehicleId == null) return (overdue: 0, upcoming: 0, onTime: 0);

    final useCase = getIt<GetMaintenancesByVehicleIdUseCase>();
    final result = await useCase.execute(vehicleId);

    return result.fold(
      (_) => (overdue: 0, upcoming: 0, onTime: 0),
      (page) {
        final scheduled = page.items.where((m) => m.mode == MaintenanceMode.scheduled).toList();
        var overdue = 0;
        var upcoming = 0;
        var onTime = 0;
        for (final m in scheduled) {
          final status = MaintenanceModel.calculateStatus(m, widget.vehicle.currentMileage);
          if (status == MaintenanceStatus.overdue) {
            overdue++;
          } else if (status == MaintenanceStatus.next) {
            upcoming++;
          } else {
            onTime++;
          }
        }
        return (overdue: overdue, upcoming: upcoming, onTime: onTime);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorderPrimary),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            _VehicleImageSection(
              vehicle: widget.vehicle,
              onOptionsTap: widget.onOptionsTap,
            ),
            _VehicleContentSection(
              vehicle: widget.vehicle,
              healthFuture: _healthFuture,
              healthExpanded: _healthExpanded,
              onToggleHealth: () => setState(() => _healthExpanded = !_healthExpanded),
              onDetailTap: widget.onTap,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Image Section ───────────────────────────────────────────────────────────

class _VehicleImageSection extends StatelessWidget {
  const _VehicleImageSection({required this.vehicle, required this.onOptionsTap});

  final VehicleModel vehicle;
  final VoidCallback onOptionsTap;

  String get _subtitle {
    final brandModel = [
      if (vehicle.brand != null) vehicle.brand!,
      if (vehicle.model != null) vehicle.model!,
    ].join(' ');
    final parts = <String>[];
    if (brandModel.isNotEmpty) parts.add(brandModel);
    if (vehicle.year != null) parts.add('${vehicle.year}');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _subtitle;
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: AppColors.darkBgSecondary)),
          if (vehicle.imageUrl != null)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: vehicle.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) => const _VehiclePlaceholder(),
                errorWidget: (_, _, _) => const _VehiclePlaceholder(),
              ),
            )
          else
            const Positioned.fill(child: _VehiclePlaceholder()),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: _MainBadge(label: context.l10n.garage_mainVehicleBadge),
          ),
          Positioned(
            top: 12,
            right: 14,
            child: GestureDetector(
              onTap: onOptionsTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.more_horiz, size: 16, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            top: 122,
            left: 20,
            right: 60,
            child: Text(
              vehicle.name,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (subtitle.isNotEmpty)
            Positioned(
              top: 156,
              left: 20,
              right: 20,
              child: Opacity(
                opacity: 0.9,
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textOnDarkPrimary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MainBadge extends StatelessWidget {
  const _MainBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.darkBgPrimary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.darkBgPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

// ─── Content Section ─────────────────────────────────────────────────────────

class _VehicleContentSection extends StatelessWidget {
  const _VehicleContentSection({
    required this.vehicle,
    required this.healthFuture,
    required this.healthExpanded,
    required this.onToggleHealth,
    required this.onDetailTap,
  });

  final VehicleModel vehicle;
  final Future<_HealthCounts> healthFuture;
  final bool healthExpanded;
  final VoidCallback onToggleHealth;
  final VoidCallback onDetailTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlateOdoRow(vehicle: vehicle),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: AppColors.darkBorderPrimary),
          const SizedBox(height: 16),
          _HealthSection(
            vehicle: vehicle,
            healthFuture: healthFuture,
            isExpanded: healthExpanded,
            onToggle: onToggleHealth,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: AppColors.darkBorderPrimary),
          const SizedBox(height: 16),
          _DetailFooter(onTap: onDetailTap),
        ],
      ),
    );
  }
}

class _PlateOdoRow extends StatelessWidget {
  const _PlateOdoRow({required this.vehicle});

  final VehicleModel vehicle;

  String _formatKm(int km) => km.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (vehicle.licensePlate != null)
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                vehicle.licensePlate!,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        Row(
          children: [
            const Icon(Icons.speed, size: 16, color: AppColors.textOnDarkSecondary),
            const SizedBox(width: 6),
            Text(
              '${_formatKm(vehicle.currentMileage)} km',
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              context.l10n.garage_odometerLabel,
              style: const TextStyle(
                color: AppColors.textOnDarkTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Health Section ──────────────────────────────────────────────────────────

class _HealthSection extends StatelessWidget {
  const _HealthSection({
    required this.vehicle,
    required this.healthFuture,
    required this.isExpanded,
    required this.onToggle,
  });

  final VehicleModel vehicle;
  final Future<_HealthCounts> healthFuture;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HealthCounts>(
      future: healthFuture,
      builder: (context, snapshot) {
        final counts = snapshot.data ?? (overdue: 0, upcoming: 0, onTime: 0);
        final total = counts.overdue + counts.upcoming + counts.onTime;

        return Column(
          children: [
            _HealthHeader(
              total: total,
              isExpanded: isExpanded,
              onTap: onToggle,
            ),
            if (isExpanded) ...[
              const SizedBox(height: 12),
              _HealthCountersRow(counts: counts),
            ],
          ],
        );
      },
    );
  }
}

class _HealthHeader extends StatelessWidget {
  const _HealthHeader({
    required this.total,
    required this.isExpanded,
    required this.onTap,
  });

  final int total;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.darkBgSecondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, size: 16, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  context.l10n.garage_healthHeader,
                  style: const TextStyle(
                    color: AppColors.textOnDarkPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  context.l10n.garage_healthServicesCount(total),
                  style: const TextStyle(
                    color: AppColors.textOnDarkTertiary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18,
                  color: AppColors.textOnDarkSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthCountersRow extends StatelessWidget {
  const _HealthCountersRow({required this.counts});

  final _HealthCounts counts;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HealthCounter(
            count: counts.overdue,
            label: context.l10n.garage_healthOverdue,
            color: AppColors.error,
            backgroundColor: const Color(0x14EF4444),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _HealthCounter(
            count: counts.upcoming,
            label: context.l10n.garage_healthUpcoming,
            color: const Color(0xFFEAB308),
            backgroundColor: const Color(0x14EAB308),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _HealthCounter(
            count: counts.onTime,
            label: context.l10n.garage_upToDate,
            color: const Color(0xFF22C55E),
            backgroundColor: const Color(0x1422C55E),
          ),
        ),
      ],
    );
  }
}

class _HealthCounter extends StatelessWidget {
  const _HealthCounter({
    required this.count,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final int count;
  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailFooter extends StatelessWidget {
  const _DetailFooter({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.touch_app, size: 14, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  context.l10n.garage_tapForDetail,
                  style: const TextStyle(
                    color: AppColors.textOnDarkSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  context.l10n.garage_seeDetail,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 14, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Maintenance Widget ──────────────────────────────────────────────────────

typedef _MaintenanceSummary = ({MaintenanceModel? last, MaintenanceModel? next});

class _MaintenanceWidget extends StatelessWidget {
  const _MaintenanceWidget({required this.vehicle, required this.onViewHistoryTap});

  final VehicleModel vehicle;
  final VoidCallback onViewHistoryTap;

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
            return (a.nextOdometer ?? 0).compareTo(b.nextOdometer ?? 0);
          });

        return (last: completed.firstOrNull, next: scheduled.firstOrNull);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          label: context.l10n.maintenance_maintenances.toUpperCase(),
          accentColor: AppColors.primary,
        ),
        const SizedBox(height: 12),
        FutureBuilder<_MaintenanceSummary>(
          future: _loadSummary(),
          builder: (context, snapshot) {
            final last = snapshot.data?.last;
            final next = snapshot.data?.next;
            final isOverdue = next != null &&
                MaintenanceModel.calculateStatus(next, vehicle.currentMileage) ==
                    MaintenanceStatus.overdue;

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _MaintenanceCard(
                        isNext: false,
                        maintenance: last,
                        vehicle: vehicle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MaintenanceCard(
                        isNext: true,
                        maintenance: next,
                        vehicle: vehicle,
                        isOverdue: isOverdue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ViewHistoryButton(onTap: onViewHistoryTap),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({
    required this.isNext,
    required this.maintenance,
    required this.vehicle,
    this.isOverdue = false,
  });

  final bool isNext;
  final MaintenanceModel? maintenance;
  final VehicleModel vehicle;
  final bool isOverdue;

  String _formatKm(int km) => km.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  String _formatDate(DateTime date) => DateFormat('MMM yyyy', 'es').format(date);

  String get _dateText {
    if (maintenance == null) return '—';
    if (isNext) {
      final date = maintenance!.nextDate;
      return date != null ? _formatDate(date) : '—';
    }
    final date = maintenance!.serviceDate;
    return date != null ? _formatDate(date) : '—';
  }

  String get _valueText {
    if (maintenance == null) return '—';
    if (isNext) {
      final km = maintenance!.nextOdometer;
      if (km != null) return '${_formatKm(km)} km';
      final date = maintenance!.nextDate;
      return date != null ? DateFormat('d MMM. yyyy', 'es').format(date) : '—';
    }
    final km = maintenance!.odometerAtService;
    if (km != null) return '${_formatKm(km)} km';
    final date = maintenance!.serviceDate;
    return date != null ? DateFormat('d MMM. yyyy', 'es').format(date) : '—';
  }

  Color get _cardBg {
    if (!isNext) return AppColors.darkCard;
    return isOverdue ? const Color(0x1AEF4444) : const Color(0x0FEAB308);
  }

  Color get _cardBorder {
    if (!isNext) return AppColors.darkBorderPrimary;
    return isOverdue ? const Color(0x40EF4444) : const Color(0x30EAB308);
  }

  Color get _iconColor {
    if (!isNext) return AppColors.primary;
    return isOverdue ? AppColors.error : const Color(0xFFEAB308);
  }

  Color get _iconBg {
    if (!isNext) return AppColors.primarySubtle;
    return isOverdue ? const Color(0x20EF4444) : const Color(0x20EAB308);
  }

  Color get _dotColor {
    if (!isNext) return const Color(0xFF22C55E);
    return isOverdue ? AppColors.error : const Color(0xFFEAB308);
  }

  Color get _valueColor {
    if (!isNext) return AppColors.textOnDarkSecondary;
    return isOverdue ? AppColors.error : const Color(0xFFEAB308);
  }

  @override
  Widget build(BuildContext context) {
    final topLabel = isNext
        ? context.l10n.garage_nextService
        : context.l10n.garage_lastService;

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: _dotColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    topLabel,
                    style: TextStyle(
                      color: _dotColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                _dateText,
                style: const TextStyle(
                  color: AppColors.textOnDarkTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _iconBg,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Icon(
              isNext ? Icons.build : Icons.water_drop,
              size: 18,
              color: _iconColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            maintenance?.name ?? '—',
            style: const TextStyle(
              color: AppColors.textOnDarkPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Text(
            _valueText,
            style: TextStyle(
              color: _valueColor,
              fontSize: 12,
              fontWeight: isNext ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewHistoryButton extends StatelessWidget {
  const _ViewHistoryButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.darkBorderPrimary),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.list, size: 16, color: AppColors.textOnDarkPrimary),
            const SizedBox(width: 8),
            Text(
              context.l10n.garage_viewMaintenanceHistory,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.textOnDarkTertiary),
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.accentColor});

  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textOnDarkSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ─── Other Vehicles ──────────────────────────────────────────────────────────

class _OtherVehiclesSectionHeader extends StatelessWidget {
  const _OtherVehiclesSectionHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.textOnDarkSecondary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          context.l10n.garage_otherVehiclesSection,
          style: const TextStyle(
            color: AppColors.textOnDarkSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkBorderPrimary),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: AppColors.textOnDarkSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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

  String _formatKm(int km) => km.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  @override
  Widget build(BuildContext context) {
    final plateYear = [
      if (vehicle.licensePlate != null) vehicle.licensePlate!,
      if (vehicle.year != null) '${vehicle.year}',
    ].join(' · ');
    final km = '${_formatKm(vehicle.currentMileage)} km';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorderPrimary),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.darkTertiary,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.two_wheeler,
                size: 22,
                color: AppColors.textOnDarkSecondary,
              ),
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
                  Row(
                    children: [
                      if (plateYear.isNotEmpty) ...[
                        Flexible(
                          child: Text(
                            plateYear,
                            style: const TextStyle(
                              color: AppColors.textOnDarkSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '·',
                          style: TextStyle(
                            color: AppColors.textOnDarkTertiary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        km,
                        style: const TextStyle(
                          color: AppColors.textOnDarkTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _VehicleStatusBadge(vehicle: vehicle),
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right, size: 16, color: AppColors.textOnDarkTertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleStatusBadge extends StatelessWidget {
  const _VehicleStatusBadge({required this.vehicle});

  final VehicleModel vehicle;

  Future<int> _loadScheduledCount() async {
    final vehicleId = vehicle.id;
    if (vehicleId == null) return 0;

    final useCase = getIt<GetMaintenancesByVehicleIdUseCase>();
    final result = await useCase.execute(vehicleId);

    return result.fold(
      (_) => 0,
      (page) => page.items.where((m) => m.mode == MaintenanceMode.scheduled).length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _loadScheduledCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        final isUpToDate = count == 0;

        final dotColor = isUpToDate ? const Color(0xFF22C55E) : const Color(0xFFEAB308);
        final badgeBg = isUpToDate ? const Color(0x2022C55E) : const Color(0x20EAB308);
        final label = isUpToDate
            ? context.l10n.garage_upToDate
            : context.l10n.garage_upcomingCount(count);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: dotColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
