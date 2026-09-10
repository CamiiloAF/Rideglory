import 'dart:io';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/models/vehicle_document.dart';

/// Caché offline de documentos (D7): copia local en
/// `ApplicationSupportDirectory/documents/<vehicleId>/<kind>.<ext>`. Se
/// escribe al subir y al abrir; el visor sin conexión lee de aquí primero.
///
/// Vive en `data/` porque hace I/O real (`dart:io`, `path_provider`): el
/// dominio nunca toca el sistema de archivos.
@injectable
class DocumentLocalCacheService {
  Future<Directory> _vehicleDirectory(String vehicleId) async {
    final base = await getApplicationSupportDirectory();
    final directory = Directory('${base.path}/documents/$vehicleId');
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    return directory;
  }

  Future<File> _fileFor(String vehicleId, DocumentKind kind, String extension) async {
    final directory = await _vehicleDirectory(vehicleId);
    return File('${directory.path}/${kind.name}.$extension');
  }

  Future<File> save(String vehicleId, DocumentKind kind, String extension, Uint8List bytes) async {
    final file = await _fileFor(vehicleId, kind, extension);
    return file.writeAsBytes(bytes, flush: true);
  }

  /// Busca la copia en caché sin importar la extensión exacta (jpg/png/pdf).
  Future<File?> find(String vehicleId, DocumentKind kind) async {
    final directory = await _vehicleDirectory(vehicleId);
    if (!directory.existsSync()) return null;
    final match = directory
        .listSync()
        .whereType<File>()
        .where((file) => file.uri.pathSegments.last.startsWith(kind.name))
        .toList();
    return match.isEmpty ? null : match.first;
  }

  Future<void> delete(String vehicleId, DocumentKind kind) async {
    final file = await find(vehicleId, kind);
    if (file != null && file.existsSync()) {
      file.deleteSync();
    }
  }

  /// Borra todo el caché de una moto (SOAT y RTM): se usa al eliminarla del
  /// garaje, para que no queden documentos huérfanos en el dispositivo.
  Future<void> deleteAllForVehicle(String vehicleId) async {
    final directory = await _vehicleDirectory(vehicleId);
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  }
}
