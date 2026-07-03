import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';

class ProfileEditAvatar extends StatelessWidget {
  const ProfileEditAvatar({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final initials = user.fullName != null && user.fullName!.isNotEmpty
        ? user.fullName!
              .trim()
              .split(RegExp(r'\s+'))
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join()
        : '?';

    return Center(
      child: Stack(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(
                    alpha: 0.4,
                  ), // Intentional: gradient stop — alpha variant of primary
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
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 16,
                color: AppColors.darkBgPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
