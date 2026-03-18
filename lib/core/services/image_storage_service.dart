import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';

import '../l10n/rideglory_l10n.dart';
import '../exceptions/domain_exception.dart';

@injectable
class ImageStorageService {
  ImageStorageService(this._storage);

  final FirebaseStorage _storage;
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImageFromGallery() async {
    return _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1080,
    );
  }

  Future<XFile?> pickImageFromCamera() async {
    return _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1080,
    );
  }

  Future<String> uploadImage({
    required XFile image,
    required String storagePath,
  }) async {
    final file = File(image.path);
    if (!file.existsSync()) {
      throw DomainException(
        message: RidegloryL10n.current.imageUploadFailed,
      );
    }
    final ref = _storage.ref().child(storagePath);
    try {
      await ref.putFile(file);
      return ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw DomainException(message: _userMessageForStorageException(e));
    }
  }

  /// Maps Firebase Storage error codes to user-facing messages.
  String _userMessageForStorageException(FirebaseException e) {
    final code = e.code.toLowerCase();
    if (code.contains('cancel')) {
      return RidegloryL10n.current.imageUploadCancelled;
    }
    if (code.contains('object-not-found') ||
        code.contains('not-found') ||
        code.contains('unauthenticated') ||
        code.contains('unauthorized') ||
        code.contains('bucket-not-found')) {
      return RidegloryL10n.current.imageUploadNotFound;
    }
    return RidegloryL10n.current.imageUploadFailed;
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (_) {
      // Silently handle errors when deleting images
    }
  }
}
