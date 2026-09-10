import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design_system/components/app_switch_tile.dart';
import '../../../../design_system/components/app_text_field.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/create_event_cubit.dart';
import '../cubit/create_event_state.dart';
import 'create_event_summary_card.dart';
import 'registration_section_label.dart';

/// Paso 3 del asistente: cupos, precio y resumen final.
class CreateEventStep3 extends StatefulWidget {
  const CreateEventStep3({required this.state, required this.cubit, super.key});

  final CreateEventState state;
  final CreateEventCubit cubit;

  @override
  State<CreateEventStep3> createState() => _CreateEventStep3State();
}

class _CreateEventStep3State extends State<CreateEventStep3> {
  late final TextEditingController _spotsController = TextEditingController(
    text: widget.state.maxParticipants.toString(),
  );
  late final TextEditingController _priceController = TextEditingController(
    text: widget.state.price == 0 ? '' : widget.state.price.toString(),
  );

  @override
  void dispose() {
    _spotsController.dispose();
    _priceController.dispose();
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
            context.l10n.events_create_step3_title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: context.l10n.events_create_spots_label,
            controller: _spotsController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            suffixText: context.l10n.events_create_spots_suffix,
            helperText: context.l10n.events_create_spots_hint,
            onChanged: (value) =>
                widget.cubit.updateMaxParticipants(int.tryParse(value) ?? 0),
          ),
          const SizedBox(height: 16),
          AppSwitchTile(
            label: context.l10n.events_create_free_label,
            subtitle: context.l10n.events_create_free_subtitle,
            value: widget.state.isFree,
            onChanged: widget.cubit.toggleFree,
          ),
          if (!widget.state.isFree) ...[
            const SizedBox(height: 16),
            AppTextField(
              label: context.l10n.events_create_price_label,
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) =>
                  widget.cubit.updatePrice(int.tryParse(value) ?? 0),
            ),
          ],
          const SizedBox(height: 16),
          RegistrationSectionLabel(context.l10n.events_create_summary_label),
          const SizedBox(height: 10),
          CreateEventSummaryCard(
            name: widget.state.name,
            startAt: widget.state.startAt,
            price: widget.state.isFree ? 0 : widget.state.price,
          ),
        ],
      ),
    );
  }
}
