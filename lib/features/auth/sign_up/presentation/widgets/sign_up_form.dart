import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:rideglory/features/auth/sign_up/presentation/manager/sign_up/sign_up_cubit.dart';
import 'package:rideglory/shared/extensions/build_context_extensions.dart';
import 'package:rideglory/shared/extensions/form_control_extensions.dart';
import 'package:rideglory/shared/extensions/widget_extensions.dart';
import 'package:rideglory/shared/routes/app_router.dart';
import 'package:rideglory/shared/widgets/buttons/our_elevated_button.dart';
import 'package:rideglory/shared/widgets/forms/our_reactive_date_time_picker.dart';
import 'package:rideglory/shared/widgets/forms/our_reactive_drop_down_field.dart';
import 'package:rideglory/shared/widgets/forms/our_reactive_text_field.dart';

import '../../../../../shared/widgets/forms/our_reactive_form.dart';
import '../../../../users/domain/entities/enums/gender.dart';
import '../../../../users/domain/entities/user_model.dart';
import '../mixins/sign_up_form_mixin.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> with SignUpFormMixin {

  late final User firebaseUser;

  @override
  void initState() {
    firebaseUser = context.read<SignUpCubit>().getFirebaseUser();

    _initializeFormData();

    super.initState();
  }

  void _initializeFormData() {
    formGroup.setValue(fullNameInput, firebaseUser.displayName);
    formGroup.setValue(emailInput, firebaseUser.email);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: OurReactiveForm(
        formGroup: formGroup,
        fields: [
          OurReactiveTextField(
            formControlName: fullNameInput,
            hintText: appStrings.fullName,
          ),
          OurReactiveTextField(
            formControlName: emailInput,
            hintText: appStrings.email,
            readOnly: true,
          ),
          OurReactiveDateTimePicker(
            formControlName: dobInput,
            hintText: appStrings.dob,
          ),
          OurReactiveDropDownInput(
            formControlName: genderInput,
            hint: appStrings.gender,
            items: Gender.values
                .map(
                  (gender) => DropdownMenuItem(
                    value: gender,
                    child: Text(gender.getText()),
                  ),
                )
                .toList(),
          ),
          OurReactiveTextField(
            formControlName: phoneNumberInput,
            hintText: appStrings.phoneNumber,
            keyboardType: TextInputType.phone,
          ),
          BlocConsumer<SignUpCubit, SignUpState>(
            listener: (context, state) {
              state.whenOrNull(
                success: () {
                  context.router.replace(const HomeRoute());
                },
                error: (message) => context.showSnackBar(message),
              );
            },
            builder: (context, state) {
              return ReactiveFormConsumer(
                builder: (context, formGroup, child) {
                  return OurElevatedButton(
                    buttonText: appStrings.save,
                    isLoading: state is LoadingSignUp,
                    onPressed: formGroup.valid
                        ? () {
                            context
                                .read<SignUpCubit>()
                                .signUp(_buildUserModel(formGroup));
                          }
                        : null,
                  );
                },
              );
            },
          )
        ],
      ),
    );
  }

  UserModel _buildUserModel(final FormGroup formGroup) {
    return UserModel(
      id: firebaseUser.uid,
      fullName: formGroup.getValue<String>(fullNameInput),
      dob: formGroup.getValue<DateTime>(dobInput),
      email: formGroup.getValue<String>(emailInput),
      gender: formGroup.getValue<Gender>(genderInput),
      phoneNumber: formGroup.getValue<int>(phoneNumberInput),
    );
  }
}
