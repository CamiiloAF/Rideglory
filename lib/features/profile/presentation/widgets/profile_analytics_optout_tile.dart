import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/profile/presentation/cubits/analytics_consent_cubit.dart';
import 'package:rideglory/shared/widgets/form/app_switch.dart';

/// A row in [ProfileActionsList] that lets the rider opt in/out of anonymous
/// analytics collection.  Uses [AppSwitch] (knob dark when ON) per the
/// dark-on-primary rule.  Lives in its own file — one widget per file rule.
class ProfileAnalyticsOptOutTile extends StatelessWidget {
  const ProfileAnalyticsOptOutTile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AnalyticsConsentCubit, ResultState<bool>>(
      listenWhen: (_, current) => current is Error,
      listener: (context, state) {
        if (state is Error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.profile_analyticsOptOutSaveError),
            ),
          );
        }
      },
      builder: (context, state) {
        final enabled = state.maybeWhen(
          data: (value) => value,
          orElse: () => true,
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(
                Icons.privacy_tip_outlined,
                color: AppColors.textOnDarkSecondary,
                size: 20,
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Text(
                  context.l10n.profile_analyticsOptOutLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textOnDarkPrimary,
                  ),
                ),
              ),
              AppSwitch(
                value: enabled,
                onChanged: (value) =>
                    context.read<AnalyticsConsentCubit>().toggle(value),
              ),
            ],
          ),
        );
      },
    );
  }
}
