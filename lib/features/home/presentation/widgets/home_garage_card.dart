import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/design_system/design_system.dart';

class HomeGarageCard extends StatelessWidget {
  const HomeGarageCard({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.garage),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroImage(vehicle: vehicle),
            _VehicleInfo(vehicle: vehicle),
          ],
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: vehicle.imageUrl != null
          ? CachedNetworkImage(
              imageUrl: vehicle.imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, _) => const _PlaceholderImage(),
              errorWidget: (_, _, _) => const _PlaceholderImage(),
            )
          : const _PlaceholderImage(),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

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

class _VehicleInfo extends StatelessWidget {
  const _VehicleInfo({required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vehicle.name,
            style: const TextStyle(
              color: AppColors.textOnDarkPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (vehicle.soatStatus != null || vehicle.soatExpiryDate != null) ...[
            const SizedBox(height: 8),
            _SoatBadge(vehicle: vehicle),
          ],
        ],
      ),
    );
  }
}

class _SoatBadge extends StatelessWidget {
  const _SoatBadge({required this.vehicle});

  final VehicleModel vehicle;

  Color _badgeBg() {
    return switch (vehicle.soatStatus) {
      SoatStatus.valid => AppColors.successSubtle,
      SoatStatus.expiringSoon => AppColors.warningSubtle,
      SoatStatus.expired => AppColors.errorSubtle,
      null => AppColors.infoSubtle,
    };
  }

  Color _badgeText() {
    return switch (vehicle.soatStatus) {
      SoatStatus.valid => AppColors.success,
      SoatStatus.expiringSoon => AppColors.warning,
      SoatStatus.expired => AppColors.error,
      null => AppColors.info,
    };
  }

  String _statusLabel(BuildContext context) {
    return switch (vehicle.soatStatus) {
      SoatStatus.valid => context.l10n.vehicle_doc_soat_label,
      SoatStatus.expiringSoon => context.l10n.vehicle_doc_soat_label,
      SoatStatus.expired => context.l10n.vehicle_doc_soat_label,
      null => context.l10n.vehicle_doc_soat_label,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _badgeBg(),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.description_outlined,
                size: 12,
                color: _badgeText(),
              ),
              const SizedBox(width: 4),
              Text(
                _statusLabel(context),
                style: TextStyle(
                  color: _badgeText(),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
