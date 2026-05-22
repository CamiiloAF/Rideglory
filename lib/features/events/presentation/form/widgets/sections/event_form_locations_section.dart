import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/screens/event_route_config_screen.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_route_type_selector.dart';
import 'package:rideglory/shared/models/address_location.dart';
import 'package:rideglory/shared/widgets/form/app_place_autocomplete.dart';

/// Route section with dual behavior:
/// - Simple route: inline Route Card with meeting point + destination
///   autocomplete fields + map preview.
/// - Custom route: "Crear ruta personalizada" button → [EventRouteConfigScreen].
///   After configuration, shows map with numbered pins + polyline + waypoints list.
class EventFormLocationsSection extends StatelessWidget {
  const EventFormLocationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventFormCubit, EventFormState>(
      buildWhen: (prev, curr) =>
          prev.routeType != curr.routeType ||
          prev.meetingPointName != curr.meetingPointName ||
          prev.destinationName != curr.destinationName ||
          prev.meetingPointLocation != curr.meetingPointLocation ||
          prev.destinationLocation != curr.destinationLocation ||
          prev.waypoints != curr.waypoints ||
          prev.waypointLocations != curr.waypointLocations,
      builder: (context, state) {
        final isCustom = state.routeType == RouteType.custom;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.event_route,
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppColors.textOnDarkTertiary,
              ),
            ),
            const SizedBox(height: 10),
            EventRouteTypeSelector(
              onChanged: (type) {
                if (type == null) return;
                final cubit = context.read<EventFormCubit>();
                cubit.setRouteType(type);
                if (type == RouteType.simple) cubit.clearWaypoints();
              },
            ),
            const SizedBox(height: 12),
            if (isCustom)
              _CustomRouteSection(state: state)
            else
              _SimpleRouteCard(state: state),
          ],
        );
      },
    );
  }
}

// ── Simple route ────────────────────────────────────────────────────────────

class _SimpleRouteCard extends StatelessWidget {
  const _SimpleRouteCard({required this.state});

  final EventFormState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EventFormCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkBorderPrimary),
          ),
          child: Column(
            children: [
              _RoutePointRow(
                dotColor: AppColors.success,
                fieldName: EventFormFields.meetingPoint,
                hintText: context.l10n.event_route_meeting_point_hint,
                onPlaceSelected: (name, location) {
                  cubit.setRoute(
                    meetingPointName: name,
                    destinationName: state.destinationName ?? '',
                    meetingPointLocation: location,
                    destinationLocation: state.destinationLocation,
                  );
                },
              ),
              Container(height: 1, color: AppColors.darkBorderPrimary),
              _RoutePointRow(
                dotColor: AppColors.primary,
                fieldName: EventFormFields.destination,
                hintText: context.l10n.event_route_destination_hint,
                onPlaceSelected: (name, location) {
                  cubit.setRoute(
                    meetingPointName: state.meetingPointName ?? '',
                    destinationName: name,
                    meetingPointLocation: state.meetingPointLocation,
                    destinationLocation: location,
                  );
                },
              ),
              if (state.meetingPointLocation != null ||
                  state.destinationLocation != null ||
                  (state.meetingPointName?.isNotEmpty ?? false) ||
                  (state.destinationName?.isNotEmpty ?? false))
                RouteMapPreview(
                  meetingPoint: state.meetingPointName,
                  destination: state.destinationName,
                  meetingPointCoords: state.meetingPointLocation,
                  destinationCoords: state.destinationLocation,
                  inCard: true,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoutePointRow extends StatelessWidget {
  const _RoutePointRow({
    required this.dotColor,
    required this.fieldName,
    required this.hintText,
    required this.onPlaceSelected,
  });

  final Color dotColor;
  final String fieldName;
  final String hintText;
  final void Function(String name, AddressLocation? location) onPlaceSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppPlaceAutocompleteField(
              name: fieldName,
              labelText: '',
              hintText: hintText,
              placeType: PlaceAutocompleteType.establishment,
              isRequired: true,
              showMapPicker: true,
              compact: true,
              resolveCoords: true,
              textInputAction: TextInputAction.next,
              validator: FormBuilderValidators.required(
                errorText: fieldName == EventFormFields.meetingPoint
                    ? context.l10n.event_meetingPointRequired
                    : context.l10n.event_destinationRequired,
              ),
              onPlaceSelected: onPlaceSelected,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom route ─────────────────────────────────────────────────────────────

class _CustomRouteSection extends StatelessWidget {
  const _CustomRouteSection({required this.state});

  final EventFormState state;

  @override
  Widget build(BuildContext context) {
    final hasWaypoints = state.waypoints.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppButton(
          label: context.l10n.route_builder_title,
          style: AppButtonStyle.outlined,
          icon: Icons.route_outlined,
          onPressed: () => _openRouteConfig(context),
        ),
        if (hasWaypoints) ...[
          const SizedBox(height: 16),
          _CustomRouteSummaryCard(state: state),
        ],
      ],
    );
  }

  void _openRouteConfig(BuildContext context) {
    final cubit = context.read<EventFormCubit>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const EventRouteConfigScreen(),
        ),
      ),
    );
  }
}

class _CustomRouteSummaryCard extends StatelessWidget {
  const _CustomRouteSummaryCard({required this.state});

  final EventFormState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Waypoints list preview (max 3 shown)
          ...state.waypoints.take(3).toList().asMap().entries.map((entry) {
            return _WaypointPreviewRow(
              index: entry.key,
              name: entry.value,
              isLast: entry.key == state.waypoints.length - 1 ||
                  entry.key == 2,
            );
          }),
          if (state.waypoints.length > 3)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                '+${state.waypoints.length - 3} más',
                style: const TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 12,
                  color: AppColors.textOnDarkTertiary,
                ),
              ),
            ),
          // Map preview
          RouteMapPreview(
            waypointCoords: state.waypointLocations
                .whereType<AddressLocation>()
                .toList(),
            inCard: true,
          ),
        ],
      ),
    );
  }
}

class _WaypointPreviewRow extends StatelessWidget {
  const _WaypointPreviewRow({
    required this.index,
    required this.name,
    required this.isLast,
  });

  final int index;
  final String name;
  final bool isLast;

  Color get _dotColor {
    if (index == 0) return AppColors.success;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textOnDarkPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Container(height: 1, color: AppColors.darkBorderPrimary),
      ],
    );
  }
}
