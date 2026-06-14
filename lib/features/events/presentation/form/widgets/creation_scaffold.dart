import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/event_form_step1.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/event_form_step2.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/event_form_step3.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/event_form_step4_review.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/event_step_indicator.dart';

/// Scaffold para el modo creación: wizard de 4 pasos.
///
/// Design spec (Pencil AybHb / EzQtb / XbcHD / FW3Hd):
/// - AppBar: ← botón círculo (siempre) + "Nuevo Evento" + "Cancelar" en todos los steps
/// - Step 0: cancelar sin confirmación. Steps 1-3: diálogo de confirmación.
/// - El EventStepIndicator va en el body (Column), NO en AppBar.bottom
/// - Separador 1px entre stepper y contenido del paso
class CreationScaffold extends StatelessWidget {
  const CreationScaffold({
    super.key,
    required this.state,
    required this.cubit,
    required this.isSaving,
  });

  final EventFormState state;
  final EventFormCubit cubit;
  final bool isSaving;

  Future<void> _handleCancel(BuildContext context) async {
    final confirmed = await AppModal.show<bool>(
      context: context,
      title: context.l10n.event_wizard_cancel_dialog_title,
      description: context.l10n.event_wizard_cancel_dialog_body,
      variant: AppModalVariant.warning,
      actions: [
        AppModalAction(
          label: context.l10n.event_wizard_cancel_dialog_confirm,
          emphasis: AppModalActionEmphasis.primary,
          popResult: true,
          onPressed: () {},
        ),
        AppModalAction.neutral(
          label: context.l10n.cancel,
          popResult: false,
          onPressed: () {},
        ),
      ],
    );
    if ((confirmed ?? false) && context.mounted) {
      context.pop();
    }
  }

  Map<String, dynamic> _getInitialValues() {
    return {
      EventFormFields.difficulty: EventDifficulty.one,
      EventFormFields.eventType: EventType.onRoad,
      EventFormFields.dateRange: DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now(),
      ),
      EventFormFields.meetingTime: DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        7,
        0,
      ),
      EventFormFields.allowedBrands: <String>[],
      EventFormFields.maxParticipants: null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (state.currentStep > 0) {
          cubit.prevStep();
        } else {
          _handleCancel(context);
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppFormNavHeader(
        title: context.l10n.event_newEvent,
        leading: AppFormNavAction.icon(
          icon: Icons.arrow_back,
          onTap: () => state.currentStep > 0
              ? cubit.prevStep()
              : _handleCancel(context),
          pill: true,
        ),
        trailing: AppFormNavAction.text(
          label: context.l10n.cancel,
          onTap: () => _handleCancel(context),
        ),
        showBottomBorder: false,
      ),
      body: Column(
        children: [
          EventStepIndicator(
            currentStep: state.currentStep,
            totalSteps: 4,
          ),
          const Divider(height: 1, color: AppColors.darkBorderPrimary),
          Expanded(
            child: FormBuilder(
              key: cubit.formKey,
              initialValue: _getInitialValues(),
              child: IndexedStack(
                index: state.currentStep,
                children: const [
                  EventFormStep1(),
                  EventFormStep2(),
                  EventFormStep3(),
                  EventFormStep4Review(),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
