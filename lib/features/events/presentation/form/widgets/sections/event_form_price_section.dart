import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

/// Redesigned price section matching Pencil frame zbCa0 — "PRECIO DE INSCRIPCIÓN":
/// - Section header with "Opcional" badge
/// - Price input card: "$" symbol + divider + text input
/// - "Evento gratuito" checkbox — when checked, price card collapses (AnimatedSize)
///   and the price field value is cleared.
class EventFormPriceSection extends StatelessWidget {
  const EventFormPriceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<bool>(
      name: EventFormFields.isFreeEvent,
      initialValue: false,
      builder: (freeField) {
        final isFree = freeField.value ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PriceSectionHeader(context: context),
            const SizedBox(height: 10),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: isFree
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PriceInputCard(isFree: isFree),
                    ),
            ),
            _FreeEventRow(
              isFree: isFree,
              onToggle: () {
                freeField.didChange(!isFree);
                if (!isFree) {
                  FormBuilder.of(context)
                      ?.fields[EventFormFields.price]
                      ?.didChange(null);
                }
              },
            ),
          ],
        );
      },
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
  const _PriceInputCard({required this.isFree});

  final bool isFree;

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
              enabled: !isFree,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textOnDarkTertiary,
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

class _FreeEventRow extends StatelessWidget {
  const _FreeEventRow({required this.isFree, required this.onToggle});

  final bool isFree;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: isFree ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isFree ? AppColors.primary : AppColors.darkBorderPrimary,
              ),
            ),
            child: isFree
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            context.l10n.event_form_free_event_label,
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textOnDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
