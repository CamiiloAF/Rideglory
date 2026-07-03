import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/shared/router/app_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/ai_description_chat_cubit.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/event_form_scaffold.dart';

/// Event creation / edit form screen.
///
/// Creation mode: 4-step wizard with [IndexedStack] + [FormBuilder] as ancestor.
///   - Header: "Cancelar" (left) + title (center). No trailing Publish button.
///   - Step indicator in body column.
///   - Navigation between steps via [EventStepNavBar] inside each step widget.
///
/// Edit mode: enters at Step 4 (overview). User taps "Editar" on a card,
///   goes to the relevant step, saves with "Listo", returns to overview.
///   No step indicator shown. Changes are saved per-section automatically.
// NOTE: IndexedStack keeps MapboxMap + QuillEditor alive simultaneously.
class EventFormView extends StatelessWidget {
  const EventFormView({super.key, this.onSaved});

  final void Function(EventModel)? onSaved;

  @override
  Widget build(BuildContext context) {
    // ScaffoldMessenger local para que los SnackBars se anclen al Scaffold
    // del wizard y no al del MainShell (que tiene HomeBottomNavigationBar).
    return ScaffoldMessenger(
      child: BlocConsumer<EventFormCubit, EventFormState>(
        listenWhen: (previous, current) =>
            previous.saveResult != current.saveResult,
        listener: (context, state) {
          state.saveResult.whenOrNull(
            data: (event) {
              context.read<AiDescriptionChatCubit>().reset();
              final cubit = context.read<EventFormCubit>();
              if (cubit.isEditing) {
                // Notifica al detalle inmediatamente, sin importar cómo se cierre el form.
                onSaved?.call(event);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.event_changesSaved),
                    backgroundColor: AppColors.success,
                  ),
                );
                cubit.goToStep(3);
              } else {
                // Publicación: SnackBar global. El cierre del wizard lo hace
                // PublishRow tras cerrarse el sheet de responsabilidad, para que
                // el EventModel guardado llegue a la lista (pop-result) y esta se
                // actualice.
                AppRouter.scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.event_eventCreatedSuccess),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
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
          final isSaving = state.saveResult is Loading<EventModel>;

          return EventFormScaffold(
            state: state,
            cubit: cubit,
            isSaving: isSaving,
          );
        },
      ),
    );
  }
}
