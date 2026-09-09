import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/features/garage/domain/utils/vehicle_plate_validator.dart';

void main() {
  group('VehiclePlateValidator', () {
    test('normalizes to uppercase without spaces', () {
      expect(VehiclePlateValidator.normalize('abc 12d'), 'ABC12D');
      expect(VehiclePlateValidator.normalize(' abc12d '), 'ABC12D');
    });

    test('accepts the Colombian motorcycle plate format', () {
      expect(VehiclePlateValidator.isValid('ABC12D'), isTrue);
      expect(VehiclePlateValidator.isValid('abc 12d'), isTrue);
    });

    test('rejects a car plate format (three letters, three digits)', () {
      expect(VehiclePlateValidator.isValid('ABC123'), isFalse);
    });

    test('rejects too short or malformed input', () {
      expect(VehiclePlateValidator.isValid('AB123'), isFalse);
      expect(VehiclePlateValidator.isValid(''), isFalse);
      expect(VehiclePlateValidator.isValid('123ABC'), isFalse);
    });
  });
}
