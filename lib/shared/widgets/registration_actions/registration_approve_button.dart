import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Botón "Aprobar" del diseño TUJA0: fondo verde sólido (#22C55E) con texto e
/// ícono oscuros. Usado en la tarjeta de asistente y en el detalle (owner).
class RegistrationApproveButton extends StatelessWidget {
  const RegistrationApproveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 48,
  });

  final String label;
  final VoidCallback onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Material(
        color: AppColors.statusGreen,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: AppColors.darkBgPrimary,
                ),
                AppSpacing.hGapSm,
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.darkBgPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
