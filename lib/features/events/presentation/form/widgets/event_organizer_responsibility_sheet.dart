import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';

/// Opens the organizer legal-responsibility declaration as a bottom sheet,
/// shown right before publishing a new event. Reuses the caller's
/// [EventFormCubit] and [FormImageCubit] instances (via [BlocProvider.value]).
/// Resolves to the saved [EventModel] when the organizer accepts and the save
/// succeeds — so the caller can pop the create page with it and let the events
/// list refresh via the pop-result — or to null if they dismiss/review.
Future<EventModel?> showEventOrganizerResponsibilitySheet({
  required BuildContext context,
  required EventModel eventToSave,
}) {
  final cubit = context.read<EventFormCubit>();
  final imageCubit = context.read<FormImageCubit>();
  return showModalBottomSheet<EventModel>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: cubit),
        BlocProvider.value(value: imageCubit),
      ],
      child: EventOrganizerResponsibilitySheet(eventToSave: eventToSave),
    ),
  );
}

/// Organizer responsibility acceptance sheet: a scrollable legal declaration
/// and the accept/review actions. Accepting stamps the responsibility timestamp
/// and saves the event; a successful save pops the sheet returning the saved
/// [EventModel] so the caller (`PublishRow`) can close the create page with it.
class EventOrganizerResponsibilitySheet extends StatelessWidget {
  const EventOrganizerResponsibilitySheet({
    super.key,
    required this.eventToSave,
  });

  final EventModel eventToSave;

  Future<void> _onAccept(BuildContext context) async {
    final cubit = context.read<EventFormCubit>();
    final imageCubit = context.read<FormImageCubit>();
    final acceptedAt = DateTime.now();
    cubit.setOrganizerResponsibility(acceptedAt);

    final imageData = imageCubit.state.whenOrNull(data: (data) => data);
    await cubit.saveEvent(
      eventToSave.copyWith(organizerAcceptedResponsibilityAt: acceptedAt),
      localCoverImagePath: imageData?.hasLocalImage == true
          ? imageData?.localImagePath
          : null,
      remoteCoverImageUrl: imageData?.hasLocalImage != true
          ? imageData?.remoteImageUrl
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return BlocConsumer<EventFormCubit, EventFormState>(
      listenWhen: (previous, current) =>
          previous.saveResult != current.saveResult,
      listener: (context, state) {
        state.saveResult.whenOrNull(
          data: (savedEvent) => Navigator.of(context).pop(savedEvent),
        );
      },
      builder: (context, state) {
        final isSaving = state.saveResult is Loading<EventModel>;
        final errorOrNull = state.saveResult.mapOrNull(error: (e) => e.error);

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.l10n.event_organizerResponsibility_title,
                        style: const TextStyle(
                          color: AppColors.textOnDarkPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      AppSpacing.gapMd,
                      Text(
                        context.l10n.event_organizerResponsibility_body,
                        style: const TextStyle(
                          color: AppColors.textOnDarkSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      if (errorOrNull != null) ...[
                        AppSpacing.gapMd,
                        Text(
                          context
                              .l10n
                              .event_organizerResponsibility_errorGeneric,
                          style: TextStyle(
                            color: colorScheme.error,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(
                      label: context
                          .l10n
                          .event_organizerResponsibility_acceptButton,
                      isLoading: isSaving,
                      onPressed: isSaving ? null : () => _onAccept(context),
                      shape: AppButtonShape.pill,
                      height: 52,
                    ),
                    AppSpacing.gapSm,
                    AppTextButton(
                      label: context
                          .l10n
                          .event_organizerResponsibility_reviewButton,
                      onPressed: isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
