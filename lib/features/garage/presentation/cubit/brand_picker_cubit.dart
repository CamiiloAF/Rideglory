import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/data/colombia_motos_brands_data.dart';
import 'brand_picker_state.dart';

/// Buscador de marca (SEL) sobre el catálogo estático de motos en Colombia.
/// No hay I/O: la lista completa cabe en memoria y el filtro es síncrono.
@injectable
class BrandPickerCubit extends Cubit<BrandPickerState> {
  BrandPickerCubit()
    : super(
        BrandPickerState(
          query: '',
          results: List<String>.of(ColombiaMotosBrandsData.brands)..sort(),
        ),
      );

  final TextEditingController searchController = TextEditingController();

  void search(String query) {
    final trimmed = query.trim();
    final results = trimmed.isEmpty
        ? List<String>.of(ColombiaMotosBrandsData.brands)
        : ColombiaMotosBrandsData.brands
              .where(
                (brand) => brand.toLowerCase().contains(trimmed.toLowerCase()),
              )
              .toList();
    results.sort();
    emit(BrandPickerState(query: trimmed, results: results));
  }

  @override
  Future<void> close() {
    searchController.dispose();
    return super.close();
  }
}
