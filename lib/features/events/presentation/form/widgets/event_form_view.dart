import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/event_form_content.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class EventFormView extends StatelessWidget {
  const EventFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EventFormCubit, ResultState<EventModel>>(
      listener: (context, state) {
        state.whenOrNull(
          data: (event) {
            final isEditing = context.read<EventFormCubit>().isEditing;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isEditing
                      ? context.l10n.event_eventUpdatedSuccess
                      : context.l10n.event_eventCreatedSuccess,
                ),
                backgroundColor: Colors.green,
              ),
            );
            context.pop(event);
          },
          error: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.errorMessage(error.message)),
                backgroundColor: Colors.red,
              ),
            );
          },
        );
      },
      builder: (context, state) {
        final cubit = context.read<EventFormCubit>();
        final isEditing = cubit.isEditing;
        final isLoading = state is Loading;

        return Scaffold(
          backgroundColor: AppColors.darkBackground,
          appBar: AppBar(
            backgroundColor: context.colorScheme.surface,
            foregroundColor: context.colorScheme.onSurface,
            centerTitle: false,
            title: Text(
              isEditing ? context.l10n.event_editEvent : context.l10n.event_newEvent,
              style: TextStyle(
                color: context.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: const EventFormContent(),
          bottomNavigationBar: _EventFormBottomBar(
            isLoading: isLoading,
            isEditing: isEditing,
          ),
        );
      },
    );
  }
}

class _EventFormBottomBar extends StatelessWidget {
  const _EventFormBottomBar({required this.isLoading, required this.isEditing});

  final bool isLoading;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(
          top: BorderSide(color: context.colorScheme.outlineVariant),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        max(16.0, MediaQuery.of(context).padding.bottom),
      ),
      child: AppButton(
        label: isEditing ? context.l10n.event_updateEvent : context.l10n.event_publishEvent,
        isLoading: isLoading,
        icon: Icons.send_outlined,
        onPressed: isLoading
            ? null
            : () {
                final cubit = context.read<EventFormCubit>();
                final event = cubit.buildEventToSave();
                if (event != null) cubit.saveEvent(event);
              },
      ),
    );
  }
}
