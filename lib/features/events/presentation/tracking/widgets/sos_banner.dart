import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/sos_alert_model.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/sos_banner_action.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full-width SOS banner shown at the top of the map overlay stack.
/// Non-blocking — the map remains interactive below this widget.
class SosBannerWidget extends StatelessWidget {
  const SosBannerWidget({super.key, required this.sosAlert});

  final SosAlertModel sosAlert;

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.sos_banner_title(sosAlert.riderName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hasPhone
                ? context.l10n.sos_banner_subtitle_with_phone
                : context.l10n.sos_banner_subtitle_no_phone,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (hasPhone) ...[
                SosBannerAction(
                  icon: Icons.phone_rounded,
                  label: context.l10n.sos_call_action,
                  onTap: () => _callRider(context),
                ),
                const SizedBox(width: 8),
              ],
              SosBannerAction(
                icon: Icons.location_on_rounded,
                label: context.l10n.sos_locate_action,
                onTap: () => _locateRider(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

