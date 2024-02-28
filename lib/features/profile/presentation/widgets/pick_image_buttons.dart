import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../manager/image_picker_cubit.dart';

class PickImageButtons extends StatelessWidget {
  const PickImageButtons({required this.onPickImage, super.key});

  final void Function(XFile file) onPickImage;

  @override
  Widget build(final BuildContext context) {
    return BlocProvider(
      create: (final context) => ImagePickerCubit(ImagePicker()),
      child: _View(onPickImage: onPickImage),
    );
  }
}

class _View extends StatelessWidget {
  const _View({required this.onPickImage});

  final void Function(XFile file) onPickImage;

  @override
  Widget build(final BuildContext context) {
    return BlocListener<ImagePickerCubit, XFile?>(
      listener: (final context, final state) {
        if (state != null) {
          onPickImage(state);
        }
      },
      child: Column(
        children: [
          SizedBox(
            height: 170,
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    child: const Icon(Icons.insert_photo_outlined),
                    onPressed: () async {
                      await _pickImage(context, ImageSource.gallery);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    child: const Icon(Icons.add_a_photo_outlined),
                    onPressed: () async {
                      await _pickImage(context, ImageSource.camera);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(
    final BuildContext context,
    final ImageSource imageSource,
  ) async {
    await context.read<ImagePickerCubit>().pickImage(imageSource);
  }
}
