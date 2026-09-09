import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_secondary_button.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Banner de "sin contacto de emergencia" en la ficha del rider.
///
/// Pencil: iFssW
class ProfileEmergencyBanner extends StatelessWidget {
  const ProfileEmergencyBanner({required this.onAddContact, super.key});

  final VoidCallback onAddContact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.warningSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertTriangle, size: 18, color: colors.warning),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  context.l10n.profile_emergency_banner_title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: colors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            context.l10n.profile_emergency_banner_body,
            style: TextStyle(fontSize: 12.5, height: 1.4, color: colors.text),
          ),
          const SizedBox(height: 11),
          AppSecondaryButton(
            label: context.l10n.profile_emergency_add_contact_cta,
            onPressed: onAddContact,
          ),
        ],
      ),
    );
  }
}
