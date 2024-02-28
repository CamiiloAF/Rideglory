import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/di_manager.dart';
import '../../../../shared/extensions/build_context_extensions.dart';
import '../../../../shared/extensions/widget_extensions.dart';
import '../../../../shared/widgets/progress_indicators/our_circular_progress_indicator.dart';
import '../../../files/domain/repositories/files_repository_contract.dart';
import '../../../users/domain/entities/user_model.dart';
import '../../manager/profile_images/profile_images_cubit.dart';
import 'image_card.dart';
import 'pick_image_buttons.dart';

class ProfileImagePicker extends StatelessWidget {
  const ProfileImagePicker({
    required this.userModel,
    required this.onPickImage,
    required this.onRemoveImage,
    super.key,
  });

  final UserModel userModel;

  final void Function(String fileURL) onPickImage;
  final void Function(String fileURL) onRemoveImage;

  @override
  Widget build(final BuildContext context) {
    return BlocProvider(
      create: (final context) => ProfileImagesCubit(
        filesRepository: DIManager.getIt<FilesRepositoryContract>(),
        urlImages: [...userModel.pictures],
      ),
      child: _View(
        userModel: userModel,
        onPickImage: onPickImage,
        onDeleteImage: onRemoveImage,
      ),
    );
  }
}

class _View extends StatelessWidget {
  const _View({
    required this.userModel,
    required this.onPickImage,
    required this.onDeleteImage,
  });

  final UserModel userModel;

  final void Function(String fileURL) onPickImage;
  final void Function(String fileURL) onDeleteImage;

  @override
  Widget build(final BuildContext context) {
    return BlocConsumer<ProfileImagesCubit, ProfileImagesState>(
      listener: (final context, final state) {
        state.whenOrNull(
          uploaded: onPickImage,
          deleted: onDeleteImage,
          error: context.showSnackBar,
        );
      },
      builder: (final context, final state) {
        final imagesUrl = context.read<ProfileImagesCubit>().imagesUrl;
        return SizedBox(
          height: 510,
          child: state is ProfileImagesLoading
              ? const OurCircularProgressIndicator()
              : CustomScrollView(
                  primary: false,
                  slivers: <Widget>[
                    if (imagesUrl.isEmpty)
                      SliverToBoxAdapter(
                        child: Center(
                          child: Text(
                            appStrings.takeOrChooseAPicture,
                          ),
                        ),
                      ),
                    SliverGrid.count(
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      crossAxisCount: 2,
                      children: [
                        ...List.generate(imagesUrl.length, (final index) {
                          final fileURL = imagesUrl[index];

                          return ImageCard(
                            fileURL: fileURL,
                            onDeleteImage: (final fileURL) {
                              context
                                  .read<ProfileImagesCubit>()
                                  .deleteImage(fileURL);
                            },
                          );
                        }),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: PickImageButtons(
                        onPickImage: (final file) {
                          context.read<ProfileImagesCubit>().uploadImage(file);
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
