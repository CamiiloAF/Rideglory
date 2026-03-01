import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/core/theme/app_colors.dart';
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
        final isLoading = state.maybeWhen(
          loading: () => true,
          orElse: () => false,
        );
        return Scaffold(
          appBar: AppAppBar(
            title: isEditing
                ? EventStrings.editEvent
                : EventStrings.createEvent,
          ),
          body: const EventFormContent(),
          // ── Sticky bottom bar ──────────────────────────────────
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
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
                // Cancel button
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: isLoading ? null : () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Save button
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () {
                              final cubit = context.read<EventFormCubit>();
                              final event = cubit.buildEventToSave();
                              if (event != null) cubit.saveEvent(event);
                            },
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        isEditing
                            ? EventStrings.updateEvent
                            : EventStrings.saveEvent,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
