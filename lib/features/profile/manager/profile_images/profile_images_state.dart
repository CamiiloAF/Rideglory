part of 'profile_images_cubit.dart';

@freezed
class ProfileImagesState with _$ProfileImagesState {
  const factory ProfileImagesState.initial() = ProfileImagesInitial;

  const factory ProfileImagesState.loading() = ProfileImagesLoading;

  const factory ProfileImagesState.uploaded(final String downloadURL) =
      ProfileImagesUploaded;

  const factory ProfileImagesState.deleted(final String downloadURL) =
      ProfileImagesDeleted;

  const factory ProfileImagesState.error(final String message) =
      ProfileImagesUpError;
}
