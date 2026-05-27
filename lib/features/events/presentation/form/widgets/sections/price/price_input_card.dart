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
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Text(
            '\$',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textOnDarkTertiary,
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 1, height: 24, color: AppColors.darkBorderPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: AppTextField(
              name: EventFormFields.price,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              hintText: '0',
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.numeric(
                  errorText: context.l10n.event_invalidPrice,
                  checkNullOrEmpty: false,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
