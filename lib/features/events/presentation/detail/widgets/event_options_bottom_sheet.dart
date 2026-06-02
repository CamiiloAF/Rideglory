import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_option_action_row.dart';

/// Owner action sheet for the event detail "three dots" menu. Replaces the old
/// [PopupMenuButton] with a bottom sheet that matches the app's modal/bottom
/// sheet design (Pencil "Event Detail — Menú Acciones"). Each row pops the sheet
/// before invoking its callback so navigation runs on the underlying screen.
class EventOptionsBottomSheet extends StatelessWidget {
  const EventOptionsBottomSheet({
    super.key,
    required this.eventName,
    required this.onEdit,
    required this.onAttendees,
    required this.onDelete,
  });

  final String eventName;
  final VoidCallback onEdit;
  final VoidCallback onAttendees;
  final VoidCallback onDelete;

  static Future<void> show({
    required BuildContext context,
    required String eventName,
    required VoidCallback onEdit,
    required VoidCallback onAttendees,
    required VoidCallback onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.darkBgPrimary.withValues(alpha: 0.82),
      builder: (_) => EventOptionsBottomSheet(
        eventName: eventName,
        onEdit: onEdit,
        onAttendees: onAttendees,
        onDelete: onDelete,
      ),
    );
  }

  void _select(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: cs.outline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 60,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 10),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 14),
              child: Column(
                children: [
                  Text(
                    context.l10n.event_optionsTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnDarkPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    eventName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textOnDarkTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: [
                  EventOptionActionRow(
                    icon: Icons.edit_outlined,
                    iconColor: AppColors.primary,
                    iconBackground: AppColors.primarySubtle,
                    label: context.l10n.event_editEvent,
                    labelColor: AppColors.textOnDarkPrimary,
                    onTap: () => _select(context, onEdit),
                  ),
                  EventOptionActionRow(
                    icon: Icons.people_outline,
                    iconColor: AppColors.info,
                    iconBackground: AppColors.infoSubtle,
                    label: context.l10n.event_viewAttendees,
                    labelColor: AppColors.textOnDarkPrimary,
                    onTap: () => _select(context, onAttendees),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Divider(
                      height: 1,
                      color: AppColors.darkBorderPrimary,
                    ),
                  ),
                  EventOptionActionRow(
                    icon: Icons.delete_outline,
                    iconColor: AppColors.error,
                    iconBackground: AppColors.errorSubtle,
                    label: context.l10n.event_deleteEvent,
                    labelColor: AppColors.error,
                    onTap: () => _select(context, onDelete),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: Material(
                  color: AppColors.darkTertiary,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cs.outline),
                      ),
                      child: Text(
                        context.l10n.cancel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOnDarkSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
