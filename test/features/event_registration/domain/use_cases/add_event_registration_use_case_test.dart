import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/domain/repository/event_registration_repository.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/add_event_registration_use_case.dart';

class MockEventRegistrationRepository extends Mock
    implements EventRegistrationRepository {}

final _registration = EventRegistrationModel(
  eventId: 'event-1',
  eventName: 'Ruta Mágica',
  userId: 'user-1',
  fullName: 'Carlos García',
  identificationNumber: '123456789',
  birthDate: DateTime(1990, 5, 15),
  phone: '3001234567',
  email: 'carlos@example.com',
  residenceCity: 'Medellín',
  eps: 'Sura',
  bloodType: BloodType.oPositive,
  emergencyContactName: 'Ana García',
  emergencyContactPhone: '3009876543',
);

void main() {
  late MockEventRegistrationRepository mockRepository;
  late AddEventRegistrationUseCase useCase;

  setUp(() {
    mockRepository = MockEventRegistrationRepository();
    useCase = AddEventRegistrationUseCase(mockRepository);
  });

  group('AddEventRegistrationUseCase', () {
    test(
      'delegates to repository.addRegistration and returns Right on success',
      () async {
        final saved = _registration.copyWith(id: 'reg-1');
        when(
          () => mockRepository.addRegistration(
            _registration,
            saveToProfile: false,
          ),
        ).thenAnswer((_) async => Right(saved));

        final result = await useCase(_registration);

        expect(result, Right(saved));
        verify(
          () => mockRepository.addRegistration(
            _registration,
            saveToProfile: false,
          ),
        ).called(1);
      },
    );

    test('forwards saveToProfile flag to the repository', () async {
      final saved = _registration.copyWith(id: 'reg-1');
      when(
        () => mockRepository.addRegistration(
          _registration,
          saveToProfile: true,
        ),
      ).thenAnswer((_) async => Right(saved));

      await useCase(_registration, saveToProfile: true);

      verify(
        () => mockRepository.addRegistration(
          _registration,
          saveToProfile: true,
        ),
      ).called(1);
    });

    test('returns Left when repository fails', () async {
      when(
        () => mockRepository.addRegistration(
          _registration,
          saveToProfile: false,
        ),
      ).thenAnswer(
        (_) async => const Left(DomainException(message: 'Error al crear')),
      );

      final result = await useCase(_registration);

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error.message, 'Error al crear'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
