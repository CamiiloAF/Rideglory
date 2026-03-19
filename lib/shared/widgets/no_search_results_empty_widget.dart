import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class NoSearchResultsEmptyWidget extends StatelessWidget {
  const NoSearchResultsEmptyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTightHeight =
                constraints.maxHeight > 0 && constraints.maxHeight < 150;

            final iconSize = isTightHeight ? 72.0 : 80.0;
            final gapAfterIcon = isTightHeight
                ? AppSpacing.gapMd
                : AppSpacing.gapLg;
            final gapBetweenTexts = isTightHeight
                ? AppSpacing.gapXs
                : AppSpacing.gapSm;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: iconSize,
                  color: cs.onSurfaceVariant,
                ),
                gapAfterIcon,
                Text(
                  context.l10n.noResults,
                  style: context.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                gapBetweenTexts,
                Text(
                  context.l10n.noSearchResultsHint,
                  style: context.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
