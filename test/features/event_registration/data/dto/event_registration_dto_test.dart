import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/features/event_registration/data/dto/event_registration_dto.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';

Map<String, dynamic> _minimalJson({String? bloodType}) => <String, dynamic>{
  'eventId': 'event-1',
  'eventName': 'Rodada Test',
  'userId': 'user-1',
  'fullName': 'Rider Test',
  'identificationNumber': '123456',
  'birthDate': '2000-01-01T00:00:00.000Z',
  'phone': '3001234567',
  'email': 'rider@test.com',
  'residenceCity': 'Bogotá',
  'eps': 'Sura',
  if (bloodType != null) 'bloodType': bloodType,
  'emergencyContactName': 'Contact Test',
  'emergencyContactPhone': '3007654321',
};

void main() {
  group('EventRegistrationModel — legal/privacy fields defaults (AC#1)', () {
    test('TC-model-01: only-required construction defaults new fields', () {
      final model = EventRegistrationModel(
        eventId: 'event-1',
        eventName: 'Rodada Test',
        userId: 'user-1',
        fullName: 'Rider Test',
        identificationNumber: '123456',
        birthDate: DateTime(2000, 1, 1),
        phone: '3001234567',
        email: 'rider@test.com',
        residenceCity: 'Bogotá',
        eps: 'Sura',
        bloodType: null,
        emergencyContactName: 'Contact Test',
        emergencyContactPhone: '3007654321',
      );

      expect(model.shareMedicalInfo, isFalse);
      expect(model.allowOrganizerContact, isFalse);
      expect(model.riskAcceptedAt, isNull);
      expect(model.riskAcceptanceVersion, isNull);
      expect(model.medicalConsentAcceptedAt, isNull);
      expect(model.medicalConsentVersion, isNull);
    });
  });

  group('EventRegistrationDto — bloodType sentinel tolerance (AC#2)', () {
    test(
      'TC-dto-01: __NOT_SHARED__ sentinel decodes to null, no exception',
      () {
        final dto = EventRegistrationDto.fromJson(
          _minimalJson(bloodType: '__NOT_SHARED__'),
        );
        expect(dto.bloodType, isNull);
      },
    );

    test('TC-dto-02: bullet mask sentinel decodes to null, no exception', () {
      final dto = EventRegistrationDto.fromJson(
        _minimalJson(bloodType: '••••'),
      );
      expect(dto.bloodType, isNull);
    });

    test('TC-dto-03: valid @JsonValue string decodes to correct enum', () {
      final dto = EventRegistrationDto.fromJson(
        _minimalJson(bloodType: 'A_POSITIVE'),
      );
      expect(dto.bloodType, BloodType.aPositive);
    });

    test('TC-dto-04: absent bloodType key decodes to null', () {
      final dto = EventRegistrationDto.fromJson(_minimalJson());
      expect(dto.bloodType, isNull);
    });
  });

  group('EventRegistrationDto — bloodTypeRaw fallback (AC10)', () {
    test(
      'TC-dto-06: unmapped sentinel string is preserved raw in bloodTypeRaw',
      () {
        final dto = EventRegistrationDto.fromJson(
          _minimalJson(bloodType: '••••'),
        );
        expect(dto.bloodType, isNull);
        expect(dto.bloodTypeRaw, '••••');
      },
    );

    test(
      'TC-dto-07: valid @JsonValue string maps to enum and bloodTypeRaw stays null',
      () {
        final dto = EventRegistrationDto.fromJson(
          _minimalJson(bloodType: 'A_POSITIVE'),
        );
        expect(dto.bloodType, BloodType.aPositive);
        expect(dto.bloodTypeRaw, isNull);
      },
    );

    test('TC-dto-08: absent bloodType key leaves bloodTypeRaw null', () {
      final dto = EventRegistrationDto.fromJson(_minimalJson());
      expect(dto.bloodType, isNull);
      expect(dto.bloodTypeRaw, isNull);
    });

    test('TC-dto-09: toJson never serializes bloodTypeRaw', () {
      final dto = EventRegistrationDto.fromJson(
        _minimalJson(bloodType: '__NOT_SHARED__'),
      );
      expect(dto.bloodTypeRaw, '__NOT_SHARED__');
      expect(dto.toJson().containsKey('bloodTypeRaw'), isFalse);
    });
  });

  group(
    'EventRegistrationModelExtension.toJson — propagates legal fields (AC#3)',
    () {
      test('TC-dto-05: toJson includes the legal fields (incl. medical '
          'consent) with exact values', () {
        final model = EventRegistrationModel(
          eventId: 'event-1',
          eventName: 'Rodada Test',
          userId: 'user-1',
          fullName: 'Rider Test',
          identificationNumber: '123456',
          birthDate: DateTime(2000, 1, 1),
          phone: '3001234567',
          email: 'rider@test.com',
          residenceCity: 'Bogotá',
          eps: 'Sura',
          bloodType: BloodType.oNegative,
          emergencyContactName: 'Contact Test',
          emergencyContactPhone: '3007654321',
          shareMedicalInfo: true,
          allowOrganizerContact: false,
          riskAcceptedAt: DateTime(2026, 6, 19),
          riskAcceptanceVersion: 'v0.1-2026-06',
          medicalConsentAcceptedAt: DateTime(2026, 6, 20),
          medicalConsentVersion: 'v0.1-2026-06',
        );

        final json = model.toJson();

        expect(json['shareMedicalInfo'], true);
        expect(json['allowOrganizerContact'], false);
        expect(json['riskAcceptedAt'], isNotNull);
        expect(
          DateTime.parse(json['riskAcceptedAt'] as String).toUtc(),
          DateTime(2026, 6, 19).toUtc(),
        );
        expect(json['riskAcceptanceVersion'], 'v0.1-2026-06');
        expect(json['medicalConsentAcceptedAt'], isNotNull);
        expect(
          DateTime.parse(json['medicalConsentAcceptedAt'] as String).toUtc(),
          DateTime(2026, 6, 20).toUtc(),
        );
        expect(json['medicalConsentVersion'], 'v0.1-2026-06');
      });
    },
  );
}
