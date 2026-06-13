import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';

/// Fila de selección de fecha/hora dentro del card de FECHA Y HORA.
///
/// Design spec (Pencil AybHb):
/// - Left: 32×32 icon circle (cornerRadius 8, fill $accent-subtle) + text col
/// - Text col: label 11px w700 text-tertiary + value 14px normal
/// - Right: chevron-right 18px text-tertiary
/// - Padding: [14, 16] vertical × horizontal
class EventDatePickerRow extends StatelessWidget {
  const EventDatePickerRow({
    super.key,
    required this.icon,
    required this.labelText,
    required this.valueText,
    required this.hasValue,
    required this.onTap,
    this.errorText,
  });

  final IconData icon;
  final String labelText;
  final String valueText;
  final bool hasValue;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    labelText,
                    style: const TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnDarkTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    valueText,
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 14,
                      color: hasValue
                          ? AppColors.textOnDarkPrimary
                          : AppColors.textOnDarkTertiary,
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      errorText!,
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 11,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textOnDarkTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
