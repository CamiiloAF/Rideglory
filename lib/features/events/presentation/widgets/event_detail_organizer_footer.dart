import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/components/app_secondary_button.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Footer de EV2 para el organizador: iniciar, cambiar ruta, ver inscritos
/// y cancelar la rodada.
class EventDetailOrganizerFooter extends StatelessWidget {
  const EventDetailOrganizerFooter({
    required this.canStart,
    required this.isBusy,
    required this.onStart,
    required this.onChangeRoute,
    required this.onViewRegistrants,
    required this.onCancelEvent,
    super.key,
  });

  final bool canStart;
  final bool isBusy;
  final VoidCallback onStart;
  final VoidCallback onChangeRoute;
  final VoidCallback onViewRegistrants;
  final VoidCallback onCancelEvent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.bg),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canStart) ...[
                AppPrimaryButton(
                  label: context.l10n.events_detail_start_cta,
                  icon: LucideIcons.play,
                  onPressed: isBusy ? null : onStart,
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: context.l10n.events_detail_change_route_cta,
                      icon: LucideIcons.milestone,
                      onPressed: isBusy ? null : onChangeRoute,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppSecondaryButton(
                      label: context.l10n.events_detail_view_registrants_cta,
                      icon: LucideIcons.users,
                      onPressed: onViewRegistrants,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: isBusy ? null : onCancelEvent,
                child: Text(
                  context.l10n.events_detail_cancel_event_cta,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.errorText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
