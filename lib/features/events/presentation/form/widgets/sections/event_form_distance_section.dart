import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';

/// Sección "DISTANCIA ESTIMADA" — diseño Pencil XbcHD.
///
/// Solo visible cuando hay waypoints configurados en la ruta.
class EventFormDistanceSection extends StatelessWidget {
  const EventFormDistanceSection({super.key});

  static const _labelStyle = TextStyle(
    fontFamily: 'Space Grotesk',
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
    color: AppColors.textOnDarkTertiary,
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventFormCubit, EventFormState>(
      buildWhen: (prev, curr) =>
          prev.waypoints != curr.waypoints ||
          prev.waypointLocations != curr.waypointLocations,
      builder: (context, state) {
        final waypointCount = state.waypointLocations.length;
        if (waypointCount < 2) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSpacing.gapXxl,
            const Text('DISTANCIA ESTIMADA', style: _labelStyle),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkBorderPrimary),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2117),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.route,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '— km',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textOnDarkPrimary,
                        ),
                      ),
                      Text(
                        '$waypointCount puntos · distancia por calcular',
                        style: const TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 12,
                          color: AppColors.textOnDarkSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
