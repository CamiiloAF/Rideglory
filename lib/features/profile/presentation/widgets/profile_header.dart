import 'package:flutter/material.dart';
import 'package:rideglory/core/utils/initials.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initials = initialsFromName(user.fullName);

    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: colorScheme.primary,
          child: Text(
            initials,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (user.fullName != null && user.fullName!.isNotEmpty)
          Text(
            user.fullName!,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        if (user.email != null && user.email!.isNotEmpty)
          Text(
            user.email!,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
