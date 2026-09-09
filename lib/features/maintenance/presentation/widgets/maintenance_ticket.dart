import 'package:flutter/material.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_radii.dart';

/// El bloque destacado del detalle: kilometraje del registro y
/// "moto · fecha larga" debajo (Pencil: `Tiquete`).
class MaintenanceTicket extends StatelessWidget {
  const MaintenanceTicket({
    required this.odometerLabel,
    required this.subtitle,
    super.key,
  });

  final String odometerLabel;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            odometerLabel,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              height: 1.05,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
