import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/core/utils/initials.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final initials = initialsFromName(user.fullName);

    return Column(
      children: [
        _ProfileAvatar(initials: initials),
        const SizedBox(height: 12),
        if (user.fullName != null && user.fullName!.isNotEmpty)
          Text(
            user.fullName!,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnDarkPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 4),
        if (user.email != null && user.email!.isNotEmpty)
          Text(
            user.email!,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textOnDarkSecondary,
            ),
          ),
        if (user.residenceCity != null &&
            user.residenceCity!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
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
        ],
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => context.pushNamed(
            AppRoutes.editProfile,
            extra: user,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.darkBorderPrimary),
            ),
            child: Text(
              context.l10n.profile_editInfo,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textOnDarkPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.4), // Intentional: gradient stop — alpha variant of primary
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
    );
  }
}
