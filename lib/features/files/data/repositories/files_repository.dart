import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/exceptions/failure.dart';
import '../../../../generated/l10n.dart';
import '../../domain/repositories/files_repository_contract.dart';

class FilesRepository implements FilesRepositoryContract {
  FilesRepository({required this.storage});

  final FirebaseStorage storage;

  @override
  Future<String> uploadFile(final XFile file) async {
    try {
      final destination = 'files/${file.name}.${file.path.split('.').last}';

      final fileInBytes = await file.readAsBytes();

      final result =
          await storage.ref(destination).child('file/').putData(fileInBytes);

      return result.ref.getDownloadURL();
    } on Exception catch (_) {
      throw Failure(AppStrings.current.errorUploadingFile);
    }
  }

  @override
  Future<void> delete(final String downloadUrl) async {
    try {
      await storage.refFromURL(downloadUrl).delete();
    } on Exception catch (_) {
      throw Failure(AppStrings.current.errorDeletingFile);
    }
  }
}
