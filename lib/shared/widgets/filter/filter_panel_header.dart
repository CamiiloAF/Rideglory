import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';

class FilterPanelHeader extends StatelessWidget {
  final bool hasActiveFilters;
  final VoidCallback onClearAll;

  const FilterPanelHeader({
    super.key,
    required this.hasActiveFilters,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.l10n.filter_title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnDarkPrimary,
            ),
          ),
          if (hasActiveFilters)
            GestureDetector(
              onTap: onClearAll,
              child: Text(
                context.l10n.filter_clearAll,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
