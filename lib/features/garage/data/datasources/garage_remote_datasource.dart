import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dto/vehicle_dto.dart';

/// Llamadas crudas a Supabase para el garaje: tabla `vehicles` y bucket
/// privado `vehicle-images`. Sin lógica de negocio: eso vive en el
/// repositorio.
@injectable
class GarageRemoteDatasource {
  GarageRemoteDatasource(this._client);

  final SupabaseClient _client;

  static const String _table = 'vehicles';
  static const String _bucket = 'vehicle-images';
  static const Duration _signedUrlTtl = Duration(hours: 1);

  String get _ownerId => _client.auth.currentUser!.id;

  Future<List<VehicleDto>> fetchVehicles() async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('owner_id', _ownerId)
        .order('is_main', ascending: false)
        .order('created_at', ascending: false);
    return rows.map(VehicleDto.fromJson).toList();
  }

  Future<VehicleDto> insertVehicle(Map<String, dynamic> values) async {
    final row = await _client
        .from(_table)
        .insert({...values, 'owner_id': _ownerId})
        .select()
        .single();
    return VehicleDto.fromJson(row);
  }

  Future<VehicleDto> updateVehicle(
    String vehicleId,
    Map<String, dynamic> values,
  ) async {
    final row = await _client
        .from(_table)
        .update(values)
        .eq('id', vehicleId)
        .select()
        .single();
    return VehicleDto.fromJson(row);
  }

  Future<void> archiveVehicle(String vehicleId) async {
    await _client
        .from(_table)
        .update({'archived_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', vehicleId);
  }

  Future<void> unarchiveVehicle(String vehicleId) async {
    await _client
        .from(_table)
        .update({'archived_at': null})
        .eq('id', vehicleId);
  }

  /// Pone `vehicleId` como principal y quita el flag de las demás; no hay
  /// trigger en la base para esto porque puede haber más de una moto
  /// candidata en el mismo `UPDATE`, así que se resuelve aquí en dos pasos.
  Future<void> setMainVehicle(String vehicleId) async {
    await _client
        .from(_table)
        .update({'is_main': false})
        .eq('owner_id', _ownerId)
        .neq('id', vehicleId);
    await _client.from(_table).update({'is_main': true}).eq('id', vehicleId);
  }

  Future<void> deleteVehicle(String vehicleId) async {
    await _client.from(_table).delete().eq('id', vehicleId);
  }

  /// `image_path` de la moto, para poder borrar su foto de Storage antes de
  /// eliminarla. `null` si nunca tuvo una.
  Future<String?> fetchImagePath(String vehicleId) async {
    final row = await _client
        .from(_table)
        .select('image_path')
        .eq('id', vehicleId)
        .single();
    return row['image_path'] as String?;
  }

  /// Sube la foto y devuelve el `image_path` guardado en la fila.
  Future<String> uploadImage({
    required String vehicleId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final path = '$_ownerId/$vehicleId.$extension';
    await _client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$extension',
            upsert: true,
          ),
        );
    return path;
  }

  /// Borra la foto de la moto del bucket, si tiene una: se usa al
  /// eliminarla del garaje.
  Future<void> deleteImage(String imagePath) async {
    await _client.storage.from(_bucket).remove([imagePath]);
  }

  Future<String> createSignedImageUrl(String imagePath) {
    return _client.storage
        .from(_bucket)
        .createSignedUrl(imagePath, _signedUrlTtl.inSeconds);
  }

  /// Vencimientos de documentos de un grupo de motos, para la alerta de la
  /// celda de galería (D5: el garaje muestra el estado legal de un vistazo).
  Future<List<Map<String, dynamic>>> fetchDocumentExpiries(
    List<String> vehicleIds,
  ) async {
    if (vehicleIds.isEmpty) return [];
    return _client
        .from('vehicle_documents')
        .select('vehicle_id, kind, expiry_date')
        .inFilter('vehicle_id', vehicleIds);
  }
}
