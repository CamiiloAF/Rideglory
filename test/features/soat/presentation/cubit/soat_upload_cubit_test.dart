import 'package:bloc_test/bloc_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:rideglory/features/soat/presentation/cubit/soat_upload_cubit.dart';

class _FakeImagePickerPlatform extends ImagePickerPlatform {
  _FakeImagePickerPlatform({this.pathToReturn});

  final String? pathToReturn;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    if (pathToReturn == null) return null;
    return XFile(pathToReturn!);
  }
}

class _FakeFilePickerPlatform extends FilePickerPlatform {
  _FakeFilePickerPlatform({this.pathToReturn});

  final String? pathToReturn;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
  }) async {
    if (pathToReturn == null) return null;
    return FilePickerResult([
      PlatformFile(path: pathToReturn, name: 'soat.pdf', size: 100),
    ]);
  }
}

void main() {
  final originalImagePickerPlatform = ImagePickerPlatform.instance;
  final originalFilePickerPlatform = FilePickerPlatform.instance;

  tearDown(() {
    ImagePickerPlatform.instance = originalImagePickerPlatform;
    FilePickerPlatform.instance = originalFilePickerPlatform;
  });

  test('estado inicial es SoatUploadInitial', () {
    final cubit = SoatUploadCubit();
    expect(cubit.state, isA<SoatUploadInitial>());
    cubit.close();
  });

  group('pickFromGallery', () {
    blocTest<SoatUploadCubit, SoatUploadState>(
      'camino feliz — emite Picking y luego ImagePicked con el archivo',
      setUp: () {
        ImagePickerPlatform.instance = _FakeImagePickerPlatform(
          pathToReturn: '/tmp/soat.jpg',
        );
      },
      build: SoatUploadCubit.new,
      act: (cubit) => cubit.pickFromGallery(),
      expect: () => [
        isA<SoatUploadPicking>(),
        isA<SoatUploadImagePicked>().having(
          (state) => state.image.path,
          'image.path',
          '/tmp/soat.jpg',
        ),
      ],
    );

    blocTest<SoatUploadCubit, SoatUploadState>(
      'camino de cancelación — vuelve a Initial si el usuario cancela',
      setUp: () {
        ImagePickerPlatform.instance = _FakeImagePickerPlatform(
          pathToReturn: null,
        );
      },
      build: SoatUploadCubit.new,
      act: (cubit) => cubit.pickFromGallery(),
      expect: () => [isA<SoatUploadPicking>(), isA<SoatUploadInitial>()],
    );
  });

  group('pickFromFile', () {
    blocTest<SoatUploadCubit, SoatUploadState>(
      'camino feliz — emite Picking y luego ImagePicked con el PDF',
      setUp: () {
        FilePickerPlatform.instance = _FakeFilePickerPlatform(
          pathToReturn: '/tmp/soat.pdf',
        );
      },
      build: SoatUploadCubit.new,
      act: (cubit) => cubit.pickFromFile(),
      expect: () => [
        isA<SoatUploadPicking>(),
        isA<SoatUploadImagePicked>().having(
          (state) => state.image.path,
          'image.path',
          '/tmp/soat.pdf',
        ),
      ],
    );

    blocTest<SoatUploadCubit, SoatUploadState>(
      'camino de cancelación — vuelve a Initial si el usuario cancela',
      setUp: () {
        FilePickerPlatform.instance = _FakeFilePickerPlatform(
          pathToReturn: null,
        );
      },
      build: SoatUploadCubit.new,
      act: (cubit) => cubit.pickFromFile(),
      expect: () => [isA<SoatUploadPicking>(), isA<SoatUploadInitial>()],
    );
  });
}
