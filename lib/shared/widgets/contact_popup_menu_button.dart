import 'package:flutter/material.dart';
import 'package:rideglory/shared/helpers/url_launcher_helper.dart';
import 'package:rideglory/design_system/design_system.dart';

class ContactPopupMenuButton extends StatelessWidget {
  const ContactPopupMenuButton({
    super.key,
    required this.phone,
    required this.contactLabel,
    required this.callLabel,
    required this.whatsappLabel,
    this.tooltip,
    this.alignment = Alignment.centerRight,
  });

  final String phone;
  final String contactLabel;
  final String callLabel;
  final String whatsappLabel;
  final String? tooltip;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Align(
      alignment: alignment,
      child: PopupMenuButton<String>(
        tooltip: tooltip ?? contactLabel,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onSelected: (value) {
          switch (value) {
            case 'call':
              UrlLauncherHelper.openPhone(phone);
              break;
            case 'whatsapp':
              UrlLauncherHelper.openWhatsApp(phone);
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'call',
            child: Row(
              children: [
                Icon(
                  Icons.phone_rounded,
                  size: 20,
                  color: colorScheme.onSurface,
                ),
                AppSpacing.hGapMd,
                Text(callLabel),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'whatsapp',
            child: Row(
              children: [
                Icon(
                  Icons.chat_rounded,
                  size: 20,
                  color: colorScheme.onSurface,
                ),
                AppSpacing.hGapMd,
                Text(whatsappLabel),
              ],
            ),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.contact_phone_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              AppSpacing.hGapSm,
              Text(
                contactLabel,
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
              AppSpacing.hGapXxs,
              Icon(
                Icons.arrow_drop_down_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
