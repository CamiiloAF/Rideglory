import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/event_form_content.dart';
import 'package:rideglory/shared/widgets/app_app_bar.dart';

class EventFormView extends StatelessWidget {
  const EventFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EventFormCubit, EventFormState>(
      listener: (context, state) {
        state.whenOrNull(
          success: (event) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(EventStrings.eventCreatedSuccess),
                backgroundColor: Colors.green,
              ),
            );
            context.pop(event);
          },
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppStrings.errorMessage(message)),
                backgroundColor: Colors.red,
              ),
            );
          },
        );
      },
      builder: (context, state) {
        final isEditing = state.maybeWhen(
          editing: (_) => true,
          orElse: () => false,
        );
        return Scaffold(
          appBar: AppAppBar(
            title: isEditing
                ? EventStrings.editEvent
                : EventStrings.createEvent,
          ),
          body: const EventFormContent(),
        );
      },
    );
  }
}
