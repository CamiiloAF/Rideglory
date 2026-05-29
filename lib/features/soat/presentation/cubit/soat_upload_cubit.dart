import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/features/soat/presentation/scan/soat_document_picker.dart';

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
  SoatUploadCubit() : super(const SoatUploadInitial());

  Future<void> pickFromGallery() async {
    emit(const SoatUploadPicking());
    final path = await SoatDocumentPicker.pickImageFromGallery();
    _emitPicked(path);
  }

  Future<void> pickFromFile() async {
    emit(const SoatUploadPicking());
    final path = await SoatDocumentPicker.pickPdf();
    _emitPicked(path);
  }

  void _emitPicked(String? path) {
    if (path != null) {
      emit(SoatUploadImagePicked(XFile(path)));
    } else {
      emit(const SoatUploadInitial());
    }
  }
}
