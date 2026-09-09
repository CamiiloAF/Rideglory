import 'package:flutter/material.dart';

import '../../../../core/utils/thousands_input_formatter.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/register_maintenance_cubit.dart';
import '../cubit/register_maintenance_state.dart';
import '../widgets/maintenance_helper_note.dart';
import '../widgets/maintenance_odometer_input.dart';

/// Paso 2: kilometraje, prellenado con el odómetro actual de la moto. Si
/// el valor ingresado es menor, se avisa pero se deja continuar — puede
/// ser un registro tardío de algo que ya pasó (Pencil `x74Sa` / `ljdLM`).
class RegisterMaintenanceStep2 extends StatefulWidget {
  const RegisterMaintenanceStep2({
    required this.state,
    required this.cubit,
    super.key,
  });

  final RegisterMaintenanceState state;
  final RegisterMaintenanceCubit cubit;

  @override
  State<RegisterMaintenanceStep2> createState() =>
      _RegisterMaintenanceStep2State();
}

class _RegisterMaintenanceStep2State extends State<RegisterMaintenanceStep2> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ThousandsInputFormatter.format(widget.state.odometer) ?? '',
    );
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    widget.cubit.updateOdometer(
      ThousandsInputFormatter.parse(_controller.text)?.toInt(),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = context.l10n;
    final vehicle = widget.state.vehicle;
    final currentLabel =
        ThousandsInputFormatter.format(vehicle.currentMileage) ??
        '${vehicle.currentMileage}';
    final valueLabel =
        ThousandsInputFormatter.format(widget.state.odometer) ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.maintenance_register_step2_question,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 12),
          MaintenanceOdometerInput(
            controller: _controller,
            suffixLabel: l10n.maintenance_register_odometer_suffix,
          ),
          const SizedBox(height: 10),
          MaintenanceHelperNote(
            text: widget.state.isBelowCurrentOdometer
                ? l10n.maintenance_register_odometer_helper_past_record(
                    currentLabel,
                  )
                : l10n.maintenance_register_odometer_helper_will_update(
                    currentLabel,
                    valueLabel.isEmpty ? currentLabel : valueLabel,
                  ),
          ),
        ],
      ),
    );
  }
}
