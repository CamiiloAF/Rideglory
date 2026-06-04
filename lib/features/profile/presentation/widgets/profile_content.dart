import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/profile/presentation/cubits/analytics_consent_cubit.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_actions_list.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_header.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_section_label.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_stats_row.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';

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
        ProfileSectionLabel(label: context.l10n.profile_settings),
        AppSpacing.gapMd,
        BlocProvider<AnalyticsConsentCubit>(
          create: (_) => getIt<AnalyticsConsentCubit>()..load(),
          child: const ProfileActionsList(),
        ),
      ],
    );
  }
}
