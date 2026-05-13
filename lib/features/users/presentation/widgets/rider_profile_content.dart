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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final initials = Initials.buildFromFullName(user.fullName ?? '');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: CircleAvatar(
            radius: 36,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              initials,
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        AppSpacing.gapMd,
        Center(
          child: Text(
            user.fullName ?? '',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (user.email != null && user.email!.isNotEmpty) ...[
          AppSpacing.gapXs,
          Center(
            child: Text(
              user.email!,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        if (user.residenceCity != null && user.residenceCity!.isNotEmpty) ...[
          AppSpacing.gapSm,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              AppSpacing.hGapXs,
              Text(
                user.residenceCity!,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
        AppSpacing.gapXl,
        Text(
          context.l10n.rider_noVehicles,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
