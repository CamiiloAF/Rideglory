import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

/// Step 4: Resumen de revisión antes de publicar.
///
/// 3 cards alineadas con los 3 steps de entrada:
/// - Card 1 "Información básica" → step 1 (nombre, portada, fecha, tipo, dificultad)
/// - Card 2 "Descripción"        → step 2
/// - Card 3 "Ruta y detalles"    → step 3 (ruta, marcas, participantes, precio)
class EventFormStep4Review extends StatelessWidget {
  const EventFormStep4Review({super.key});

  static final _priceFmt = NumberFormat('#,##0', 'es_CO');

  String _formatBrands(
    BuildContext context, {
    required List<String> brands,
  }) {
    if (brands.isEmpty) {
      return context.l10n.event_step_review_allBrands;
    }
    const maxVisible = 2;
    if (brands.length <= maxVisible) return brands.join(', ');
    final visible = brands.take(maxVisible).join(', ');
    final extra = brands.length - maxVisible;
    return '$visible y $extra más';
  }

  String _truncateAddress(String full) {
    final commaIndex = full.indexOf(',');
    return commaIndex > 0 ? full.substring(0, commaIndex) : full;
  }

  String _resolveMeetingPoint(BuildContext context, EventFormState state) {
    if (state.waypoints.isEmpty) {
      return context.l10n.event_step_review_noMeetingPoint;
    }
    return _truncateAddress(state.waypoints.first);
  }

  String _formatPrice(String? raw) {
    final digits = raw?.replaceAll(RegExp(r'[^\d]'), '') ?? '';
    final value = int.tryParse(digits) ?? 0;
    return '\$${_priceFmt.format(value).replaceAll(',', '.')} COP';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventFormCubit, EventFormState>(
      builder: (context, state) {
        final cubit = context.read<EventFormCubit>();
        final formData = cubit.formKey.currentState?.instantValue ?? {};
        final imageState = context.watch<FormImageCubit>().state;
        final imageData = imageState.whenOrNull(data: (data) => data);
        final hasCover = imageData?.displayImageUrl?.isNotEmpty == true;

        final name = formData[EventFormFields.name] as String? ?? '';
        final description =
            formData[EventFormFields.description] as String? ?? '';
        final dateRange = formData[EventFormFields.dateRange] as DateTimeRange?;
        final meetingTime = formData[EventFormFields.meetingTime] as DateTime?;
        final isMultiDay = dateRange != null &&
            dateRange.end.isAfter(dateRange.start);
        final difficulty =
            formData[EventFormFields.difficulty] as EventDifficulty? ??
            EventDifficulty.one;
        final eventType =
            formData[EventFormFields.eventType] as EventType? ??
            EventType.onRoad;
        final allowedBrands =
            formData[EventFormFields.allowedBrands] as List<dynamic>? ?? [];
        final maxParticipants =
            formData[EventFormFields.maxParticipants] as int?;
        final priceStr = formData[EventFormFields.price] as String?;
        final isFree =
            priceStr == null || priceStr.isEmpty || priceStr == '0';

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
                      title: cubit.isEditing
                          ? context.l10n.event_step4_editTitle
                          : context.l10n.event_step4_title,
                      subtitle: cubit.isEditing
                          ? context.l10n.event_step4_editSubtitle
                          : context.l10n.event_step4_subtitle,
                    ),
                    const SizedBox(height: 20),

                    // Card 1: Información básica — espejo del step 1
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
                          label: context.l10n.event_step_review_coverLabel,
                          value: hasCover
                              ? context.l10n.event_step_review_coverLoaded
                              : context.l10n.event_step_review_coverNone,
                        ),
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
                        ),
                        ReviewRow(
                          label: context.l10n.event_step_review_type,
                          value: eventType.label,
                        ),
                        ReviewRow(
                          label: context.l10n.event_step_review_difficulty,
                          value: difficulty.label,
                          trailingWidget: DifficultyFlames(
                            level: difficulty.value,
                          ),
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 2: Descripción — espejo del step 2
                    ReviewCard(
                      title: context.l10n.event_step2_title,
                      icon: Icons.notes_rounded,
                      onEdit: () => cubit.goToStep(1),
                      rows: [
                        ReviewRow(
                          label: context.l10n.event_step_review_descLabel,
                          value: description.isNotEmpty
                              ? context.l10n.event_step_review_descAdded
                              : context.l10n.event_step_review_noDescription,
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 3: Ruta y detalles — espejo del step 3
                    ReviewCard(
                      title: context.l10n.event_step3_title,
                      icon: Icons.route,
                      onEdit: () => cubit.goToStep(2),
                      rows: [
                        ReviewRow(
                          label: context.l10n.event_step_review_meetingPoint,
                          value: _resolveMeetingPoint(context, state),
                        ),
                        if (state.waypoints.length > 1)
                          ReviewRow(
                            label: context.l10n.event_step_review_destination,
                            value: _truncateAddress(state.waypoints.last),
                          ),
                        if (state.waypoints.length > 2)
                          ReviewRow(
                            label: context.l10n.event_step_review_waypoints,
                            value: '${state.waypoints.length - 2}',
                          ),
                        ReviewRow(
                          label: context.l10n.event_step_review_brands,
                          value: _formatBrands(
                            context,
                            brands: allowedBrands.cast<String>(),
                          ),
                        ),
                        ReviewRow(
                          label: context.l10n.event_step_review_maxParticipants,
                          value: maxParticipants != null
                              ? '$maxParticipants'
                              : context.l10n.event_step_review_noLimit,
                        ),
                        ReviewRow(
                          label: context.l10n.event_step_review_price,
                          value: isFree
                              ? context.l10n.event_step_review_free
                              : _formatPrice(priceStr),
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
