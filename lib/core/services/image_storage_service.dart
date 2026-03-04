import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';

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
    final ref = _storage.ref().child(storagePath);
    final uploadTask = await ref.putFile(file);
    return uploadTask.ref.getDownloadURL();
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
