import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/domain/result_state.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/router/go_router_extensions.dart';
import '../../../../design_system/components/app_page_header.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../../shared/widgets/states/error_state_view.dart';
import '../cubit/delete_account_cubit.dart';
import '../cubit/delete_account_state.dart';
import '../cubit/sign_out_cubit.dart';

/// Paso 3 — "Borrando tu cuenta...". Recibe el mismo [DeleteAccountCubit]
/// del paso 1/2 por `extra` de la ruta (Navigator apila páginas distintas;
/// no comparten árbol de widgets).
///
/// Pencil: ofQFh
class DeleteAccountProgressPage extends StatelessWidget {
  const DeleteAccountProgressPage({
    required this.deleteAccountCubit,
    super.key,
  });

  final DeleteAccountCubit deleteAccountCubit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: deleteAccountCubit),
        BlocProvider(create: (_) => getIt<SignOutCubit>()),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<DeleteAccountCubit, DeleteAccountState>(
            listener: (context, state) {
              if (state is DeleteAccountDone) {
                context.read<SignOutCubit>().signOut();
              }
            },
          ),
          BlocListener<SignOutCubit, ResultState<Unit>>(
            listener: (context, state) {
              state.whenOrNull(
                data: (_) => context.goAndClearStack(AppRoutes.welcomePath),
              );
            },
          ),
        ],
        child: Scaffold(
          appBar: AppPageHeader(title: context.l10n.profile_delete_step1_title),
          body: BlocBuilder<DeleteAccountCubit, DeleteAccountState>(
            builder: (context, state) {
              if (state is DeleteAccountError) {
                return ErrorStateView(
                  title: context.l10n.profile_delete_error_title,
                  message: context.l10n.profile_delete_error_body,
                  onRetry: () => context.read<DeleteAccountCubit>().confirm(),
                );
              }
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          LucideIcons.trash2,
                          size: 26,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        context.l10n.profile_delete_progress_title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.profile_delete_progress_body,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          backgroundColor: colors.border,
                          color: colors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
