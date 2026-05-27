import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/locations/route_point_row.dart';

class SimpleRouteCard extends StatelessWidget {
  const SimpleRouteCard({super.key, required this.state});

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
              RoutePointRow(
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
              RoutePointRow(
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
