import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/domain/result_state.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/router/go_router_extensions.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../../shared/widgets/states/error_state_view.dart';
import '../../../../shared/widgets/states/skeleton_list.dart';
import '../cubit/profile_settings_cubit.dart';
import '../cubit/profile_settings_state.dart';
import '../cubit/sign_out_cubit.dart';
import '../profile_error_translator.dart';
import '../widgets/settings_list_content.dart';

/// P1 — Lista de ajustes: la vista extendida a la que se llega desde el
/// engranaje de la ficha del rider.
///
/// Pencil: BS3wJ
class SettingsListPage extends StatelessWidget {
  const SettingsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ProfileSettingsCubit>()..load()),
        BlocProvider(create: (_) => getIt<SignOutCubit>()),
      ],
      child: BlocListener<SignOutCubit, ResultState<Unit>>(
        listener: (context, state) {
          state.whenOrNull(
            data: (_) => context.goAndClearStack(AppRoutes.welcomePath),
          );
        },
        child: Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Text(
                    context.l10n.profile_title,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                ),
                Expanded(
                  child:
                      BlocBuilder<ProfileSettingsCubit, ProfileSettingsState>(
                        builder: (context, state) {
                          return state.profile.when(
                            initial: () => const SkeletonList(),
                            loading: () => const SkeletonList(),
                            empty: () => const SkeletonList(),
                            error: (error) => ErrorStateView(
                              title: context.l10n.profile_load_error_title,
                              message: profileErrorMessage(context, error),
                              onRetry: () =>
                                  context.read<ProfileSettingsCubit>().load(),
                            ),
                            data: (profile) => SettingsListContent(
                              profile: profile,
                              notificationsEnabled: state.notificationsEnabled,
                              analyticsEnabled: state.analyticsEnabled,
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
