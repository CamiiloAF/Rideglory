import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/features/users/presentation/cubit/rider_profile_cubit.dart';
import 'package:rideglory/features/users/presentation/widgets/rider_profile_content.dart';
import 'package:rideglory/features/users/presentation/widgets/rider_profile_error.dart';
import 'package:rideglory/features/users/presentation/widgets/rider_profile_loading.dart';
import 'package:rideglory/shared/widgets/states/page_loading_state_widget.dart';

class RiderProfilePage extends StatelessWidget {
  const RiderProfilePage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RiderProfileCubit>()..fetchRiderProfile(userId),
      child: Scaffold(
        backgroundColor: AppColors.darkBgPrimary,
        appBar: AppAppBar(title: context.l10n.rider_profileTitle),
        body: SafeArea(
          child: BlocBuilder<RiderProfileCubit, ResultState<UserModel>>(
            builder: (context, state) {
              return state.when(
                initial: () => const PageLoadingStateWidget(),
                loading: () => const RiderProfileLoading(),
                data: (user) => RiderProfileContent(user: user),
                empty: () => const RiderProfileLoading(),
                error: (error) => RiderProfileError(
                  message: error.message,
                  onRetry: () => context
                      .read<RiderProfileCubit>()
                      .fetchRiderProfile(userId),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
