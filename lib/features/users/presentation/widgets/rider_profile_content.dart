import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/core/utils/initials.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';

class RiderProfileContent extends StatelessWidget {
  const RiderProfileContent({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final initials = Initials.buildFromFullName(user.fullName ?? '');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        _RiderAvatar(initials: initials),
        AppSpacing.gapMd,
        Center(
          child: Text(
            user.fullName ?? '',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnDarkPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (user.email != null && user.email!.isNotEmpty) ...[
          AppSpacing.gapXs,
          Center(
            child: Text(
              user.email!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textOnDarkSecondary,
              ),
            ),
          ),
        ],
        if (user.residenceCity != null &&
            user.residenceCity!.isNotEmpty) ...[
          AppSpacing.gapXs,
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.textOnDarkSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  user.residenceCity!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textOnDarkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
        AppSpacing.gapXxl,
        _RiderStatsRow(
          eventsLabel: context.l10n.rider_statsEvents,
          followersLabel: context.l10n.rider_statsFollowers,
          followingLabel: context.l10n.rider_statsFollowing,
        ),
        AppSpacing.gapXxl,
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.darkBgPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              context.l10n.rider_follow,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RiderAvatar extends StatelessWidget {
  const _RiderAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              Color(0x66F98C1F),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.darkCard,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnDarkPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RiderStatsRow extends StatelessWidget {
  const _RiderStatsRow({
    required this.eventsLabel,
    required this.followersLabel,
    required this.followingLabel,
  });

  final String eventsLabel;
  final String followersLabel;
  final String followingLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCell(value: '0', label: eventsLabel),
        const SizedBox(width: 8),
        _StatCell(value: '0', label: followersLabel),
        const SizedBox(width: 8),
        _StatCell(value: '0', label: followingLabel),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textOnDarkPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textOnDarkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
