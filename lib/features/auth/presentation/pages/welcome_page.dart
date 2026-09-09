import 'package:go_router/go_router.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/domain/result_state.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/router/go_router_extensions.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../auth_error_translator.dart';
import '../cubit/welcome_cubit.dart';
import '../widgets/social_auth_button.dart';
import '../widgets/welcome_feature_row.dart';

/// Bienvenida (L2): propuesta de valor + Google, Apple y correo.
///
/// Pencil: tp9oS
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return BlocProvider(
      create: (_) => getIt<WelcomeCubit>(),
      child: Scaffold(
        body: BlocListener<WelcomeCubit, ResultState<Unit>>(
          listener: (context, state) {
            state.whenOrNull(
              data: (_) => context.goAndClearStack(AppRoutes.maintenancePath),
              error: (error) => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(authErrorMessage(context, error))),
              ),
            );
          },
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.auth_welcome_title,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              color: colors.text,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            context.l10n.auth_welcome_headline,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              color: colors.text,
                            ),
                          ),
                          const SizedBox(height: 22),
                          WelcomeFeatureRow(
                            icon: LucideIcons.timer,
                            title: context
                                .l10n
                                .auth_welcome_feature_maintenance_title,
                            body: context
                                .l10n
                                .auth_welcome_feature_maintenance_body,
                          ),
                          WelcomeFeatureRow(
                            icon: LucideIcons.bike,
                            title:
                                context.l10n.auth_welcome_feature_garage_title,
                            body: context.l10n.auth_welcome_feature_garage_body,
                          ),
                          WelcomeFeatureRow(
                            icon: LucideIcons.fileText,
                            title: context
                                .l10n
                                .auth_welcome_feature_documents_title,
                            body: context
                                .l10n
                                .auth_welcome_feature_documents_body,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 26),
                    child: Column(
                      children: [
                        BlocBuilder<WelcomeCubit, ResultState<Unit>>(
                          builder: (context, state) {
                            final isLoading = state is Loading;
                            return Column(
                              children: [
                                SocialAuthButton(
                                  label:
                                      context.l10n.auth_welcome_continue_google,
                                  onPressed: isLoading
                                      ? null
                                      : () => context
                                            .read<WelcomeCubit>()
                                            .signInWithGoogle(),
                                ),
                                const SizedBox(height: 11),
                                SocialAuthButton(
                                  label:
                                      context.l10n.auth_welcome_continue_apple,
                                  onPressed: isLoading
                                      ? null
                                      : () => context
                                            .read<WelcomeCubit>()
                                            .signInWithApple(),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 11),
                        TextButton(
                          onPressed: () =>
                              context.pushNamed(AppRoutes.authEmailLogin),
                          child: Text(
                            context.l10n.auth_welcome_continue_email,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.text,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.auth_welcome_legal,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
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
