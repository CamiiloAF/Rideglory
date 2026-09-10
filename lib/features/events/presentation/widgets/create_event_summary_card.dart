import 'package:flutter/widgets.dart';

import '../../../../design_system/components/app_outlined_card.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../event_labels.dart';
import '../widgets/labeled_value_row.dart';

/// Resumen final antes de publicar (paso 3).
class CreateEventSummaryCard extends StatelessWidget {
  const CreateEventSummaryCard({
    required this.name,
    required this.startAt,
    required this.price,
    super.key,
  });

  final String name;
  final DateTime? startAt;
  final int price;

  @override
  Widget build(BuildContext context) {
    return AppOutlinedCard(
      children: [
        LabeledValueRow(
          label: context.l10n.events_create_summary_name,
          value: name.isEmpty ? '—' : name,
        ),
        LabeledValueRow(
          label: context.l10n.events_create_summary_date,
          value: startAt == null ? '—' : eventDateLabel(startAt!),
        ),
        LabeledValueRow(
          label: context.l10n.events_create_summary_price,
          value: eventPriceLabel(context, price),
        ),
      ],
    );
  }
}
