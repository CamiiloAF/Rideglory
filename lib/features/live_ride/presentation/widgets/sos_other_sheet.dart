import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/components/app_secondary_button.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/sos_alert.dart';
import '../cubit/sos_cubit.dart';
import '../live_ride_external_actions.dart';
import '../live_ride_formatters.dart';
import 'sos_coordinates_card.dart';
import 'sos_other_close_confirm_dialog.dart';

/// LV5b: tarjeta del SOS de otro rider — llamar, centrar el mapa en la
/// alerta y, solo para el organizador, marcarlo como resuelto (D19).
///
/// Pencil: p4830
class SosOtherSheet extends StatelessWidget {
  const SosOtherSheet({
    required this.alert,
    required this.isOwner,
    this.onViewMap,
    super.key,
  });

  final SosAlert alert;
  final bool isOwner;
  final VoidCallback? onViewMap;

  static Future<void> show(
    BuildContext context, {
    required SosAlert alert,
    required bool isOwner,
    VoidCallback? onViewMap,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          SosOtherSheet(alert: alert, isOwner: isOwner, onViewMap: onViewMap),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final minutes = liveRideMinutesSince(alert.createdAt);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.errorSolid,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    liveRideInitials(alert.riderName),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colors.onBlock,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        alert.riderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: colors.text,
                        ),
                      ),
                      Text(
                        context.l10n.sos_other_asked_help_minutes(minutes),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.errorText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SosCoordinatesCard(
              lat: alert.lat,
              lng: alert.lng,
              accuracyM: alert.accuracyM,
            ),
            const SizedBox(height: 14),
            if (alert.riderPhone != null) ...[
              AppPrimaryButton(
                label: context.l10n.sos_other_call_cta(alert.riderName),
                icon: LucideIcons.phone,
                onPressed: () => openSosPhoneDialer(alert.riderPhone!),
              ),
              const SizedBox(height: 10),
            ],
            AppSecondaryButton(
              label: context.l10n.sos_other_view_map_cta,
              icon: LucideIcons.map,
              onPressed: () {
                Navigator.of(context).pop();
                onViewMap?.call();
              },
            ),
            if (isOwner) ...[
              const SizedBox(height: 10),
              AppSecondaryButton(
                label: context.l10n.sos_other_resolve_cta,
                icon: LucideIcons.check,
                onPressed: () => _resolve(context),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.sos_other_resolve_note,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _resolve(BuildContext context) async {
    final confirmed = await SosOtherCloseConfirmDialog.show(
      context,
      riderName: alert.riderName,
    );
    if (!confirmed || !context.mounted) return;
    await context.read<SosCubit>().closeOther(alert.id);
    if (context.mounted) Navigator.of(context).pop();
  }
}
