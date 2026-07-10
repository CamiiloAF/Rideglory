import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/domain/repository/event_registration_repository.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/set_registration_ready_for_edit_use_case.dart';

class MockEventRegistrationRepository extends Mock
    implements EventRegistrationRepository {}

final _registration = EventRegistrationModel(
  id: 'reg-1',
  eventId: 'event-1',
  eventName: 'Ruta Mágica',
  userId: 'user-1',
  status: RegistrationStatus.readyForEdit,
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
  late SetRegistrationReadyForEditUseCase useCase;

  setUp(() {
    mockRepository = MockEventRegistrationRepository();
    useCase = SetRegistrationReadyForEditUseCase(mockRepository);
  });

  group('SetRegistrationReadyForEditUseCase', () {
    test(
      'delegates to repository.setRegistrationReadyForEdit and returns Right with readyForEdit status',
      () async {
        when(
          () => mockRepository.setRegistrationReadyForEdit('reg-1'),
        ).thenAnswer((_) async => Right(_registration));

        final result = await useCase('reg-1');

        expect(result, Right(_registration));
        result.fold((_) => fail('Expected Right'), (value) {
          expect(value.status, RegistrationStatus.readyForEdit);
        });
        verify(
          () => mockRepository.setRegistrationReadyForEdit('reg-1'),
        ).called(1);
      },
    );

    test('returns Left when repository fails', () async {
      when(
        () => mockRepository.setRegistrationReadyForEdit('reg-1'),
      ).thenAnswer(
        (_) async =>
            const Left(DomainException(message: 'No se pudo actualizar')),
      );

      final result = await useCase('reg-1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error.message, 'No se pudo actualizar'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
