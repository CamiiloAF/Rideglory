import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/exceptions/failure.dart';
import '../../../files/domain/repositories/files_repository_contract.dart';

part 'profile_images_cubit.freezed.dart';

part 'profile_images_state.dart';

class ProfileImagesCubit extends Cubit<ProfileImagesState> {
  ProfileImagesCubit({
    required final FilesRepositoryContract filesRepository,
    required final List<String> urlImages,
  })  : _filesRepository = filesRepository,
        _urlImages = urlImages,
        super(const ProfileImagesInitial());

  final FilesRepositoryContract _filesRepository;

  final List<String> _urlImages;

  List<String> get imagesUrl => _urlImages;

  Future<void> uploadImage(final XFile file) async {
    emit(const ProfileImagesLoading());
    try {
      final result = await _filesRepository.uploadFile(file);
      _urlImages.add(result);
      emit(ProfileImagesUploaded(result));
    } on Failure catch (e) {
      emit(ProfileImagesUpError(e.message));
    }
  }

  Future<void> deleteImage(final String downloadUrl) async {
    emit(const ProfileImagesLoading());
    try {
      await _filesRepository.delete(downloadUrl);
      _urlImages.remove(downloadUrl);
      emit(ProfileImagesDeleted(downloadUrl));
    } on Failure catch (e) {
      emit(ProfileImagesUpError(e.message));
    }
  }
}
