import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/event_form_content.dart';
import 'package:rideglory/shared/widgets/app_app_bar.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';

class EventFormView extends StatelessWidget {
  const EventFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EventFormCubit, ResultState<EventModel>>(
      listener: (context, state) {
        state.whenOrNull(
          data: (event) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(EventStrings.eventCreatedSuccess),
                backgroundColor: Colors.green,
              ),
            );
            context.pop(event);
          },
          error: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppStrings.errorMessage(error.message)),
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
          appBar: AppAppBar(
            title: isEditing
                ? EventStrings.editEvent
                : EventStrings.createEvent,
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
        color: AppColors.darkSurface,
        border: Border(top: BorderSide(color: AppColors.darkBorder)),
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
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Cancelar',
              variant: AppButtonVariant.outline,
              isLoading: false,
              onPressed: isLoading ? null : () => context.pop(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: AppButton(
              label: isEditing
                  ? EventStrings.updateEvent
                  : EventStrings.saveEvent,
              isLoading: isLoading,
              icon: Icons.save_outlined,
              onPressed: isLoading
                  ? null
                  : () {
                      final cubit = context.read<EventFormCubit>();
                      final event = cubit.buildEventToSave();
                      if (event != null) cubit.saveEvent(event);
                    },
            ),
          ),
        ],
      ),
    );
  }
}
