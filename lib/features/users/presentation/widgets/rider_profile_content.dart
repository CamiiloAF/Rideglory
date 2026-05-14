import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        // Avatar with gradient ring
        Center(
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
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        AppSpacing.gapMd,
        // Name
        Center(
          child: Text(
            user.fullName ?? '',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Location
        if (user.residenceCity != null && user.residenceCity!.isNotEmpty) ...[
          AppSpacing.gapXxs,
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.textOnDarkSecondary,
                ),
                AppSpacing.hGapXxs,
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
        // Email as bio fallback
        if (user.email != null && user.email!.isNotEmpty) ...[
          AppSpacing.gapXs,
          Center(
            child: Text(
              user.email!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textOnDarkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        AppSpacing.gapXl,
        // Stats row
        const Row(
          children: [
            _StatCard(value: '0', label: 'Rodadas'),
            AppSpacing.hGapMd,
            _StatCard(value: '0', label: 'Seguidores'),
            AppSpacing.hGapMd,
            _StatCard(value: '0', label: 'Siguiendo'),
          ],
        ),
        AppSpacing.gapLg,
        // Follow button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.darkBgPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Seguir',
              style: TextStyle(
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
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
