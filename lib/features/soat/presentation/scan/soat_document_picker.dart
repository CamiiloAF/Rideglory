import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

/// Selección centralizada del documento de SOAT.
///
/// Garantiza que el OCR reciba SIEMPRE la misma calidad sin importar desde dónde
/// se suba (bottom sheet de opciones o card del formulario). Las imágenes se
/// piden a máxima calidad y **sin redimensionar**: el texto pequeño del SOAT
/// necesita resolución para que el reconocimiento lo lea. (No se usa
/// `ImageStorageService`, que comprime/escala para fotos de perfil/portada.)
abstract final class SoatDocumentPicker {
  static Future<String?> pickImageFromGallery() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    return file?.path;
  }

  static Future<String?> pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    return result?.files.single.path;
  }
}
