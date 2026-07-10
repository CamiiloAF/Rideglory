import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/model/upload_event_image_request.dart';
import 'package:rideglory/features/events/domain/repository/event_repository.dart';
import 'package:rideglory/features/events/domain/use_cases/upload_event_image_use_case.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository mockRepository;
  late UploadEventImageUseCase useCase;

  const request = UploadEventImageRequest(
    localImagePath: '/tmp/cover.jpg',
    eventId: 'event-1',
    ownerId: 'owner-1',
  );

  setUpAll(() {
    registerFallbackValue(request);
  });

  setUp(() {
    mockRepository = MockEventRepository();
    useCase = UploadEventImageUseCase(mockRepository);
  });

  test('delegates to repository.uploadEventImage and returns Right', () async {
    when(() => mockRepository.uploadEventImage(any())).thenAnswer(
      (_) async => const Right('https://storage.example.com/cover.jpg'),
    );

    final result = await useCase(request);

    expect(result, const Right('https://storage.example.com/cover.jpg'));
    verify(() => mockRepository.uploadEventImage(request)).called(1);
  });

  test('returns Left when repository fails', () async {
    const error = DomainException(message: 'No se pudo subir la imagen.');
    when(
      () => mockRepository.uploadEventImage(any()),
    ).thenAnswer((_) async => const Left(error));

    final result = await useCase(request);

    expect(result, const Left(error));
  });
}
