import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

import '../dto/nominatim_result_dto.dart';

/// Buscador de destino sin mapa interactivo (D10): la API pública de
/// Nominatim/OpenStreetMap, sin llave. Requiere un `User-Agent` propio por
/// su política de uso — nunca vacío ni el genérico del paquete `http`.
@injectable
class NominatimDatasource {
  const NominatimDatasource(this._client);

  final http.Client _client;

  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';
  static const String _userAgent =
      'Rideglory/1.0 (com.camiloagudelo.rideglory; contacto@rideglory.co)';

  Future<List<NominatimResultDto>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'format': 'json',
        'countrycodes': 'co',
        'addressdetails': '0',
        'limit': '8',
        'q': trimmed,
      },
    );
    final response = await _client.get(
      uri,
      headers: const {'User-Agent': _userAgent},
    );
    if (response.statusCode != 200) {
      throw Exception('nominatim_error: ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map(
          (item) => NominatimResultDto.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
