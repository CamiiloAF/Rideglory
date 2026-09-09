import 'package:freezed_annotation/freezed_annotation.dart';

part 'brand_picker_state.freezed.dart';

@freezed
abstract class BrandPickerState with _$BrandPickerState {
  const factory BrandPickerState({
    required String query,
    required List<String> results,
  }) = _BrandPickerState;
}
