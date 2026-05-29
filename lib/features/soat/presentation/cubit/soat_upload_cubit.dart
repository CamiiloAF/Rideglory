import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/services/image_storage_service.dart';

sealed class SoatUploadState {
  const SoatUploadState();
}

final class SoatUploadInitial extends SoatUploadState {
  const SoatUploadInitial();
}

final class SoatUploadPicking extends SoatUploadState {
  const SoatUploadPicking();
}

final class SoatUploadImagePicked extends SoatUploadState {
  const SoatUploadImagePicked(this.image);
  final XFile image;
}

final class SoatUploadError extends SoatUploadState {
  const SoatUploadError(this.message);
  final String message;
}

@injectable
class SoatUploadCubit extends Cubit<SoatUploadState> {
  SoatUploadCubit(this._imageStorageService) : super(const SoatUploadInitial());

  final ImageStorageService _imageStorageService;

  Future<void> pickFromGallery() async {
    emit(const SoatUploadPicking());
    final image = await _imageStorageService.pickImageFromGallery();
    if (image != null) {
      emit(SoatUploadImagePicked(image));
    } else {
      emit(const SoatUploadInitial());
    }
  }

  Future<void> pickFromFile() async {
    emit(const SoatUploadPicking());
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      emit(SoatUploadImagePicked(XFile(result.files.single.path!)));
    } else {
      emit(const SoatUploadInitial());
    }
  }
}
