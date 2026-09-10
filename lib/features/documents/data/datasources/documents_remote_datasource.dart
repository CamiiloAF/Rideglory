import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dto/vehicle_document_dto.dart';

/// Llamadas crudas a Supabase para `vehicle_documents` y el bucket privado
/// `documents`.
@injectable
class DocumentsRemoteDatasource {
  DocumentsRemoteDatasource(this._client);

  final SupabaseClient _client;

  static const String _table = 'vehicle_documents';
  static const String _bucket = 'documents';
  static const Duration _signedUrlTtl = Duration(hours: 1);

  String get _ownerId => _client.auth.currentUser!.id;

  Future<List<VehicleDocumentDto>> fetchDocuments(String vehicleId) async {
    final rows = await _client.from(_table).select().eq('vehicle_id', vehicleId);
    return rows.map(VehicleDocumentDto.fromJson).toList();
  }

  Future<VehicleDocumentDto> upsertDocument(
    String vehicleId,
    String kind,
    Map<String, dynamic> values,
  ) async {
    final row = await _client
        .from(_table)
        .upsert({...values, 'vehicle_id': vehicleId, 'kind': kind}, onConflict: 'vehicle_id,kind')
        .select()
        .single();
    return VehicleDocumentDto.fromJson(row);
  }

  Future<void> deleteDocument(String vehicleId, String kind) async {
    await _client.from(_table).delete().eq('vehicle_id', vehicleId).eq('kind', kind);
  }

  Future<void> setReminderEnabled(String vehicleId, String kind, bool enabled) async {
    await _client
        .from(_table)
        .update({'reminder_enabled': enabled})
        .eq('vehicle_id', vehicleId)
        .eq('kind', kind);
  }

  String _storagePath(String vehicleId, String kind, String extension) {
    return '$_ownerId/$vehicleId/$kind.$extension';
  }

  Future<String> uploadFile({
    required String vehicleId,
    required String kind,
    required Uint8List bytes,
    required String extension,
  }) async {
    final path = _storagePath(vehicleId, kind, extension);
    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return path;
  }

  Future<Uint8List> downloadFile(String filePath) {
    return _client.storage.from(_bucket).download(filePath);
  }

  Future<String> createSignedUrl(String filePath) {
    return _client.storage.from(_bucket).createSignedUrl(filePath, _signedUrlTtl.inSeconds);
  }

  Future<void> deleteFile(String filePath) async {
    await _client.storage.from(_bucket).remove([filePath]);
  }

  /// Borra SOAT y RTM del bucket para una moto entera (`<owner>/<vehicleId>/*`),
  /// sin importar la extensión: se usa al eliminar la moto del garaje.
  Future<void> deleteAllFilesForVehicle(String vehicleId) async {
    final prefix = '$_ownerId/$vehicleId';
    final objects = await _client.storage.from(_bucket).list(path: prefix);
    if (objects.isEmpty) return;
    await _client.storage
        .from(_bucket)
        .remove(objects.map((object) => '$prefix/${object.name}').toList());
  }
}
