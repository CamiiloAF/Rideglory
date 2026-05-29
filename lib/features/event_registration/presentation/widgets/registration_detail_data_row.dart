import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Fila etiqueta/valor dentro del contenedor de filas de
/// [RegistrationDetailDataCard]. Corresponde a `rowLabel`/`rowValue` del diseño
/// Pencil (padding 11x14, etiqueta secundaria, valor blanco).
class RegistrationDetailDataRow extends StatelessWidget {
  const RegistrationDetailDataRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.showDivider = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.darkBorderPrimary,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textOnDarkSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: valueColor ?? AppColors.textOnDarkPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
