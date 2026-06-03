import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/shared/helpers/url_launcher_helper.dart';
import 'package:rideglory/shared/router/app_routes.dart';

/// Card de un rider en la lista de participantes del tracking en vivo.
class RiderListItem extends StatelessWidget {
  const RiderListItem({
    super.key,
    required this.rider,
    required this.isSos,
    required this.isActive,
    required this.onLocate,
    this.phone,
    this.vehicleDisplayName,
    this.distanceFromUserMeters,
  });

  final RiderTrackingModel rider;
  final bool isSos;

  /// Effective active status: false if rider.isActive is false OR if
  /// lastUpdated is older than 1 minute.
  final bool isActive;

  final VoidCallback onLocate;

  /// Phone number from the event registration. Null if unavailable.
  final String? phone;

  /// Vehicle display name from the event registration. Null if unavailable.
  final String? vehicleDisplayName;

  /// Haversine distance from the current user's GPS to this rider (metres).
  /// Null if the current user's GPS is unavailable.
  final double? distanceFromUserMeters;

  @override
  Widget build(BuildContext context) {
    final name = rider.fullName.trim();
    final displayName = name.isEmpty ? context.l10n.map_riderRole : name;
    final hasPhone = phone != null && phone!.isNotEmpty;

    return GestureDetector(
      onTap: () => context.pushNamed(
        AppRoutes.riderProfile,
        extra: rider.userId,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSos
              ? Color.alphaBlend(
                  AppColors.error.withValues(alpha: 0.08),
                  AppColors.darkCard,
                )
              : AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSos ? AppColors.error : AppColors.darkBorderPrimary,
            width: isSos ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: Avatar + name + distance badge ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _RiderAvatar(rider: rider, isSos: isSos, isActive: isActive),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textOnDarkPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (distanceFromUserMeters != null &&
                              distanceFromUserMeters! > 0) ...[
                            AppSpacing.hGapSm,
                            _DistanceBadge(
                              distanceMeters: distanceFromUserMeters!,
                            ),
                          ],
                        ],
                      ),
                      AppSpacing.gapXxs,
                      Text(
                        vehicleDisplayName ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textOnDarkSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,
            // ── Row 2: Status ──
            _StatusRow(rider: rider, isSos: isSos, isActive: isActive),
            AppSpacing.gapMd,
            // ── Row 3: Actions ──
            isSos
                ? _SosActionsRow(onLocate: onLocate, phone: hasPhone ? phone : null)
                : _NormalActionsRow(
                    phone: hasPhone ? phone : null,
                    userId: rider.userId,
                  ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar with status dot
// ─────────────────────────────────────────────────────────────────────────────

class _RiderAvatar extends StatelessWidget {
  const _RiderAvatar({
    required this.rider,
    required this.isSos,
    required this.isActive,
  });

  final RiderTrackingModel rider;
  final bool isSos;
  final bool isActive;

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Color get _dotColor {
    if (isSos) return AppColors.error;
    return isActive ? AppColors.success : AppColors.tabInactive;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.darkTertiary,
            border: Border.all(color: AppColors.darkBorderLight),
          ),
          alignment: Alignment.center,
          child: Text(
            _initials(rider.fullName),
            style: const TextStyle(
              color: AppColors.textOnDarkPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Positioned(
          right: 1,
          bottom: 1,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _dotColor,
              border: Border.all(color: AppColors.darkCard, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Distance badge
// ─────────────────────────────────────────────────────────────────────────────

class _DistanceBadge extends StatelessWidget {
  const _DistanceBadge({required this.distanceMeters});

  final double distanceMeters;

  String get _label {
    final km = distanceMeters / 1000;
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2117),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status row
// ─────────────────────────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.rider,
    required this.isSos,
    required this.isActive,
  });

  final RiderTrackingModel rider;
  final bool isSos;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    if (isSos || !isActive) {
      final dotColor = isSos ? AppColors.error : AppColors.tabInactive;
      final textColor = isSos ? AppColors.error : AppColors.textOnDarkTertiary;
      return Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
          ),
          AppSpacing.hGapXxs,
          Text(
            context.l10n.map_stopped,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    // Active rider
    return Row(
      children: [
        const Icon(
          Icons.route_rounded,
          size: 14,
          color: AppColors.success,
        ),
        AppSpacing.hGapXxs,
        Text(
          '${rider.speedKmh.round()} km/h',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Normal rider actions row
// ─────────────────────────────────────────────────────────────────────────────

class _NormalActionsRow extends StatelessWidget {
  const _NormalActionsRow({this.phone, required this.userId});

  final String? phone;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionIconButton(
          icon: Icons.phone_rounded,
          onTap: phone != null
              ? () => UrlLauncherHelper.openPhone(phone!)
              : null,
        ),
        AppSpacing.hGapSm,
        _ActionIconButton(
          icon: Icons.chat_bubble_outline_rounded,
          onTap: phone != null
              ? () => UrlLauncherHelper.openWhatsApp(phone!)
              : null,
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => context.pushNamed(
            AppRoutes.riderProfile,
            extra: userId,
          ),
          child: Text(
            '${context.l10n.map_viewProfile} →',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SOS actions row
// ─────────────────────────────────────────────────────────────────────────────

class _SosActionsRow extends StatelessWidget {
  const _SosActionsRow({required this.onLocate, this.phone});

  final VoidCallback onLocate;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextButton(
              onPressed: phone != null
                  ? () => UrlLauncherHelper.openPhone(phone!)
                  : null,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.textOnDarkPrimary,
                disabledBackgroundColor: AppColors.error.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                '📡 ${context.l10n.map_emergencyCall}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        AppSpacing.hGapMd,
        GestureDetector(
          onTap: onLocate,
          child: Text(
            '${context.l10n.map_locate} 📍',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared action icon button (phone / WhatsApp)
// ─────────────────────────────────────────────────────────────────────────────

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.darkTertiary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: onTap != null
                ? AppColors.textOnDarkSecondary
                : AppColors.textOnDarkTertiary,
          ),
        ),
      ),
    );
  }
}
