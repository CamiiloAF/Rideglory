import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

class OurReactiveForm extends StatefulWidget {
  const OurReactiveForm({
    required this.formGroup,
    required this.fields,
    super.key,
    this.validationMessages,
  });

  final FormGroup formGroup;
  final List<Widget> fields;
  final Map<String, ValidationMessageFunction>? validationMessages;

  @override
  State<OurReactiveForm> createState() => _OurReactiveFormState();
}

class _OurReactiveFormState extends State<OurReactiveForm> {
  @override
  Widget build(final BuildContext context) {

    return ReactiveFormConfig(
      validationMessages: {
        // ValidationMessage.required: (final _) => appStrings.fieldIsRequired,
        // ValidationMessage.email: (final _) => appStrings.invalidEmail,
        // ValidationMessage.mustMatch: (final _) => appStrings.passwordsMustMatch,
        // ValidationMessage.minLength: (final error) {
        //   final requiredLength = (error as Map<String, int>)['requiredLength'];
        //   return appStrings.minXCharactersAreRequired(requiredLength!);
        // },
        // ValidationMessage.maxLength: (final error) {
        //   final requiredLength = (error as Map<String, int>)['requiredLength'];
        //   return appStrings.maxXCharactersAreAllowed(requiredLength!);
        // },
        ...?widget.validationMessages,
      },
      child: ReactiveForm(
        formGroup: widget.formGroup,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.fields,
        ),
      ),
    );
  }
}
