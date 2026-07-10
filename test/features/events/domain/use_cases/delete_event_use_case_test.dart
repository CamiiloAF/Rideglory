import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/repository/event_repository.dart';
import 'package:rideglory/features/events/domain/use_cases/delete_event_use_case.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository mockRepository;
  late DeleteEventUseCase useCase;

  setUp(() {
    mockRepository = MockEventRepository();
    useCase = DeleteEventUseCase(mockRepository);
  });

  test('delegates to repository.deleteEvent and returns Right on success', () async {
    when(
      () => mockRepository.deleteEvent('event-1'),
    ).thenAnswer((_) async => const Right(Nothing()));

    final result = await useCase('event-1');

    expect(result.isRight(), isTrue);
    verify(() => mockRepository.deleteEvent('event-1')).called(1);
  });

  test('returns Left when repository fails', () async {
    const error = DomainException(message: 'No se pudo eliminar.');
    when(
      () => mockRepository.deleteEvent('event-1'),
    ).thenAnswer((_) async => const Left(error));

    final result = await useCase('event-1');

    expect(result, const Left(error));
  });
}
