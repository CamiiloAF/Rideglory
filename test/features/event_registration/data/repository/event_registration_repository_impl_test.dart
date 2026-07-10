import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/features/event_registration/data/dto/event_registration_dto.dart';
import 'package:rideglory/features/event_registration/data/repository/event_registration_repository_impl.dart';
import 'package:rideglory/features/event_registration/data/service/registration_service.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';

class MockRegistrationService extends Mock implements RegistrationService {}

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

final _persisted = EventRegistrationDto(
  id: 'reg-1',
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

DioException _dioError({int statusCode = 400, String? message}) {
  return DioException(
    requestOptions: RequestOptions(path: '/registrations'),
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: RequestOptions(path: '/registrations'),
      statusCode: statusCode,
      data: message == null ? null : {'message': message},
    ),
  );
}

void main() {
  late MockRegistrationService mockService;
  late EventRegistrationRepositoryImpl repository;

  setUp(() {
    mockService = MockRegistrationService();
    repository = EventRegistrationRepositoryImpl(mockService);
  });

  group('addRegistration', () {
    test('returns Right with created registration on success', () async {
      when(
        () => mockService.create(
          eventId: any(named: 'eventId'),
          body: any(named: 'body'),
          saveToProfile: any(named: 'saveToProfile'),
        ),
      ).thenAnswer((_) async => _persisted);

      final result = await repository.addRegistration(_registration);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (value) {
        expect(value.id, 'reg-1');
      });
    });

    test('returns Left with mapped message on DioException', () async {
      when(
        () => mockService.create(
          eventId: any(named: 'eventId'),
          body: any(named: 'body'),
          saveToProfile: any(named: 'saveToProfile'),
        ),
      ).thenThrow(_dioError(statusCode: 400, message: 'Datos inválidos'));

      final result = await repository.addRegistration(_registration);

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error.message, 'Datos inválidos'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('updateRegistration', () {
    test('returns Left immediately when registration has no id', () async {
      final result = await repository.updateRegistration(_registration);

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(
          error.message,
          'Registration id is required to update.',
        ),
        (_) => fail('Expected Left'),
      );
      verifyNever(
        () => mockService.update(
          registrationId: any(named: 'registrationId'),
          body: any(named: 'body'),
          saveToProfile: any(named: 'saveToProfile'),
        ),
      );
    });

    test('returns Right with updated registration on success', () async {
      final withId = _registration.copyWith(id: 'reg-1');
      when(
        () => mockService.update(
          registrationId: any(named: 'registrationId'),
          body: any(named: 'body'),
          saveToProfile: any(named: 'saveToProfile'),
        ),
      ).thenAnswer((_) async => _persisted);

      final result = await repository.updateRegistration(withId);

      expect(result.isRight(), isTrue);
      verify(
        () => mockService.update(
          registrationId: 'reg-1',
          body: any(named: 'body'),
          saveToProfile: false,
        ),
      ).called(1);
    });

    test('returns Left with mapped message on DioException', () async {
      final withId = _registration.copyWith(id: 'reg-1');
      when(
        () => mockService.update(
          registrationId: any(named: 'registrationId'),
          body: any(named: 'body'),
          saveToProfile: any(named: 'saveToProfile'),
        ),
      ).thenThrow(_dioError(statusCode: 404));

      final result = await repository.updateRegistration(withId);

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) =>
            expect(error.message, 'No encontramos la información solicitada.'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('cancelRegistration', () {
    test('returns Right(Nothing) on success', () async {
      when(() => mockService.cancel('reg-1')).thenAnswer((_) async {});

      final result = await repository.cancelRegistration('reg-1');

      expect(result, const Right(Nothing()));
    });

    test('returns Left with mapped message on DioException', () async {
      when(
        () => mockService.cancel('reg-1'),
      ).thenThrow(_dioError(statusCode: 403));

      final result = await repository.cancelRegistration('reg-1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(
          error.message,
          'No tienes permisos para realizar esta acción.',
        ),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('getRegistrationsByEvent', () {
    test('returns Right with list on success', () async {
      when(
        () => mockService.findByEvent('event-1'),
      ).thenAnswer((_) async => [_persisted]);

      final result = await repository.getRegistrationsByEvent('event-1');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (value) {
        expect(value, hasLength(1));
        expect(value.first.id, 'reg-1');
      });
    });

    test('returns Left with mapped message on DioException', () async {
      when(
        () => mockService.findByEvent('event-1'),
      ).thenThrow(_dioError(statusCode: 401));

      final result = await repository.getRegistrationsByEvent('event-1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) =>
            expect(error.message, 'Tu sesión expiró. Inicia sesión nuevamente.'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('getMyRegistrations', () {
    test('returns Right with list on success', () async {
      when(
        () => mockService.findMyRegistrations(),
      ).thenAnswer((_) async => [_persisted]);

      final result = await repository.getMyRegistrations();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (value) {
        expect(value, hasLength(1));
      });
    });

    test('returns Left with mapped message on DioException', () async {
      when(
        () => mockService.findMyRegistrations(),
      ).thenThrow(_dioError(statusCode: 500));

      final result = await repository.getMyRegistrations();

      expect(result.isLeft(), isTrue);
    });
  });

  group('getMyRegistrationForEvent', () {
    test('returns Right with registration when found', () async {
      when(
        () => mockService.findMyRegistrationForEvent('event-1'),
      ).thenAnswer((_) async => _persisted);

      final result = await repository.getMyRegistrationForEvent('event-1');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (value) {
        expect(value?.id, 'reg-1');
      });
    });

    test('returns Right(null) when there is no registration', () async {
      when(
        () => mockService.findMyRegistrationForEvent('event-1'),
      ).thenAnswer((_) async => null);

      final result = await repository.getMyRegistrationForEvent('event-1');

      expect(result, const Right(null));
    });

    test('returns Left with mapped message on DioException', () async {
      when(
        () => mockService.findMyRegistrationForEvent('event-1'),
      ).thenThrow(_dioError(statusCode: 404));

      final result = await repository.getMyRegistrationForEvent('event-1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) =>
            expect(error.message, 'No encontramos la información solicitada.'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('approveRegistration', () {
    test('returns Right with approved registration on success', () async {
      when(
        () => mockService.approve('reg-1'),
      ).thenAnswer((_) async => _persisted);

      final result = await repository.approveRegistration('reg-1');

      expect(result.isRight(), isTrue);
    });

    test('returns Left with mapped message on DioException', () async {
      when(
        () => mockService.approve('reg-1'),
      ).thenThrow(_dioError(statusCode: 409));

      final result = await repository.approveRegistration('reg-1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(
          error.message,
          'Ya existe un registro con esta información.',
        ),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('rejectRegistration', () {
    test('returns Right with rejected registration on success', () async {
      when(
        () => mockService.reject('reg-1'),
      ).thenAnswer((_) async => _persisted);

      final result = await repository.rejectRegistration('reg-1');

      expect(result.isRight(), isTrue);
    });

    test('returns Left with mapped message on DioException', () async {
      when(
        () => mockService.reject('reg-1'),
      ).thenThrow(_dioError(statusCode: 403));

      final result = await repository.rejectRegistration('reg-1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(
          error.message,
          'No tienes permisos para realizar esta acción.',
        ),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('setRegistrationReadyForEdit', () {
    test('returns Right with updated registration on success', () async {
      when(
        () => mockService.setReadyForEdit('reg-1'),
      ).thenAnswer((_) async => _persisted);

      final result = await repository.setRegistrationReadyForEdit('reg-1');

      expect(result.isRight(), isTrue);
    });

    test('returns Left with mapped message on DioException', () async {
      when(
        () => mockService.setReadyForEdit('reg-1'),
      ).thenThrow(_dioError(statusCode: 400, message: 'No se pudo procesar'));

      final result = await repository.setRegistrationReadyForEdit('reg-1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error.message, 'No se pudo procesar'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
