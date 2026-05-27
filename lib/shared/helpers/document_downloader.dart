import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

/// Utilidad para abrir documentos remotos (imágenes, PDF) con la app
/// predeterminada del dispositivo.
///
/// Implementa una caché local: la primera vez descarga el archivo a un
/// directorio temporal; las siguientes, reutiliza el archivo descargado
/// si la URL (sin query params) no ha cambiado.
abstract class DocumentDownloader {
  /// Descarga [url] con caché y lo abre con la app predeterminada del SO.
  static Future<void> openRemote(String url, String fileName) async {
    final filePath = await _cachedFilePath(url, fileName);
    await OpenFile.open(filePath);
  }

  /// Extrae el nombre del archivo a partir de una URL remota.
  static String fileNameFromUrl(String url) =>
      Uri.decodeFull(url.split('?').first).split('/').last;

  /// Retorna `true` si la URL corresponde a un PDF.
  static bool isPdfUrl(String url) =>
      Uri.decodeFull(url.split('?').first).toLowerCase().endsWith('.pdf');

  // ── Caché ─────────────────────────────────────────────────────────────────

  /// Devuelve la ruta local del archivo, descargándolo solo si no está en caché.
  ///
  /// La clave de caché se calcula sobre la URL **sin query params** para que
  /// los cambios de token de Firebase Storage no invaliden el caché
  /// innecesariamente. Si el usuario sube un nuevo documento (distinta ruta),
  /// el hash cambia y se descarga el nuevo archivo.
  static Future<String> _cachedFilePath(String url, String fileName) async {
    final cacheDir = await _cacheDirectory();
    final key = _cacheKey(url);
    final ext = fileName.contains('.') ? '.${fileName.split('.').last}' : '';
    final filePath = '${cacheDir.path}/$key$ext';

    if (File(filePath).existsSync()) return filePath;

    await Dio().download(url, filePath);
    return filePath;
  }

  /// Hash estable de la ruta del archivo (sin query params).
  static String _cacheKey(String url) =>
      url.split('?').first.hashCode.abs().toString();

  static Future<Directory> _cacheDirectory() async {
    final temp = await getTemporaryDirectory();
    final dir = Directory('${temp.path}/soat_cache');
    if (!dir.existsSync()) dir.createSync();
    return dir;
  }
}
