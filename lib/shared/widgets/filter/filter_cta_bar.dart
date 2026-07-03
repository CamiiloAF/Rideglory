import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';

class FilterCtaBar extends StatelessWidget {
  final int activeFilterCount;

  /// Label of the left/secondary button (e.g. "Limpiar" or "Cancelar").
  final String secondaryLabel;

  /// Tapped on the left/secondary button.
  final VoidCallback onSecondary;
  final VoidCallback onApply;

  const FilterCtaBar({
    super.key,
    required this.activeFilterCount,
    required this.secondaryLabel,
    required this.onSecondary,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onSecondary,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.darkBgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: const Border.fromBorderSide(
                    BorderSide(color: AppColors.darkBorderPrimary),
                  ),
                ),
                child: Center(
                  child: Text(
                    secondaryLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnDarkSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onApply,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.l10n.filter_apply,
                      // Texto oscuro sobre el color primario (nunca blanco).
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkBgPrimary,
                      ),
                    ),
                    if (activeFilterCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.darkBgPrimary.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$activeFilterCount',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkBgPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
