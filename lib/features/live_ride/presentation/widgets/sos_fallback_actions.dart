import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/components/app_secondary_button.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/live_ride_contacts.dart';
import '../live_ride_external_actions.dart';

/// D17/D18: llamar al contacto cacheado (o al organizador si no hay
/// contacto), SMS con coordenadas y el botón terciario "Llamar al 123"
/// (nunca automático, D18). Se usa en LV4a/LV4b/LV7+SOS.
class SosFallbackActions extends StatelessWidget {
  const SosFallbackActions({
    required this.lat,
    required this.lng,
    super.key,
    this.contacts,
  });

  final double lat;
  final double lng;
  final LiveRideContacts? contacts;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final contactPhone = contacts?.emergencyContactPhone;
    final contactName = contacts?.emergencyContactName;
    final organizerPhone = contacts?.organizerPhone;
    final organizerName = contacts?.organizerName ?? '';

    final String? primaryPhone;
    final String primaryLabel;
    if (contactPhone != null && contactName != null) {
      primaryPhone = contactPhone;
      primaryLabel = context.l10n.sos_call_contact_cta(contactName);
    } else if (organizerPhone != null) {
      primaryPhone = organizerPhone;
      primaryLabel = context.l10n.sos_call_organizer_cta(organizerName);
    } else {
      primaryPhone = null;
      primaryLabel = context.l10n.sos_call_organizer_cta(organizerName);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (primaryPhone == null) ...[
          Text(
            context.l10n.sos_no_contact_warning,
            style: TextStyle(fontSize: 12.5, color: colors.warning),
          ),
          const SizedBox(height: 10),
        ] else ...[
          AppPrimaryButton(
            label: primaryLabel,
            icon: LucideIcons.phone,
            onPressed: () => openSosPhoneDialer(primaryPhone!),
          ),
          const SizedBox(height: 10),
        ],
        AppSecondaryButton(
          label: context.l10n.sos_sms_cta,
          icon: LucideIcons.messageSquare,
          onPressed: (primaryPhone ?? organizerPhone) == null
              ? null
              : () => openSosSms(
                  phone: primaryPhone ?? organizerPhone!,
                  lat: lat,
                  lng: lng,
                ),
        ),
        const SizedBox(height: 10),
        AppSecondaryButton(
          label: context.l10n.sos_call_123_cta,
          icon: LucideIcons.phone,
          onPressed: () => openSosPhoneDialer('123'),
        ),
      ],
    );
  }
}
