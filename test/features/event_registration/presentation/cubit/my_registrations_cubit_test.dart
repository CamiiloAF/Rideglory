import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/domain/model/registration_with_event.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/cancel_event_registration_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/get_my_registrations_use_case.dart';
import 'package:rideglory/features/event_registration/presentation/my_registrations_cubit.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/use_cases/get_event_by_id_use_case.dart';

class MockGetMyRegistrationsUseCase extends Mock
    implements GetMyRegistrationsUseCase {}

class MockCancelEventRegistrationUseCase extends Mock
    implements CancelEventRegistrationUseCase {}

class MockGetEventByIdUseCase extends Mock implements GetEventByIdUseCase {}

final _mockEvent = EventModel(
  id: 'event-1',
  ownerId: 'owner-1',
  name: 'Ruta Mágica',
  description: 'Una ruta increíble',
  city: 'Medellín',
  startDate: DateTime(2026, 6, 1),
  difficulty: EventDifficulty.two,
  meetingPoint: 'Plaza Botero',
  destination: 'Guatapé',
  meetingTime: DateTime(2026, 6, 1, 8),
  eventType: EventType.tourism,
);

final _mockRegistration = EventRegistrationModel(
  id: 'reg-1',
  eventId: 'event-1',
  eventName: 'Ruta Mágica',
  userId: 'user-1',
  status: RegistrationStatus.pending,
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
  late MockGetMyRegistrationsUseCase mockGetRegistrations;
  late MockCancelEventRegistrationUseCase mockCancelRegistration;
  late MockGetEventByIdUseCase mockGetEventById;
  late MyRegistrationsCubit cubit;

  setUp(() {
    mockGetRegistrations = MockGetMyRegistrationsUseCase();
    mockCancelRegistration = MockCancelEventRegistrationUseCase();
    mockGetEventById = MockGetEventByIdUseCase();
    cubit = MyRegistrationsCubit(
      mockGetRegistrations,
      mockCancelRegistration,
      mockGetEventById,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('MyRegistrationsCubit', () {
    test('TC-reg-1: initial state is ResultState.initial', () {
      expect(
        cubit.state,
        const ResultState<List<RegistrationWithEvent>>.initial(),
      );
    });

    group('fetchMyRegistrations', () {
      blocTest<MyRegistrationsCubit, ResultState<List<RegistrationWithEvent>>>(
        'TC-reg-2: emits loading then data when registrations exist',
        setUp: () {
          when(() => mockGetRegistrations()).thenAnswer(
            (_) async => Right([_mockRegistration]),
          );
          when(() => mockGetEventById('event-1')).thenAnswer(
            (_) async => Right(_mockEvent),
          );
        },
        build: () => cubit,
        act: (c) => c.fetchMyRegistrations(),
        expect: () => [
          const ResultState<List<RegistrationWithEvent>>.loading(),
          predicate<ResultState<List<RegistrationWithEvent>>>(
            (state) =>
                state is Data<List<RegistrationWithEvent>> &&
                state.data.length == 1 &&
                state.data.first.registration.id == 'reg-1',
          ),
        ],
      );

      blocTest<MyRegistrationsCubit, ResultState<List<RegistrationWithEvent>>>(
        'TC-reg-3: emits loading then error when use case fails',
        setUp: () {
          when(() => mockGetRegistrations()).thenAnswer(
            (_) async =>
                const Left(DomainException(message: 'No autorizado')),
          );
        },
        build: () => cubit,
        act: (c) => c.fetchMyRegistrations(),
        expect: () => [
          const ResultState<List<RegistrationWithEvent>>.loading(),
          predicate<ResultState<List<RegistrationWithEvent>>>(
            (state) =>
                state is Error<List<RegistrationWithEvent>> &&
                state.error.message == 'No autorizado',
          ),
        ],
      );

      blocTest<MyRegistrationsCubit, ResultState<List<RegistrationWithEvent>>>(
        'TC-reg-4: emits loading then empty when no registrations',
        setUp: () {
          when(() => mockGetRegistrations()).thenAnswer(
            (_) async => const Right([]),
          );
        },
        build: () => cubit,
        act: (c) => c.fetchMyRegistrations(),
        expect: () => [
          const ResultState<List<RegistrationWithEvent>>.loading(),
          const ResultState<List<RegistrationWithEvent>>.empty(),
        ],
      );
    });

    group('updateStatusFilter', () {
      test('TC-reg-5: hasFilters returns true when filter is set', () async {
        when(() => mockGetRegistrations()).thenAnswer(
          (_) async => Right([_mockRegistration]),
        );
        when(() => mockGetEventById('event-1')).thenAnswer(
          (_) async => Right(_mockEvent),
        );
        await cubit.fetchMyRegistrations();

        cubit.updateStatusFilter({RegistrationStatus.pending});
        expect(cubit.hasFilters, isTrue);
        expect(cubit.statusFilter, {RegistrationStatus.pending});
      });

      test('TC-reg-6: clearFilters resets filters', () async {
        when(() => mockGetRegistrations()).thenAnswer(
          (_) async => Right([_mockRegistration]),
        );
        when(() => mockGetEventById('event-1')).thenAnswer(
          (_) async => Right(_mockEvent),
        );
        await cubit.fetchMyRegistrations();

        cubit.updateStatusFilter({RegistrationStatus.approved});
        cubit.clearFilters();
        expect(cubit.hasFilters, isFalse);
        expect(cubit.statusFilter, isEmpty);
      });
    });

    group('RegistrationModel', () {
      test('TC-reg-7: registrationTitle returns correct string', () {
        expect(
          _mockRegistration.registrationTitle,
          'Inscripción al evento Ruta Mágica',
        );
      });
    });
  });
}
