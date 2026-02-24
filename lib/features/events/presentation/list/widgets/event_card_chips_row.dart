import 'package:flutter/material.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/list/widgets/difficulty_chip.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_card_price_chip.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_type_chip.dart';

class EventCardChipsRow extends StatelessWidget {
  final EventType eventType;
  final EventDifficulty difficulty;
  final bool isFree;
  final double? price;

  const EventCardChipsRow({
    super.key,
    required this.eventType,
    required this.difficulty,
    required this.isFree,
    this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        EventTypeChip(eventType: eventType),
        const SizedBox(width: 8),
        DifficultyChip(difficulty: difficulty),
        const Spacer(),
        EventCardPriceChip(isFree: isFree, price: price),
      ],
    );
  }
}
