import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

const _androidStoreUrl =
    'https://play.google.com/store/apps/details?id=com.camiloagudelo.rideglory';

class ForceUpdateDialog extends StatelessWidget {
  const ForceUpdateDialog({super.key});

  Future<void> _openStore() async {
    final url = Uri.parse(
      defaultTargetPlatform == TargetPlatform.iOS
          ? _androidStoreUrl // reemplazar con App Store URL cuando esté disponible
          : _androidStoreUrl,
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: Text(
          context.l10n.splash_forceUpdateTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          context.l10n.splash_forceUpdateMessage,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: _openStore,
            child: Text(
              context.l10n.splash_forceUpdateButton,
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
