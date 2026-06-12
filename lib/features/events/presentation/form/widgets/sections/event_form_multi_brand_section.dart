import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/core/data/colombia_motos_brands_data.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/multi_brand/brand_chips_inline.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/multi_brand/multi_brand_toggle_card.dart';

/// Brands section matching Pencil frame zbCa0 — "MARCAS PERMITIDAS" section:
/// - Section header
/// - Card: left column (label + subtitle) + right toggle switch
/// - Hint box with info text
/// - Brand chips when multibrand is off
class EventFormMultiBrandSection extends StatelessWidget {
  const EventFormMultiBrandSection({super.key});

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<bool>(
      name: EventFormFields.isMultiBrand,
      builder: (isField) {
        final isMultiBrand = isField.value ?? true;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.event_multiBrandLabel.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AppColors.textOnDarkTertiary,
              ),
            ),
            const SizedBox(height: 10),
            MultiBrandToggleCard(
              isMultiBrand: isMultiBrand,
              onChanged: isField.didChange,
            ),
            const SizedBox(height: 8),
            if (!isMultiBrand) ...[
              const SizedBox(height: 12),
              FormBuilderField<List<String>>(
                name: EventFormFields.allowedBrands,
                builder: (listField) => BrandChipsInline(
                  field: listField,
                  suggestions: ColombiaMotosBrandsData.search,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
