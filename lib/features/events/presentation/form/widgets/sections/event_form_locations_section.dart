import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/screens/event_route_config_screen.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/locations/route_points_card.dart';

/// Sección de ruta — diseño Pencil MmZfp.
///
/// Muestra los puntos de ruta (SALIDA, WAYPOINTS, LLEGADA) en modo solo lectura.
/// El botón "Editar ruta >" navega a [EventRouteConfigScreen] para crear/editar.
class EventFormLocationsSection extends StatelessWidget {
  const EventFormLocationsSection({super.key});

  static const _labelStyle = TextStyle(
    fontFamily: 'Space Grotesk',
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
    color: AppColors.textOnDarkTertiary,
  );

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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventFormCubit, EventFormState>(
      buildWhen: (prev, curr) =>
          prev.waypoints != curr.waypoints ||
          prev.waypointLocations != curr.waypointLocations ||
          prev.showRouteError != curr.showRouteError,
      builder: (context, state) {
        final hasRoute = state.waypoints.isNotEmpty;
        final buttonLabel = hasRoute
            ? context.l10n.route_edit_button
            : context.l10n.route_create_button;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.l10n.event_route, style: _labelStyle),
                GestureDetector(
                  onTap: () => _openRouteConfig(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        buttonLabel,
                        style: const TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            RoutePointsCard(
              state: state,
              onEmptyTap: hasRoute ? null : () => _openRouteConfig(context),
            ),
            if (state.showRouteError) ...[
              const SizedBox(height: 8),
              Text(
                context.l10n.event_route_required_error,
                style: const TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 12,
                  color: AppColors.error,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
