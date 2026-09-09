import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/domain/result_state.dart';
import '../../../../core/services/notifications/maintenance_notification_scheduler.dart';
import '../../../../design_system/components/app_banner.dart';
import '../../../../design_system/components/app_page_header.dart';
import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/components/saving_button.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/register_maintenance_cubit.dart';
import '../cubit/register_maintenance_state.dart';
import '../widgets/maintenance_wizard_progress.dart';
import 'register_maintenance_step1.dart';
import 'register_maintenance_step2.dart';
import 'register_maintenance_step3.dart';

/// Encabezado + progreso + paso actual + CTA del asistente de registro.
class RegisterMaintenanceView extends StatelessWidget {
  const RegisterMaintenanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegisterMaintenanceCubit>();

    return BlocConsumer<RegisterMaintenanceCubit, RegisterMaintenanceState>(
      listener: (context, state) async {
        final maintenance = state.submission.whenOrNull(data: (data) => data);
        if (maintenance == null) return;
        final l10n = context.l10n;
        final navigator = Navigator.of(context);
        final scheduler = getIt<MaintenanceNotificationScheduler>();
        await scheduler.cancel(maintenance.id);
        if (maintenance.nextDate != null) {
          await scheduler.scheduleForMaintenance(
            maintenanceId: maintenance.id,
            title: l10n.maintenance_notification_title,
            body: l10n.maintenance_notification_body(
              maintenance.type,
              maintenance.vehicleDisplayName,
            ),
            date: maintenance.nextDate!,
          );
        }
        navigator.pop(true);
      },
      builder: (context, state) {
        final l10n = context.l10n;
        final isLastStep = state.step == 2;
        final canContinue = switch (state.step) {
          0 => state.canContinueStep1,
          1 => state.canContinueStep2,
          _ => true,
        };

        return Scaffold(
          appBar: AppPageHeader(
            title: state.isEditing
                ? l10n.maintenance_edit_title
                : l10n.maintenance_register_title,
            onBack: () => _handleBack(context, cubit, state),
          ),
          body: SafeArea(
            child: Column(
              children: [
                MaintenanceWizardProgress(step: state.step),
                Expanded(
                  child: SingleChildScrollView(
                    child: switch (state.step) {
                      0 => RegisterMaintenanceStep1(state: state, cubit: cubit),
                      1 => RegisterMaintenanceStep2(state: state, cubit: cubit),
                      _ => RegisterMaintenanceStep3(state: state, cubit: cubit),
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.submission.maybeWhen(
                        error: (_) => true,
                        orElse: () => false,
                      )) ...[
                        AppBanner(
                          title: l10n.maintenance_save_error_title,
                          body: l10n.maintenance_save_error_body,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (state.isSubmitting)
                        SavingButton(label: l10n.maintenance_action_saving)
                      else
                        AppPrimaryButton(
                          label: isLastStep
                              ? l10n.maintenance_action_save
                              : l10n.maintenance_action_next,
                          onPressed: canContinue
                              ? () => isLastStep
                                    ? cubit.submit()
                                    : cubit.nextStep()
                              : null,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleBack(
    BuildContext context,
    RegisterMaintenanceCubit cubit,
    RegisterMaintenanceState state,
  ) {
    if (state.step == 0 && state.isOtherType && !state.isEditing) {
      cubit.clearTypeSelection();
      return;
    }
    if (state.step > 0) {
      cubit.previousStep();
      return;
    }
    Navigator.of(context).maybePop();
  }
}
