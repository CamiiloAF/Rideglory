import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';

class PriceInputCard extends StatelessWidget {
  const PriceInputCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Único input (con prefijo "$"); antes se anidaba un AppTextField —que ya
    // trae su propia caja y borde— dentro de un Container de alto fijo, lo que
    // producía un doble input y overflow vertical.
    return AppTextField(
      name: EventFormFields.price,
      prefixText: '\$ ',
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      hintText: '0',
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.numeric(
          errorText: context.l10n.event_invalidPrice,
          checkNullOrEmpty: false,
        ),
      ]),
    );
  }
}
