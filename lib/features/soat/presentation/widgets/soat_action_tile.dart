import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Fila de acción discreta (ícono + etiqueta + chevron) pensada para agruparse
/// dentro de una card. Evita la saturación de color de varios botones llenos
/// apilados: la jerarquía la marca un único CTA principal y estas acciones
/// secundarias quedan neutras.
class SoatActionTile extends StatelessWidget {
  const SoatActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.loading = false,
    this.showDivider = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Tinte del ícono y la etiqueta. Por defecto, texto primario (neutro).
  final Color? color;
  final bool loading;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.textOnDarkPrimary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDivider)
          const Divider(height: 1, color: AppColors.darkBorderPrimary),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: loading ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: tint),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: tint,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (loading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: tint,
                      ),
                    )
                  else
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.textOnDarkTertiary,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
