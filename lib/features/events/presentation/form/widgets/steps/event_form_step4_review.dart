import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/difficulty_flames.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/event_step_nav_bar.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/review_card.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/review_row.dart';

/// Step 4: Summary review before publishing.
///
/// Shows 3 cards (Básico, Configuración, Ruta) each with an "Editar" button
/// that calls [EventFormCubit.goToStep]. Publish + save-draft buttons live
/// inside [EventStepNavBar] (step 4 branch).
class EventFormStep4Review extends StatelessWidget {
  const EventFormStep4Review({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventFormCubit, EventFormState>(
      builder: (context, state) {
        final cubit = context.read<EventFormCubit>();
        final formData = FormBuilder.of(context)?.value ?? {};

        final name = formData[EventFormFields.name] as String? ?? '';
        final description =
            formData[EventFormFields.description] as String? ?? '';
        final dateRange =
            formData[EventFormFields.dateRange] as DateTimeRange?;
        final meetingTime =
            formData[EventFormFields.meetingTime] as DateTime?;
        final difficulty =
            formData[EventFormFields.difficulty] as EventDifficulty? ??
                EventDifficulty.one;
        final eventType =
            formData[EventFormFields.eventType] as EventType? ??
                EventType.tourism;
        final isMultiBrand =
            formData[EventFormFields.isMultiBrand] as bool? ?? true;
        final allowedBrands =
            formData[EventFormFields.allowedBrands] as List<dynamic>? ?? [];
        final maxParticipants =
            formData[EventFormFields.maxParticipants] as int?;
        final priceStr = formData[EventFormFields.price] as String?;
        final isFree =
            formData[EventFormFields.isFreeEvent] as bool? ?? false;

        final dateText = dateRange != null
            ? DateFormat('dd/MM/yyyy').format(dateRange.start)
            : context.l10n.event_step_review_noDate;
        final timeText = meetingTime != null
            ? DateFormat('HH:mm').format(meetingTime)
            : '';

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card 1: Información básica
                    ReviewCard(
                      title: context.l10n.event_step_review_basicSection,
                      onEdit: () => cubit.goToStep(0),
                      rows: [
                        ReviewRow(
                          label: '',
                          value: name.isNotEmpty
                              ? name
                              : context.l10n.event_step_review_noName,
                          isTitle: true,
                        ),
                        if (description.isNotEmpty)
                          ReviewRow(
                            label: '',
                            value: description,
                            isSubtitle: true,
                          ),
                        ReviewRow(
                          label: '',
                          value: timeText.isNotEmpty
                              ? '$dateText • $timeText'
                              : dateText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Card 2: Configuración
                    ReviewCard(
                      title: context.l10n.event_step_review_detailsSection,
                      onEdit: () => cubit.goToStep(1),
                      rows: [
                        ReviewRow(
                          label: context.l10n.event_step_review_difficulty,
                          value: difficulty.label,
                          trailingWidget: DifficultyFlames(
                            level: difficulty.value,
                          ),
                        ),
                        ReviewRow(
                          label: context.l10n.event_step_review_type,
                          value: eventType.label,
                        ),
                        ReviewRow(
                          label: context.l10n.event_step_review_brands,
                          value: isMultiBrand
                              ? context.l10n.event_step_review_allBrands
                              : allowedBrands.isNotEmpty
                                  ? allowedBrands.join(', ')
                                  : context.l10n.event_step_review_allBrands,
                        ),
                        ReviewRow(
                          label: context.l10n.event_step_review_maxParticipants,
                          value: maxParticipants != null
                              ? '$maxParticipants'
                              : context.l10n.event_step_review_noLimit,
                        ),
                        ReviewRow(
                          label: context.l10n.event_step_review_price,
                          value: (isFree ||
                                  priceStr == null ||
                                  priceStr.isEmpty ||
                                  priceStr == '0')
                              ? context.l10n.event_step_review_free
                              : '\$$priceStr',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Card 3: Ruta
                    ReviewCard(
                      title: context.l10n.event_step_review_routeSection,
                      onEdit: () => cubit.goToStep(2),
                      rows: [
                        ReviewRow(
                          label:
                              context.l10n.event_step_review_meetingPoint,
                          value: state.meetingPointName?.isNotEmpty == true
                              ? state.meetingPointName!
                              : context.l10n.event_step_review_noMeetingPoint,
                        ),
                        ReviewRow(
                          label: context.l10n.event_step_review_destination,
                          value: state.destinationName?.isNotEmpty == true
                              ? state.destinationName!
                              : context.l10n.event_step_review_noDestination,
                        ),
                        if (state.waypoints.isNotEmpty)
                          ReviewRow(
                            label: context.l10n.event_step_review_waypoints,
                            value: state.waypoints.length.toString(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const EventStepNavBar(),
          ],
        );
      },
    );
  }
}
