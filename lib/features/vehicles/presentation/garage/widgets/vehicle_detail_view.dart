import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_maintenance_history_section.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_soat_card.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class VehicleDetailView extends StatelessWidget {
  const VehicleDetailView({
    super.key,
    required this.vehicle,
    required this.onBack,
    required this.maintenanceRefreshTick,
    required this.onPendingMaintenanceConsumed,
    required this.onMaintenanceCreated,
    required this.onMaintenanceRefreshRequested,
    this.pendingCreatedMaintenance,
    this.onVehicleUpdated,
  });

  final VehicleModel vehicle;
  final VoidCallback onBack;
  final int maintenanceRefreshTick;
  final MaintenanceModel? pendingCreatedMaintenance;
  final void Function(String vehicleId) onPendingMaintenanceConsumed;
  final ValueChanged<MaintenanceModel> onMaintenanceCreated;
  final ValueChanged<String> onMaintenanceRefreshRequested;
  final ValueChanged<VehicleModel>? onVehicleUpdated;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _DetailNav(vehicle: vehicle, onBack: onBack),
          ),
          SliverToBoxAdapter(
            child: _HeroImage(vehicle: vehicle),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _TopRow(vehicle: vehicle),
                const SizedBox(height: 16),
                if (vehicle.licensePlate != null || vehicle.vin != null) ...[
                  _IdentificationCard(vehicle: vehicle),
                  const SizedBox(height: 16),
                ],
                _SpecsCard(vehicle: vehicle),
                const SizedBox(height: 16),
                VehicleSoatCard(vehicle: vehicle),
                const SizedBox(height: 16),
                VehicleMaintenanceHistorySection(
                  vehicle: vehicle,
                  maintenanceRefreshTick: maintenanceRefreshTick,
                  pendingCreatedMaintenance: pendingCreatedMaintenance,
                  onPendingMaintenanceConsumed: onPendingMaintenanceConsumed,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nav Header ──────────────────────────────────────────────────────────────

class _DetailNav extends StatelessWidget {
  const _DetailNav({required this.vehicle, required this.onBack});

  final VehicleModel vehicle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _NavButton(icon: Icons.arrow_back, onTap: onBack),
              Expanded(
                child: Text(
                  vehicle.name,
                  style: const TextStyle(
                    color: AppColors.textOnDarkPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _NavButton(
                icon: Icons.edit_outlined,
                onTap: () => context.pushNamed(AppRoutes.editVehicle, extra: vehicle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.darkBgSecondary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: AppColors.textOnDarkPrimary),
      ),
    );
  }
}

// ─── Hero Image ──────────────────────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          vehicle.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: vehicle.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const _ImagePlaceholder(),
                  errorWidget: (_, _, _) => const _ImagePlaceholder(),
                )
              : const _ImagePlaceholder(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0xCC0D0D0F),
                  Color(0xFF0D0D0F),
                ],
                stops: [0.3, 0.8, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkBgSecondary,
      child: const Center(
        child: Icon(Icons.two_wheeler, size: 64, color: AppColors.darkBorderLight),
      ),
    );
  }
}

// ─── Top Row (badge + subtitle) ──────────────────────────────────────────────

class _TopRow extends StatelessWidget {
  const _TopRow({required this.vehicle});

  final VehicleModel vehicle;

  String get _subtitle {
    final parts = <String>[];
    if (vehicle.year != null) parts.add('${vehicle.year}');
    if (vehicle.model != null) parts.add(vehicle.model!);
    if (vehicle.licensePlate != null) parts.add(vehicle.licensePlate!);
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (vehicle.isMainVehicle) ...[
          _MainBadge(),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            _subtitle,
            style: const TextStyle(
              color: AppColors.textOnDarkSecondary,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MainBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
    );
  }
}

// ─── Identification Card ─────────────────────────────────────────────────────

class _IdentificationCard extends StatelessWidget {
  const _IdentificationCard({required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    final plate = vehicle.licensePlate;
    final vin = vehicle.vin;

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
          _CardHeader(
            icon: Icons.badge_outlined,
            label: context.l10n.vehicle_identification,
          ),
          if (plate != null) ...[
            _IdentificationRow(
              iconBg: AppColors.primarySubtle,
              icon: Icons.directions_car_outlined,
              iconColor: AppColors.primary,
              label: context.l10n.vehicle_plate,
              child: Text(
                plate,
                style: const TextStyle(
                  color: AppColors.textOnDarkPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
          if (plate != null && vin != null)
            const _RowDivider(),
          if (vin != null)
            _IdentificationRow(
              iconBg: AppColors.darkTertiary,
              icon: Icons.numbers,
              iconColor: AppColors.textOnDarkSecondary,
              label: context.l10n.vehicle_vinLabel,
              trailing: _CopyButton(text: vin),
              child: Text(
                vin,
                style: const TextStyle(
                  color: AppColors.textOnDarkPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IdentificationRow extends StatelessWidget {
  const _IdentificationRow({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.child,
    this.trailing,
  });

  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textOnDarkTertiary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                child,
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Clipboard.setData(ClipboardData(text: text)),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.darkTertiary,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.content_copy, size: 14, color: AppColors.textOnDarkSecondary),
      ),
    );
  }
}

// ─── Specs Card ──────────────────────────────────────────────────────────────

class _SpecsCard extends StatelessWidget {
  const _SpecsCard({required this.vehicle});

  final VehicleModel vehicle;

  String _formatKm(int km) =>
      NumberFormat('#,###').format(km).replaceAll(',', '.');

  @override
  Widget build(BuildContext context) {
    final rows = <_SpecRowData>[
      if (vehicle.brand != null)
        _SpecRowData(label: context.l10n.vehicle_specBrand, value: vehicle.brand!),
      if (vehicle.model != null)
        _SpecRowData(label: context.l10n.vehicle_specModel, value: vehicle.model!),
      if (vehicle.year != null)
        _SpecRowData(label: context.l10n.vehicle_specYear, value: '${vehicle.year}'),
      _SpecRowData(
        label: context.l10n.vehicle_currentMileageLabel,
        value: '${_formatKm(vehicle.currentMileage)} km',
      ),
      if (vehicle.purchaseDate != null)
        _SpecRowData(
          label: context.l10n.vehicle_specPurchaseDate,
          value: DateFormat.yMMMd('es').format(vehicle.purchaseDate!),
        ),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

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
          _CardHeader(icon: Icons.settings_outlined, label: context.l10n.vehicle_specs),
          ...rows.asMap().entries.map((entry) {
            final isLast = entry.key == rows.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.value.label,
                        style: const TextStyle(
                          color: AppColors.textOnDarkSecondary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        entry.value.value,
                        style: const TextStyle(
                          color: AppColors.textOnDarkPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast) const _RowDivider(),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _SpecRowData {
  const _SpecRowData({required this.label, required this.value});
  final String label;
  final String value;
}

// ─── Shared card components ───────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textOnDarkTertiary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textOnDarkTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.darkBorderPrimary);
  }
}
