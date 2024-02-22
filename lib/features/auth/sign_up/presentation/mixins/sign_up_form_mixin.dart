import 'package:reactive_forms/reactive_forms.dart';

import '../../../../users/domain/entities/enums/gender.dart';

mixin SignUpFormMixin {
  final fullNameInput = 'fullName';
  final emailInput = 'email';
  final dobInput = 'dob';
  final genderInput = 'gender';
  final phoneNumberInput = 'phoneNumber';

  late final FormGroup formGroup = FormGroup({
    fullNameInput: FormControl<String>(
      validators: [
        Validators.required,
      ],
    ),
    emailInput: FormControl<String>(
      validators: [
        Validators.required,
        Validators.email,
      ],
    ),
    dobInput: FormControl<DateTime>(
      validators: [
        Validators.required,
      ],
    ),
    genderInput: FormControl<Gender>(
      validators: [
        Validators.required,
      ],
    ),
    phoneNumberInput: FormControl<int>(
      validators: [
        Validators.required,
        Validators.number,
      ],
    ),
  });
}
