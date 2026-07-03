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

/// Scaffold unificado para creación y edición de eventos.
///
/// - Modo creación: wizard lineal de 4 pasos con step indicator.
/// - Modo edición: el usuario entra en Step 4 (overview) y navega a cada
///   sección tocando "Editar". El guardado es automático por sección.
class EventFormScaffold extends StatelessWidget {
  const EventFormScaffold({
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
    final event = cubit.editingEvent;
    if (event != null) {
      return {
        EventFormFields.name: event.name,
        EventFormFields.description: event.description,
        EventFormFields.dateRange: DateTimeRange(
          start: event.startDate,
          end: event.endDate ?? event.startDate,
        ),
        EventFormFields.meetingTime: event.meetingTime,
        EventFormFields.difficulty: event.difficulty,
        EventFormFields.eventType: event.eventType,
        EventFormFields.allowedBrands: event.allowedBrands,
        EventFormFields.price: event.price?.toString() ?? '',
        EventFormFields.maxParticipants: event.maxParticipants,
      };
    }
    final now = DateTime.now();
    return {
      EventFormFields.difficulty: EventDifficulty.one,
      EventFormFields.eventType: EventType.onRoad,
      EventFormFields.dateRange: DateTimeRange(start: now, end: now),
      EventFormFields.meetingTime: DateTime(now.year, now.month, now.day, 7, 0),
      EventFormFields.allowedBrands: <String>[],
      EventFormFields.maxParticipants: null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = cubit.isEditing;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (isEditing) {
          if (state.currentStep < 3) {
            cubit.goToStep(3);
          } else {
            context.pop();
          }
        } else {
          if (state.currentStep > 0) {
            cubit.prevStep();
          } else {
            _handleCancel(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBgPrimary,
        appBar: AppFormNavHeader(
          title: isEditing
              ? context.l10n.event_editEvent
              : context.l10n.event_newEvent,
          leading: AppFormNavAction.icon(
            icon: Icons.arrow_back,
            onTap: () {
              if (isEditing) {
                if (state.currentStep < 3) {
                  cubit.goToStep(3);
                } else {
                  context.pop();
                }
              } else {
                if (state.currentStep > 0) {
                  cubit.prevStep();
                } else {
                  _handleCancel(context);
                }
              }
            },
            pill: true,
          ),
          trailing: isEditing
              ? null
              : AppFormNavAction.text(
                  label: context.l10n.cancel,
                  onTap: () => _handleCancel(context),
                ),
          showBottomBorder: false,
        ),
        body: Column(
          children: [
            if (!isEditing) ...[
              EventStepIndicator(currentStep: state.currentStep, totalSteps: 4),
              const Divider(height: 1, color: AppColors.darkBorderPrimary),
            ],
            Expanded(
              child: FormBuilder(
                key: cubit.formKey,
                initialValue: _getInitialValues(),
                child: IndexedStack(
                  index: state.currentStep,
                  children: [
                    const EventFormStep1(),
                    EventFormStep2(
                      initialDescription: cubit.editingEvent?.description,
                    ),
                    const EventFormStep3(),
                    const EventFormStep4Review(),
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
