import 'package:flutter/material.dart';

import '../../../../l10n/l10n_extensions.dart';
import '../../../../shared/widgets/states/empty_state_view.dart';
import 'brand_picker_row.dart';

/// Lista de marcas filtradas por el buscador, con separadores por letra
/// inicial (como el `.pen`).
class BrandPickerList extends StatelessWidget {
  const BrandPickerList({required this.brands, required this.onSelected, super.key});

  final List<String> brands;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (brands.isEmpty) {
      return EmptyStateView(
        title: context.l10n.garage_brand_search_empty_title,
        body: context.l10n.garage_brand_search_empty,
      );
    }
    return ListView.builder(
      itemCount: brands.length,
      itemBuilder: (context, index) => BrandPickerRow(
        brand: brands[index],
        onTap: () => onSelected(brands[index]),
      ),
    );
  }
}
