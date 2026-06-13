import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/difficulty_flames.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/event_step_nav_bar.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/review_card.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/review_row.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/step_title.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';

/// Step 4: Summary review before publishing.
///
/// Shows 4 cards (Básico, Configuración, Ruta, Fecha y hora) per Pencil FW3Hd.
/// Each card has an icon, title, "Editar" button, and label/value rows.
class EventFormStep4Review extends StatelessWidget {
  const EventFormStep4Review({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventFormCubit, EventFormState>(
      builder: (context, state) {
        final cubit = context.read<EventFormCubit>();
        final formData = FormBuilder.of(context)?.value ?? {};
        final imageState = context.watch<FormImageCubit>().state;
        final imageData = imageState.whenOrNull(data: (data) => data);
        final hasCover = imageData?.displayImageUrl?.isNotEmpty == true;

        final name = formData[EventFormFields.name] as String? ?? '';
        final description =
            formData[EventFormFields.description] as String? ?? '';
        final dateRange =
            formData[EventFormFields.dateRange] as DateTimeRange?;
        final meetingTime =
            formData[EventFormFields.meetingTime] as DateTime?;
        final isMultiDay =
            formData[EventFormFields.isMultiDay] as bool? ?? false;
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
            ? DateFormat('EEE, dd MMM yyyy', 'es').format(dateRange.start)
            : context.l10n.event_step_review_noDate;
        final timeText = meetingTime != null
            ? DateFormat('hh:mm a').format(meetingTime)
            : '';

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StepTitle(
                      title: context.l10n.event_step4_title,
                      subtitle: context.l10n.event_step4_subtitle,
                    ),
                    const SizedBox(height: 20),
                    // Card 1: Información básica
                    ReviewCard(
                      title: context.l10n.event_step_review_basicSection,
                      icon: Icons.info_outline,
                      onEdit: () => cubit.goToStep(0),
                      rows: [
                        ReviewRow(
                          label: context.l10n.event_step_review_nameLabel,
                          value: name.isNotEmpty
                              ? name
                              : context.l10n.event_step_review_noName,
                        ),
                        ReviewRow(
                          label: context.l10n.event_step_review_descLabel,
                          value: description.isNotEmpty
                              ? context.l10n.event_step_review_descAdded
                              : context.l10n.event_step_review_noDescription,
                        ),
                        ReviewRow(
                          label: context.l10n.event_step_review_coverLabel,
                          value: hasCover
                              ? context.l10n.event_step_review_coverLoaded
                              : context.l10n.event_step_review_coverNone,
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Card 2: Configuración
                    ReviewCard(
                      title: context.l10n.event_step_review_detailsSection,
                      icon: Icons.tune,
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
                              : '\$$priceStr COP',
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Card 3: Ruta
                    ReviewCard(
                      title: context.l10n.event_step_review_routeSection,
                      icon: Icons.route,
                      onEdit: () => cubit.goToStep(2),
                      rows: [
                        ReviewRow(
                          label: context.l10n.event_step_review_meetingPoint,
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
                            value: '${state.waypoints.length}',
                          ),
                        ReviewRow(
                          label: context.l10n.event_step_review_brands,
                          value: isMultiBrand
                              ? context.l10n.event_step_review_allBrands
                              : allowedBrands.isNotEmpty
                                  ? allowedBrands.join(', ')
                                  : context.l10n.event_step_review_allBrands,
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Card 4: Fecha y hora
                    ReviewCard(
                      title: context.l10n.event_step_review_dateTimeSection,
                      icon: Icons.calendar_today_outlined,
                      onEdit: () => cubit.goToStep(0),
                      rows: [
                        ReviewRow(
                          label: context.l10n.event_step_review_date,
                          value: dateText,
                        ),
                        if (timeText.isNotEmpty)
                          ReviewRow(
                            label: context.l10n.event_step_review_meetingTime,
                            value: timeText,
                          ),
                        ReviewRow(
                          label: context.l10n.event_step_review_multiDay,
                          value: isMultiDay
                              ? context.l10n.event_step_review_yes
                              : context.l10n.event_step_review_no,
                          showDivider: false,
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
