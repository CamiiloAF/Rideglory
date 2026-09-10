import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/domain/result_state.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../design_system/components/app_page_header.dart';
import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/components/app_secondary_button.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../../shared/widgets/states/error_state_view.dart';
import '../../domain/delete_account_summary.dart';
import '../cubit/delete_account_cubit.dart';
import '../cubit/delete_account_state.dart';
import '../cubit/delete_account_summary_cubit.dart';
import '../profile_error_translator.dart';
import '../widgets/delete_account_summary_content.dart';
import '../widgets/delete_account_summary_skeleton.dart';
import '../widgets/delete_confirm_sheet.dart';

/// Paso 1: explica qué se borra. El paso 2 (confirmación) es una hoja
/// modal sobre esta misma pantalla, tal como lo diseña el `.pen`.
///
/// Pencil: MCSBy (paso 1), H69H3 (paso 2, hoja)
class DeleteAccountExplanationPage extends StatelessWidget {
  const DeleteAccountExplanationPage({super.key});

  Future<void> _openConfirmSheet(
    BuildContext context,
    DeleteAccountCubit cubit,
    DeleteAccountSummary summary,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: cubit,
        child: DeleteConfirmSheet(summary: summary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<DeleteAccountSummaryCubit>()..load()),
        BlocProvider(create: (_) => getIt<DeleteAccountCubit>()),
      ],
      child: BlocListener<DeleteAccountCubit, DeleteAccountState>(
        listener: (context, state) {
          switch (state) {
            case DeleteAccountInProgress():
              context.pushNamed(
                AppRoutes.profileDeleteAccountProgress,
                extra: context.read<DeleteAccountCubit>(),
              );
            case DeleteAccountBlocked():
              context.pushNamed(AppRoutes.profileDeleteAccountBlocked);
            case DeleteAccountDone():
            case DeleteAccountInitial():
            case DeleteAccountError():
              break;
          }
        },
        child: Scaffold(
          appBar: AppPageHeader(title: context.l10n.profile_delete_step1_title),
          body:
              BlocBuilder<
                DeleteAccountSummaryCubit,
                ResultState<DeleteAccountSummary>
              >(
                builder: (context, state) {
                  return state.when(
                    initial: () => const DeleteAccountSummarySkeleton(),
                    loading: () => const DeleteAccountSummarySkeleton(),
                    empty: () => const DeleteAccountSummarySkeleton(),
                    error: (error) => ErrorStateView(
                      message: profileErrorMessage(context, error),
                      onRetry: () =>
                          context.read<DeleteAccountSummaryCubit>().load(),
                    ),
                    data: (summary) => Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                            child: DeleteAccountSummaryContent(
                              summary: summary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                          child: Column(
                            children: [
                              AppPrimaryButton(
                                destructive: true,
                                label:
                                    context.l10n.profile_delete_continue_button,
                                onPressed: () => _openConfirmSheet(
                                  context,
                                  context.read<DeleteAccountCubit>(),
                                  summary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              AppSecondaryButton(
                                label:
                                    context.l10n.profile_delete_cancel_button,
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
        ),
      ),
    );
  }
}
