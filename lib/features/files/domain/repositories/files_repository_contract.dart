import 'package:image_picker/image_picker.dart';

abstract interface class FilesRepositoryContract {
  /// Uploads a file to the Firebase Storage and return the download URL
  Future<String> uploadFile(final XFile file);

  /// Delete a file to the Firebase Storage
  Future<void> delete(final String downloadUrl);
}
