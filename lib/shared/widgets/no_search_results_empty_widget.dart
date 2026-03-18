import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/extensions/theme_extensions.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

// TODO Update strings
class NoSearchResultsEmptyWidget extends StatelessWidget {
  const NoSearchResultsEmptyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron resultados',
              style: context.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta ajustar los filtros o la búsqueda',
              style: context.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
