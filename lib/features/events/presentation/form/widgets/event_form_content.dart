import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_basic_info_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_date_time_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_difficulty_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_event_type_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_locations_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_max_participants_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_multi_brand_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_price_section.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';
import 'package:rideglory/shared/widgets/form/form_image_section.dart';

/// Main scrollable content of the event form.
///
/// Section order matches Pencil frame zbCa0:
/// Cover → Información Básica → Fecha y Hora → Dificultad → Ruta →
/// Tipo de Evento → Marcas Permitidas → Máximo de Participantes → Precio
class EventFormContent extends StatelessWidget {
  const EventFormContent({super.key});

  Map<String, dynamic> _getInitialValues(EventFormCubit cubit) {
    if (!cubit.isEditing) {
      return {
        EventFormFields.difficulty: EventDifficulty.one,
        EventFormFields.eventType: EventType.tourism,
        EventFormFields.isMultiDay: false,
        EventFormFields.dateRange: DateTimeRange(
          start: DateTime.now(),
          end: DateTime.now(),
        ),
        EventFormFields.meetingTime: DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          7,
          0,
        ),
        EventFormFields.isMultiBrand: true,
        EventFormFields.allowedBrands: <String>[],
        EventFormFields.maxParticipants: null,
        EventFormFields.isFreeEvent: false,
      };
    }
    final event = cubit.editingEvent!;
    final routeType = event.waypoints.isNotEmpty ||
            (event.routeGeoJson?['routeType'] == 'custom')
        ? RouteType.custom
        : RouteType.simple;
    return {
      EventFormFields.routeType: routeType,
      EventFormFields.name: event.name,
      EventFormFields.description: event.description,
      EventFormFields.isMultiDay:
          event.endDate != null && event.endDate != event.startDate,
      EventFormFields.dateRange: DateTimeRange(
        start: event.startDate,
        end: event.endDate ?? event.startDate,
      ),
      EventFormFields.meetingTime: event.meetingTime,
      EventFormFields.difficulty: event.difficulty,
      EventFormFields.eventType: event.eventType,
      EventFormFields.meetingPoint: event.meetingPoint,
      EventFormFields.destination: event.destination,
      EventFormFields.isMultiBrand: event.allowedBrands.isEmpty,
      EventFormFields.allowedBrands: event.allowedBrands,
      EventFormFields.price: event.price?.toString() ?? '',
      EventFormFields.maxParticipants: event.maxParticipants,
      EventFormFields.isFreeEvent: event.isFree,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EventFormCubit>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: FormBuilder(
        key: cubit.formKey,
        initialValue: _getInitialValues(cubit),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover ──────────────────────────────────────────────────
            BlocBuilder<FormImageCubit, ResultState<FormImageData>>(
              builder: (context, imageState) {
                final imageData = imageState.whenOrNull(data: (data) => data);
                final hasLocalImage = imageData?.hasLocalImage == true;

                return FormImageSection(
                  imageUrl: hasLocalImage ? null : imageData?.displayImageUrl,
                  localImagePath:
                      hasLocalImage ? imageData?.displayImageUrl : null,
                  onPickImage: () =>
                      context.read<FormImageCubit>().pickImageFromGallery(),
                  onClearTap: hasLocalImage
                      ? context.read<FormImageCubit>().clearLocalImage
                      : null,
                  title: context.l10n.event_addEventCover,
                  hint: context.l10n.event_addEventCoverHint,
                  uploadButtonLabel: context.l10n.event_uploadImage,
                );
              },
            ),
            // ── Información Básica ─────────────────────────────────────
            AppSpacing.gapXxl,
            EventFormBasicInfoSection(
              isEditing: cubit.isEditing,
              descriptionInitialValue: cubit.editingEvent?.description,
            ),
            // ── Fecha y Hora ───────────────────────────────────────────
            AppSpacing.gapXxl,
            const EventFormDateTimeSection(),
            // ── Ruta ───────────────────────────────────────────────────
            AppSpacing.gapXxl,
            const EventFormLocationsSection(),
            // ── Dificultad ─────────────────────────────────────────────
            AppSpacing.gapXxl,
            const EventFormDifficultySection(),
            // ── Tipo de Evento ─────────────────────────────────────────
            AppSpacing.gapXxl,
            const EventFormEventTypeSection(),
            // ── Marcas Permitidas ──────────────────────────────────────
            AppSpacing.gapXxl,
            const EventFormMultiBrandSection(),
            // ── Máximo de Participantes ────────────────────────────────
            AppSpacing.gapXxl,
            const EventFormMaxParticipantsSection(),
            // ── Precio de Inscripción ──────────────────────────────────
            AppSpacing.gapXxl,
            const EventFormPriceSection(),
          ],
        ),
      ),
    );
  }

}
