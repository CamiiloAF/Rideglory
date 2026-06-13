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
/// - AppBar: ← botón círculo (siempre) + "Nuevo Evento" + "Cancelar" solo en step 0
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

  Map<String, dynamic> _getInitialValues() {
    return {
      EventFormFields.difficulty: EventDifficulty.one,
      EventFormFields.eventType: EventType.tourism,
      EventFormFields.isMultiDay: false,
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
      EventFormFields.isMultiBrand: true,
      EventFormFields.allowedBrands: <String>[],
      EventFormFields.maxParticipants: null,
      EventFormFields.isFreeEvent: false,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppFormNavHeader(
        title: context.l10n.event_newEvent,
        leading: AppFormNavAction.icon(
          icon: Icons.arrow_back,
          onTap: () => context.pop(),
          pill: true,
        ),
        trailing: state.currentStep == 0
            ? AppFormNavAction.text(
                label: context.l10n.cancel,
                onTap: () => context.pop(),
              )
            : null,
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: IndexedStack(
                  key: ValueKey(state.currentStep),
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
          ),
        ],
      ),
    );
  }
}
