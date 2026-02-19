import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

class NoSearchResultsEmptyWidget extends StatelessWidget {
  const NoSearchResultsEmptyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No se encontraron resultados',
              style: context.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta ajustar los filtros o la búsqueda',
              style: context.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
