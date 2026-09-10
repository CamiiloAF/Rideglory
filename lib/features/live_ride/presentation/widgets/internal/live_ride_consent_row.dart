import 'package:flutter/material.dart';

import '../../../../../design_system/tokens/app_colors.dart';

/// Fila informativa (icono + texto) de las hojas de consentimiento LV2 y
/// LV2b. Interno del feature: no es un control reusable en otras
/// pantallas.
class LiveRideConsentRow extends StatelessWidget {
  const LiveRideConsentRow({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: colors.text,
            ),
          ),
        ),
      ],
    );
  }
}
