import 'package:flutter/material.dart';

import '../../../../design_system/components/app_text_field.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/create_event_cubit.dart';
import '../cubit/create_event_state.dart';
import 'create_event_destination_field.dart';
import 'create_event_difficulty_chips.dart';

/// Paso 2 del asistente: destino, ruta y dificultad.
class CreateEventStep2 extends StatefulWidget {
  const CreateEventStep2({required this.state, required this.cubit, super.key});

  final CreateEventState state;
  final CreateEventCubit cubit;

  @override
  State<CreateEventStep2> createState() => _CreateEventStep2State();
}

class _CreateEventStep2State extends State<CreateEventStep2> {
  late final TextEditingController _routeController = TextEditingController(
    text: widget.state.routeText,
  );

  @override
  void dispose() {
    _routeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.events_create_step2_title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 16),
          CreateEventDestinationField(
            query: widget.state.destinationQuery,
            results: widget.state.destinationResults,
            cubit: widget.cubit,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: context.l10n.events_create_route_label,
            controller: _routeController,
            helperText: context.l10n.events_create_route_hint,
            onChanged: widget.cubit.updateRouteText,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.events_create_difficulty_label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          CreateEventDifficultyChips(
            selected: widget.state.difficulty,
            onSelected: widget.cubit.selectDifficulty,
          ),
        ],
      ),
    );
  }
}
