import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/domain/repository/event_registration_repository.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/reject_registration_use_case.dart';

class MockEventRegistrationRepository extends Mock
    implements EventRegistrationRepository {}

final _registration = EventRegistrationModel(
  id: 'reg-1',
  eventId: 'event-1',
  eventName: 'Ruta Mágica',
  userId: 'user-1',
  status: RegistrationStatus.rejected,
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
  late RejectRegistrationUseCase useCase;

  setUp(() {
    mockRepository = MockEventRegistrationRepository();
    useCase = RejectRegistrationUseCase(mockRepository);
  });

  group('RejectRegistrationUseCase', () {
    test(
      'delegates to repository.rejectRegistration and returns Right with rejected status',
      () async {
        when(
          () => mockRepository.rejectRegistration('reg-1'),
        ).thenAnswer((_) async => Right(_registration));

        final result = await useCase('reg-1');

        expect(result, Right(_registration));
        result.fold((_) => fail('Expected Right'), (value) {
          expect(value.status, RegistrationStatus.rejected);
        });
        verify(() => mockRepository.rejectRegistration('reg-1')).called(1);
      },
    );

    test(
      'returns Left when repository fails (e.g. not authorized)',
      () async {
        when(() => mockRepository.rejectRegistration('reg-1')).thenAnswer(
          (_) async => const Left(
            DomainException(
              message: 'No tienes permisos para realizar esta acción.',
            ),
          ),
        );

        final result = await useCase('reg-1');

        expect(result.isLeft(), isTrue);
        result.fold(
          (error) => expect(
            error.message,
            'No tienes permisos para realizar esta acción.',
          ),
          (_) => fail('Expected Left'),
        );
      },
    );
  });
}
