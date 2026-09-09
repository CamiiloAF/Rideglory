import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/domain/result_state.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/router/go_router_extensions.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../../shared/cubits/connectivity/connectivity_cubit.dart';
import '../../../../shared/cubits/connectivity/connectivity_state.dart';
import '../../../../shared/widgets/states/error_state_view.dart';
import '../../../../shared/widgets/states/offline_state_view.dart';
import '../cubit/profile_overview_cubit.dart';
import '../cubit/profile_overview_state.dart';
import '../cubit/profile_settings_cubit.dart';
import '../cubit/sign_out_cubit.dart';
import '../profile_error_translator.dart';
import '../widgets/profile_content.dart';
import '../widgets/profile_skeleton.dart';
import '../widgets/settings_gear_button.dart';

/// P2 — Ficha del rider. Página principal de la pestaña Perfil.
///
/// Pencil: iFssW (contenido), ZhLW3 (carga), iWE6o (error), HGJYs (sin conexión)
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isOffline =
        context.watch<ConnectivityCubit>().state is ConnectivityOffline;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ProfileOverviewCubit>()..load()),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.profile_title,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: colors.text,
                        ),
                      ),
                      const SettingsGearButton(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: isOffline
                        ? OfflineStateView(
                            title: context.l10n.profile_offline_title,
                            body: context.l10n.profile_offline_body,
                            onRetry: () =>
                                context.read<ProfileOverviewCubit>().load(),
                          )
                        : BlocBuilder<
                            ProfileOverviewCubit,
                            ProfileOverviewState
                          >(
                            builder: (context, state) {
                              return state.profile.when(
                                initial: () => const ProfileSkeleton(),
                                loading: () => const ProfileSkeleton(),
                                empty: () => const ProfileSkeleton(),
                                error: (error) => ErrorStateView(
                                  title: context.l10n.profile_load_error_title,
                                  message: profileErrorMessage(context, error),
                                  onRetry: () => context
                                      .read<ProfileOverviewCubit>()
                                      .load(),
                                ),
                                data: (profile) =>
                                    ProfileContent(profile: profile),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
