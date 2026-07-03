import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

class EventDetailDescriptionSection extends StatefulWidget {
  const EventDetailDescriptionSection({super.key, required this.event});

  final EventModel event;

  @override
  State<EventDetailDescriptionSection> createState() =>
      _EventDetailDescriptionSectionState();
}

class _EventDetailDescriptionSectionState
    extends State<EventDetailDescriptionSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.event_aboutEvent,
          style: const TextStyle(
            color: AppColors.textOnDarkPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Space Grotesk',
          ),
        ),
        const SizedBox(height: 8),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: SizedBox(
            height: 67,
            child: ClipRect(
              child: IgnorePointer(
                child: RichTextViewer(
                  content: widget.event.description,
                  textColor: AppColors.textOnDarkSecondary,
                  fontSize: 14,
                  lineHeight: 1.6,
                ),
              ),
            ),
          ),
          secondChild: IgnorePointer(
            child: RichTextViewer(
              content: widget.event.description,
              textColor: AppColors.textOnDarkSecondary,
              fontSize: 14,
              lineHeight: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _expanded
                    ? context.l10n.event_showLess
                    : context.l10n.event_showMore,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Space Grotesk',
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                color: AppColors.primary,
                size: 14,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
