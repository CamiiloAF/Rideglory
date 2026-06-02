import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/sos_alert_model.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/sos_banner_action.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full-width SOS banner shown at the top of the map overlay stack.
/// Non-blocking — the map remains interactive below this widget.
class SosBannerWidget extends StatelessWidget {
  const SosBannerWidget({
    super.key,
    required this.sosAlert,
    required this.displayName,
    this.onLocate,
  });

  final SosAlertModel sosAlert;

  /// Resolved rider name (the alert payload may only carry the user id).
  final String displayName;

  /// Centers the SOS rider on the in-app map. Falls back to external maps.
  final VoidCallback? onLocate;

  Future<void> _callRider(BuildContext context) async {
    final phone = sosAlert.phone;
    if (phone == null) return;

    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tracking_sosCallError)),
      );
    }
  }

  Future<void> _showLocateOptions(BuildContext context) async {
    await AppModal.show<void>(
      context: context,
      title: context.l10n.sos_locate_sheet_title(displayName),
      icon: Icons.location_on_rounded,
      variant: AppModalVariant.warning,
      barrierDismissible: true,
      actions: [
        AppModalAction(
          label: context.l10n.sos_locate_center_option,
          onPressed: () => onLocate?.call(),
        ),
        AppModalAction.neutral(
          label: context.l10n.sos_locate_external_option,
          onPressed: () => _locateRider(context),
        ),
      ],
    );
  }

  Future<void> _locateRider(BuildContext context) async {
    final lat = sosAlert.latitude;
    final lng = sosAlert.longitude;
    if (lat == null || lng == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tracking_sosLocationError)),
      );
      return;
    }

    final label = Uri.encodeComponent(sosAlert.riderName);
    final androidUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');
    final iosUri = Uri.parse('maps:?q=$lat,$lng');

    final uri = Theme.of(context).platform == TargetPlatform.iOS
        ? iosUri
        : androidUri;

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tracking_sosMapError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhone = sosAlert.phone != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.sos_banner_title(displayName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  hasPhone
                      ? sosAlert.phone!
                      : context.l10n.sos_banner_subtitle_no_phone,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (hasPhone) ...[
            SosBannerAction(
              icon: Icons.phone_rounded,
              label: context.l10n.sos_call_action,
              onTap: () => _callRider(context),
            ),
            const SizedBox(width: 6),
          ],
          SosBannerAction(
            icon: Icons.location_on_rounded,
            label: context.l10n.sos_locate_action,
            onTap: () => _showLocateOptions(context),
          ),
        ],
      ),
    );
  }
}

