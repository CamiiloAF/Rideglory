import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_card_constants.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_card_expand_toggle.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_card_info_panel.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_card_my_event_badge.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_card_price_badge.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_card_type_chip.dart';

class EventCard extends StatefulWidget {
  final EventModel event;
  final VoidCallback onTap;
  final bool isOwner;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.isOwner = false,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _isExpanded = false;

  @override
  void didUpdateWidget(covariant EventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event.id != widget.event.id && _isExpanded) {
      _isExpanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        height: eventCardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowDark,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  widget.event.imageUrl ?? '',
                  fit: BoxFit.fill,
                  errorBuilder: (_, _, _) => Image.asset(
                    'assets/images/event.jpeg', //TODO: Add placeholder image
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.5),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: EventCardTypeChip(eventType: widget.event.eventType),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: EventCardPriceBadge(
                  isFree: widget.event.isFree,
                  price: widget.event.price,
                ),
              ),
              if (widget.isOwner)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  bottom: _isExpanded ? eventCardInfoPanelHeight + 12 : 14,
                  left: 14,
                  child: const EventCardMyEventBadge(),
                ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                bottom: _isExpanded ? eventCardInfoPanelHeight + 12 : 14,
                right: 14,
                child: EventCardExpandToggle(
                  isExpanded: _isExpanded,
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                bottom: _isExpanded ? 0 : -eventCardInfoPanelHeight,
                left: 0,
                right: 0,
                height: eventCardInfoPanelHeight,
                child: EventCardInfoPanel(
                  event: widget.event,
                  onTap: widget.onTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
