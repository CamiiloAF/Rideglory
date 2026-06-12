import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/ai_description_chat_cubit.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/creation_scaffold.dart';
import 'package:rideglory/features/events/presentation/form/widgets/editing_scaffold.dart';

/// Event creation / edit form screen.
///
/// Creation mode: 4-step wizard with [IndexedStack] + [FormBuilder] as ancestor.
///   - Header: "Cancelar" (left) + title (center). No trailing Publish button.
///   - Step indicator in AppFormNavHeader bottom slot.
///   - Navigation between steps via [EventStepNavBar] inside each step widget.
///
/// Edit mode (isEditing == true): flat single-page scroll layout preserved.
///   // TODO(stepper-edit): migrate edit mode to stepper wizard.
// NOTE: IndexedStack keeps MapboxMap + QuillEditor alive simultaneously.
class EventFormView extends StatelessWidget {
  const EventFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EventFormCubit, EventFormState>(
      listenWhen: (previous, current) =>
          previous.saveResult != current.saveResult,
      listener: (context, state) {
        state.saveResult.whenOrNull(
          data: (event) {
            context.read<AiDescriptionChatCubit>().reset();
            final isEditing = context.read<EventFormCubit>().isEditing;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isEditing
                      ? context.l10n.event_eventUpdatedSuccess
                      : context.l10n.event_eventCreatedSuccess,
                ),
                backgroundColor: AppColors.success,
              ),
            );
          },
          error: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.errorMessage(error.message)),
                backgroundColor: AppColors.error,
              ),
            );
          },
        );
      },
      builder: (context, state) {
        final cubit = context.read<EventFormCubit>();
        final isEditing = cubit.isEditing;
        final isSaving = state.saveResult is Loading<EventModel>;

        if (isEditing) {
          // TODO(stepper-edit): replace with stepper wizard when edit mode is ready.
          return EditingScaffold(isSaving: isSaving);
        }

        return CreationScaffold(state: state, cubit: cubit, isSaving: isSaving);
      },
    );
  }
}
