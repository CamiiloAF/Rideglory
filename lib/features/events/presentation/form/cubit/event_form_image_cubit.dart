import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';

@immutable
class EventFormImageData {
  const EventFormImageData({this.remoteImageUrl, this.localImagePath});

  final String? remoteImageUrl;
  final String? localImagePath;

  bool get hasLocalImage => localImagePath != null;
  String? get displayImageUrl => localImagePath ?? remoteImageUrl;

  EventFormImageData copyWith({
    String? remoteImageUrl,
    Object? localImagePath = _unset,
  }) {
    return EventFormImageData(
      remoteImageUrl: remoteImageUrl ?? this.remoteImageUrl,
      localImagePath: localImagePath == _unset
          ? this.localImagePath
          : localImagePath as String?,
    );
  }
}

const _unset = Object();

@injectable
class EventFormImageCubit extends Cubit<ResultState<EventFormImageData>> {
  EventFormImageCubit() : super(const ResultState.initial());

  final ImagePicker _picker = ImagePicker();

  void initialize({String? remoteImageUrl}) {
    emit(
      ResultState.data(
        data: EventFormImageData(remoteImageUrl: remoteImageUrl),
      ),
    );
  }

  Future<void> pickCoverImageFromGallery() async {
    final current = _currentImageData();
    if (current == null) return;

    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (file == null) return;

    emit(ResultState.data(data: current.copyWith(localImagePath: file.path)));
  }

  void clearLocalCoverImage() {
    final current = _currentImageData();
    if (current == null) return;
    emit(ResultState.data(data: current.copyWith(localImagePath: null)));
  }

  String? get selectedLocalImagePath =>
      state.whenOrNull(data: (data) => data.localImagePath);

  EventFormImageData? _currentImageData() {
    return state.whenOrNull(data: (data) => data) ?? const EventFormImageData();
  }
}
