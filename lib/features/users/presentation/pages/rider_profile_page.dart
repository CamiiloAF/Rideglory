import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/features/users/presentation/cubit/rider_profile_cubit.dart';
import 'package:rideglory/features/users/presentation/widgets/rider_profile_content.dart';
import 'package:rideglory/features/users/presentation/widgets/rider_profile_loading.dart';

class RiderProfilePage extends StatelessWidget {
  const RiderProfilePage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RiderProfileCubit>()..fetchRiderProfile(userId),
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppAppBar(title: context.l10n.rider_profileTitle),
        body: SafeArea(
          child: BlocBuilder<RiderProfileCubit, ResultState<UserModel>>(
            builder: (context, state) {
              return state.when(
                initial: () => const RiderProfileLoading(),
                loading: () => const RiderProfileLoading(),
                data: (user) => RiderProfileContent(user: user),
                empty: () => const RiderProfileLoading(),
                error: (error) => _RiderProfileError(
                  message: error.message,
                  onRetry: () =>
                      context.read<RiderProfileCubit>().fetchRiderProfile(userId),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RiderProfileError extends StatelessWidget {
  const _RiderProfileError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: colorScheme.onErrorContainer,
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Text(
                    message,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapLg,
          AppButton(
            label: context.l10n.rider_errorRetry,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
