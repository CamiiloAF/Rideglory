import 'package:freezed_annotation/freezed_annotation.dart';

part 'destination_suggestion.freezed.dart';

/// Un resultado del buscador de destino (Nominatim/OpenStreetMap) en el
/// paso 2 de crear rodada. Sin mapa interactivo en v2 (D10): el rider
/// escoge un resultado de texto y eso fija el punto exacto.
@freezed
abstract class DestinationSuggestion with _$DestinationSuggestion {
  const factory DestinationSuggestion({
    required String displayName,
    required double lat,
    required double lng,
  }) = _DestinationSuggestion;
}
