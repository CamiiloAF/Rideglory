import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/profile/presentation/cubits/delete_account_cubit.dart';
import 'package:rideglory/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:rideglory/features/profile/presentation/widgets/delete_account_confirm_button.dart';
import 'package:rideglory/features/profile/presentation/widgets/delete_account_error_banner.dart';
import 'package:rideglory/features/profile/presentation/widgets/delete_account_intro_section.dart';
import 'package:rideglory/features/profile/presentation/widgets/delete_account_understand_switch.dart';
import 'package:rideglory/features/profile/presentation/widgets/delete_account_what_gets_deleted_list.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class DeleteAccountConfirmationPage extends StatefulWidget {
  const DeleteAccountConfirmationPage({super.key});

  @override
  State<DeleteAccountConfirmationPage> createState() =>
      _DeleteAccountConfirmationPageState();
}

class _DeleteAccountConfirmationPageState
    extends State<DeleteAccountConfirmationPage> {
  late final DeleteAccountCubit _cubit;
  bool _understood = false;

  @override
  void initState() {
    super.initState();
    _cubit = GetIt.instance<DeleteAccountCubit>();
  }

  void _onConfirmTap(BuildContext context) {
    ConfirmationDialog.show(
      context: context,
      title: context.l10n.profile_deleteAccount_pageTitle,
      content: context.l10n.profile_deleteAccount_introBody,
      cancelLabel: context.l10n.cancel,
      confirmLabel: context.l10n.profile_deleteAccount_confirmButton,
      confirmType: DialogActionType.danger,
      icon: Icons.delete_outline,
      onConfirm: () => _cubit.deleteAccount(),
    );
  }

  void _onSuccess(BuildContext context) {
    context.read<AuthCubit>().signOut();
    context.read<VehicleCubit>().clearVehicles();
    context.read<ProfileCubit>().reset();
    context.goAndClearStack(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<DeleteAccountCubit, ResultState<Nothing>>(
        listener: (context, state) {
          if (state is Data<Nothing>) _onSuccess(context);
        },
        child: Scaffold(
          backgroundColor: AppColors.darkBgPrimary,
          appBar: AppAppBar(
            title: context.l10n.profile_deleteAccount_pageTitle,
          ),
          body: SafeArea(
            child: BlocBuilder<DeleteAccountCubit, ResultState<Nothing>>(
              builder: (context, state) {
                final isLoading = state is Loading<Nothing>;
                final isError = state is Error<Nothing>;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    const DeleteAccountIntroSection(),
                    AppSpacing.gapXxl,
                    const DeleteAccountWhatGetsDeletedList(),
                    AppSpacing.gapXxl,
                    if (isError) ...[
                      const DeleteAccountErrorBanner(),
                      AppSpacing.gapXxl,
                    ],
                    DeleteAccountUnderstandSwitch(
                      onChanged: isLoading
                          ? (_) {}
                          : (value) => setState(() => _understood = value),
                    ),
                    AppSpacing.gapXxl,
                    DeleteAccountConfirmButton(
                      isEnabled: _understood,
                      isLoading: isLoading,
                      isRetry: isError,
                      onPressed: () => _onConfirmTap(context),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
