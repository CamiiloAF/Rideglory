import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_locations_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_max_participants_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_multi_brand_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_price_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/event_step_nav_bar.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/step_title.dart';

/// Step 3: Ruta y detalles — diseño Pencil XbcHD.
///
/// - PUNTOS DE RUTA: salida, waypoints, llegada (+ botón Editar ruta)
/// - DISTANCIA ESTIMADA: solo visible cuando hay waypoints configurados
/// - CUPO MÁXIMO: stepper de participantes
/// - PRECIO POR PERSONA: stepper de precio
// NOTE: IndexedStack mantiene MapboxMap + QuillEditor vivos simultáneamente.
class EventFormStep3 extends StatelessWidget {
  const EventFormStep3({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepTitle(
                  title: context.l10n.event_step3_title,
                  subtitle: context.l10n.event_step3_subtitle,
                ),
                const SizedBox(height: 20),
                const EventFormLocationsSection(),
                AppSpacing.gapXxl,
                const EventFormMaxParticipantsSection(),
                AppSpacing.gapXxl,
                const EventFormPriceSection(),
                AppSpacing.gapXxl,
                const EventFormMultiBrandSection(),
              ],
            ),
          ),
        ),
        const EventStepNavBar(),
      ],
    );
  }
}
