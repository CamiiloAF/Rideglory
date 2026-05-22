import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

/// Price section for the event form.
///
/// Always shows the price input. A helper note below the field explains that
/// a price of 0 means the event is free — no checkbox needed.
class EventFormPriceSection extends StatelessWidget {
  const EventFormPriceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PriceSectionHeader(context: context),
        const SizedBox(height: 10),
        const _PriceInputCard(),
        const SizedBox(height: 6),
        _PriceFreeHint(context: context),
      ],
    );
  }
}

class _PriceSectionHeader extends StatelessWidget {
  const _PriceSectionHeader({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.l10n.event_form_price_section_title,
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.textOnDarkTertiary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.darkTertiary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            context.l10n.event_form_optional_badge,
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textOnDarkTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceInputCard extends StatelessWidget {
  const _PriceInputCard();

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
            child: FormBuilderTextField(
              name: EventFormFields.price,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textOnDarkPrimary,
              ),
              decoration: const InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(
                  color: AppColors.textOnDarkTertiary,
                  fontSize: 16,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                errorStyle: TextStyle(height: 0),
              ),
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

class _PriceFreeHint extends StatelessWidget {
  const _PriceFreeHint({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline,
          size: 13,
          color: AppColors.textOnDarkTertiary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            context.l10n.event_form_price_free_hint,
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 11,
              fontWeight: FontWeight.normal,
              color: AppColors.textOnDarkTertiary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
