import 'package:flutter/material.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/price/price_free_hint.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/price/price_input_card.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/price/price_section_header.dart';

/// Price section for the event form.
///
/// Always shows the price input. A helper note below the field explains that
/// a price of 0 means the event is free — no checkbox needed.
class EventFormPriceSection extends StatelessWidget {
  const EventFormPriceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PriceSectionHeader(),
        SizedBox(height: 10),
        PriceInputCard(),
        SizedBox(height: 6),
        PriceFreeHint(),
      ],
    );
  }
}
