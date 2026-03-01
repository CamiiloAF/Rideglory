import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

// TODO Update strings
class NoSearchResultsEmptyWidget extends StatelessWidget {
  const NoSearchResultsEmptyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark ||
        Theme.of(context).scaffoldBackgroundColor.value < 0xFF808080;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron resultados',
              style: context.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta ajustar los filtros o la búsqueda',
              style: context.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[500] : null,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
