import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_content.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/states/page_error_state_widget.dart';
import 'package:rideglory/shared/widgets/states/page_loading_state_widget.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) {
        if (!didPop)
          context.goNamed(
            AppRoutes.home,
          ); // Intentional: shell-tab navigation resets stack to prevent back-stack accumulation in StatefulShellRoute
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBgPrimary,
        appBar: AppAppBar(title: context.l10n.profile_title),
        body: SafeArea(
          child: BlocBuilder<ProfileCubit, ResultState<UserModel>>(
            builder: (context, state) {
              return state.when(
                initial: () => const PageLoadingStateWidget(),
                loading: () => const PageLoadingStateWidget(),
                data: (user) => ProfileContent(user: user),
                empty: () => EmptyStateWidget(
                  icon: Icons.person_off_outlined,
                  title: context.l10n.profile_loadingError,
                ),
                error: (error) => PageErrorStateWidget(
                  title: context.l10n.profile_loadingError,
                  message: error.message,
                  onRetry: () async =>
                      context.read<ProfileCubit>().fetchProfile(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
