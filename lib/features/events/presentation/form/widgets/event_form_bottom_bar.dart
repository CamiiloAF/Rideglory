import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/widgets/draft_link.dart';
import 'package:rideglory/features/events/presentation/form/widgets/publish_button.dart';

/// Bottom bar for the event form containing the primary "Publicar evento" CTA
/// and the "Guardar como borrador" secondary link.
///
/// Matches Pencil frame zbCa0 — "CTA" section:
/// - Pill button h=56, radius=28, accent fill, send icon
/// - Draft text link below (only in create mode)
class EventFormBottomBar extends StatelessWidget {
  const EventFormBottomBar({
    super.key,
    required this.isLoading,
    required this.isEditing,
  });

  final bool isLoading;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkBgPrimary,
        border: Border(top: BorderSide(color: AppColors.darkBorderPrimary)),
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, max(16.0, bottomPadding)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PublishButton(isLoading: isLoading, isEditing: isEditing),
          if (!isEditing) ...[
            const SizedBox(height: 16),
            const DraftLink(),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
