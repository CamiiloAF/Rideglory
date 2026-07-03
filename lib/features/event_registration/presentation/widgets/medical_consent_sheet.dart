import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Opens the Ley 1581 de 2012 medical-data authorization as a bottom sheet,
/// shown when the rider leaves the Medical step of the registration wizard.
///
/// Resolves to the acceptance timestamp when authorized, and to `null` when
/// declined or dismissed — the caller in `RegistrationFormContent._onNext`
/// only advances (and records the consent on the registration) on a non-null
/// result.
Future<DateTime?> showMedicalConsentSheet({required BuildContext context}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const MedicalConsentSheet(),
  );
}

/// Medical-data authorization sheet (Ley 1581): a scrollable legal text and the
/// authorize/decline actions. Authorizing pops the sheet with the acceptance
/// timestamp; declining pops with `null` after a blocking message. The consent
/// is recorded per registration, so there is no backend call here.
class MedicalConsentSheet extends StatelessWidget {
  const MedicalConsentSheet({super.key});

  void _onDecline(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.registration_law1581DeclinedMessage)),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.registration_law1581_title,
                    style: const TextStyle(
                      color: AppColors.textOnDarkPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AppSpacing.gapMd,
                  Text(
                    context.l10n.registration_law1581_body,
                    style: const TextStyle(
                      color: AppColors.textOnDarkSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton(
                  label: context.l10n.registration_law1581_authorizeButton,
                  onPressed: () => Navigator.of(context).pop(DateTime.now()),
                  shape: AppButtonShape.pill,
                  height: 52,
                ),
                AppSpacing.gapSm,
                AppTextButton(
                  label: context.l10n.registration_law1581_declineButton,
                  onPressed: () => _onDecline(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
