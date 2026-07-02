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

  group('RegistrationWizardSteps.fieldsByStep — fase 3 (no UI yet)', () {
    // Case 2.3: shareMedicalInfo/allowOrganizerContact are declared as
    // constants but MUST NOT be wired into the wizard's step fields yet —
    // that UI (switches/consent) ships in fases 4/5/6, not in this
    // domain/data-only phase.
    test(
      'fieldsByStep does not include shareMedicalInfo (no wizard UI in this phase)',
      () {
        final allStepFields = RegistrationWizardSteps.fieldsByStep
            .expand((step) => step);

        expect(
          allStepFields.contains(RegistrationFormFields.shareMedicalInfo),
          isFalse,
        );
      },
    );

    test(
      'fieldsByStep does not include allowOrganizerContact (no wizard UI in this phase)',
      () {
        final allStepFields = RegistrationWizardSteps.fieldsByStep
            .expand((step) => step);

        expect(
          allStepFields.contains(RegistrationFormFields.allowOrganizerContact),
          isFalse,
        );
      },
    );
  });
}
