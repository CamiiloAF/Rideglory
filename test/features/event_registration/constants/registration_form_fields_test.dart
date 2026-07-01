import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/features/event_registration/constants/registration_form_fields.dart';

void main() {
  group('RegistrationFormFields', () {
    test('shareMedicalInfo has the exact key expected by form binding', () {
      expect(RegistrationFormFields.shareMedicalInfo, 'shareMedicalInfo');
    });

    test('allowOrganizerContact has the exact key expected by form binding', () {
      expect(RegistrationFormFields.allowOrganizerContact, 'allowOrganizerContact');
    });
  });
}
