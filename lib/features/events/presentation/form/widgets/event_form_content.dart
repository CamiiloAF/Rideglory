import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_basic_info_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_date_time_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_details_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_locations_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_recommendations_section.dart';

class EventFormContent extends StatelessWidget {
  const EventFormContent({super.key});

  Map<String, dynamic> _getInitialValues(EventFormCubit cubit) {
    return cubit.state.maybeWhen(
      editing: (event) => {
        EventFormFields.name: event.name,
        EventFormFields.description: event.description,
        EventFormFields.city: event.city,
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
        EventFormFields.allowedBrands: event.allowedBrands,
        EventFormFields.price: event.price?.toString() ?? '',
        EventFormFields.recommendations: event.recommendations ?? '',
      },
      orElse: () => {
        EventFormFields.difficulty: EventDifficulty.one,
        EventFormFields.eventType: EventType.onRoad,
        EventFormFields.isMultiDay: false,
        EventFormFields.dateRange: DateTimeRange(
          start: DateTime.now(),
          end: DateTime.now(),
        ),
        EventFormFields.meetingTime: DateTime.now(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EventFormCubit>();
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: FormBuilder(
        key: cubit.formKey,
        initialValue: _getInitialValues(cubit),
        child: BlocBuilder<EventFormCubit, EventFormState>(
          builder: (context, state) {
            final isEditing = state.maybeWhen(
              editing: (_) => true,
              orElse: () => false,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Información Básica ───────────────────────────
                _FormCard(
                  icon: Icons.info_outline,
                  title: EventStrings.basicInfo,
                  colorScheme: cs,
                  child: Column(
                    children: [
                      EventFormBasicInfoSection(isEditing: isEditing),
                      const SizedBox(height: 16),
                      const EventFormDateTimeSection(),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Detalles Técnicos ────────────────────────────
                _FormCard(
                  icon: Icons.settings_outlined,
                  title: 'Detalles Técnicos',
                  colorScheme: cs,
                  child: EventFormDetailsSection(),
                ),

                const SizedBox(height: 16),

                // ── Logística de Ruta ────────────────────────────
                _FormCard(
                  icon: Icons.route_outlined,
                  title: 'Logística de Ruta',
                  colorScheme: cs,
                  child: const EventFormLocationsSection(),
                ),

                const SizedBox(height: 16),

                // ── Recomendaciones ──────────────────────────────
                _FormCard(
                  icon: Icons.tips_and_updates_outlined,
                  title: EventStrings.recommendations,
                  colorScheme: cs,
                  child: EventFormRecommendationsSection(
                    initialValue: cubit.state.maybeWhen(
                      editing: (event) => event.recommendations,
                      orElse: () => null,
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card container for each section (matches Stitch design)
// ─────────────────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final ColorScheme colorScheme;

  const _FormCard({
    required this.icon,
    required this.title,
    required this.child,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

