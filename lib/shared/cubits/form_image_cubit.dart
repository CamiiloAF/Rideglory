import 'package:bloc/bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/image_storage_service.dart';

class FormImageData {
  const FormImageData({this.remoteImageUrl, this.localImagePath});

  final String? remoteImageUrl;
  final String? localImagePath;

  bool get hasLocalImage => localImagePath != null;
  String? get displayImageUrl => localImagePath ?? remoteImageUrl;

  FormImageData copyWith({
    String? remoteImageUrl,
    Object? localImagePath = _unset,
  }) {
    return FormImageData(
      remoteImageUrl: remoteImageUrl ?? this.remoteImageUrl,
      localImagePath: localImagePath == _unset
          ? this.localImagePath
          : localImagePath as String?,
    );
  }
}

const _unset = Object();

class FormImageCubit extends Cubit<ResultState<FormImageData>> {
  FormImageCubit(this._imageStorageService)
    : super(const ResultState.initial());

  final ImageStorageService _imageStorageService;
  bool _isPickingImage = false;

  void initialize({String? remoteImageUrl}) {
    emit(ResultState.data(data: FormImageData(remoteImageUrl: remoteImageUrl)));
  }

  Future<void> pickImageFromGallery() async {
    if (_isPickingImage) return;
    _isPickingImage = true;
    final current = _currentImageData();
    if (current == null) {
      _isPickingImage = false;
      return;
    }

    try {
      final file = await _imageStorageService.pickImageFromGallery();
      if (file == null) return;

      emit(ResultState.data(data: current.copyWith(localImagePath: file.path)));
    } finally {
      _isPickingImage = false;
    }
  }

  void clearLocalImage() {
    final current = _currentImageData();
    if (current == null) return;
    emit(ResultState.data(data: current.copyWith(localImagePath: null)));
  }

  void setRemoteImageUrl(String url) {
    emit(ResultState.data(data: FormImageData(remoteImageUrl: url)));
  }

  String? get selectedLocalImagePath =>
      state.whenOrNull(data: (data) => data.localImagePath);

  FormImageData? _currentImageData() {
    return state.whenOrNull(data: (data) => data) ?? const FormImageData();
  }
}
