import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_actions_list.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_garage_section.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_header.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_stats_row.dart';

class ProfileContent extends StatelessWidget {
  const ProfileContent({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        ProfileHeader(user: user),
        AppSpacing.gapXxl,
        ProfileStatsRow(
          eventsLabel: context.l10n.profile_statsEvents,
          kmLabel: context.l10n.profile_statsKm,
          followersLabel: context.l10n.profile_statsFollowers,
        ),
        AppSpacing.gapXxl,
        _SectionLabel(label: context.l10n.profile_garage),
        AppSpacing.gapMd,
        const ProfileGarageSection(),
        AppSpacing.gapXxl,
        _SectionLabel(label: context.l10n.profile_settings),
        AppSpacing.gapMd,
        const ProfileActionsList(),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnDarkSecondary,
        letterSpacing: 1.5,
      ),
    );
  }
}
