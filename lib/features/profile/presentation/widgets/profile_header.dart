import 'package:flutter/material.dart';
import 'package:rideglory/core/utils/initials.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final initials = initialsFromName(user.fullName);

    return Column(
      children: [
        // Avatar with gradient ring
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                Color(0x66F98C1F), // accent at 40%
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
        const SizedBox(height: 12),
        if (user.fullName != null && user.fullName!.isNotEmpty)
          Text(
            user.fullName!,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
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
      ],
    );
  }
}
