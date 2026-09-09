import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radii.dart';

/// Bloque destacado con el kilometraje actual de una moto.
///
/// Pencil: UrND6
class OdometerBlock extends StatelessWidget {
  const OdometerBlock({
    required this.kilometers,
    required this.detail,
    super.key,
  });

  /// Ya formateado con separador de miles, ej. `18.450`.
  final String kilometers;

  /// Ej. `Yamaha MT-03 · actualizado el 12 ago`.
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
      decoration: BoxDecoration(
        color: colors.block,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                kilometers,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                  color: colors.onBlock,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'km',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: colors.onBlockSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: TextStyle(fontSize: 12, color: colors.onBlockSecondary),
          ),
        ],
      ),
    );
  }
}
