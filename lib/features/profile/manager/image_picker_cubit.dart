import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../../core/exceptions/failure.dart';
import '../../../../../../generated/l10n.dart';

class ImagePickerCubit extends Cubit<XFile?> {
  ImagePickerCubit(this.imagePicker) : super(null);

  final ImagePicker imagePicker;

  Future<void> pickImage(
    final ImageSource source, {
    final int? imageQuality,
  }) async {
    try {
      final image = await ImagePicker()
          .pickImage(source: source, imageQuality: imageQuality);

      emit(image);
    } on Exception {
      throw Failure(AppStrings.current.errorPickingFile);
    }
  }
}
