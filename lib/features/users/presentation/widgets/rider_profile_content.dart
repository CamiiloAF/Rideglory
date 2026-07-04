import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/core/utils/initials.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/features/users/presentation/widgets/rider_avatar.dart';
import 'package:rideglory/features/users/presentation/widgets/rider_stats_row.dart';

class RiderProfileContent extends StatelessWidget {
  const RiderProfileContent({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final initials = Initials.buildFromFullName(user.fullName ?? '');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        RiderAvatar(initials: initials),
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
        if (user.residenceCity != null && user.residenceCity!.isNotEmpty) ...[
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
        RiderStatsRow(
          eventsLabel: context.l10n.rider_statsEvents,
          followersLabel: context.l10n.rider_statsFollowers,
          followingLabel: context.l10n.rider_statsFollowing,
        ),
        AppSpacing.gapXxl,
        AppButton(
          label: context.l10n.rider_follow,
          onPressed: () => InfoDialog.show(
            context: context,
            title: context.l10n.rider_followComingSoonTitle,
            content: context.l10n.rider_followComingSoonMessage,
          ),
        ),
      ],
    );
  }
}
