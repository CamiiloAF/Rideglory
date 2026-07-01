import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/features/users/data/dto/user_dto.dart';

Map<String, dynamic> _minimalJson() => <String, dynamic>{
  'id': 'user-1',
  'fullName': 'Rider Test',
  'email': 'rider@test.com',
};

void main() {
  group('UserDto — medicalConsentAcceptedAt (AC#5)', () {
    test(
      'TC-dto-01: fromJson parses ISO-8601 string into non-null DateTime',
      () {
        final json = _minimalJson()
          ..['medicalConsentAcceptedAt'] = '2026-06-19T12:00:00.000Z';

        final dto = UserDto.fromJson(json);

        expect(dto.medicalConsentAcceptedAt, isNotNull);
        expect(
          dto.medicalConsentAcceptedAt!.toUtc(),
          DateTime.parse('2026-06-19T12:00:00.000Z').toUtc(),
        );
      },
    );

    test('TC-dto-02: fromJson with field absent decodes to null', () {
      final dto = UserDto.fromJson(_minimalJson());

      expect(dto.medicalConsentAcceptedAt, isNull);
    });
  });
}
