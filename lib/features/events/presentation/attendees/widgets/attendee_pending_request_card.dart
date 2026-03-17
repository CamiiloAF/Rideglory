import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/attendees/attendees_cubit.dart';
import 'package:rideglory/features/events/presentation/shared/widgets/initials_avatar.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';
import 'package:rideglory/shared/widgets/modals/confirmation_dialog.dart';
import 'package:rideglory/shared/widgets/modals/dialog_type.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

class AttendeePendingRequestCard extends StatelessWidget {
  final EventRegistrationModel registration;
  final VoidCallback? onTap;

  const AttendeePendingRequestCard({
    super.key,
    required this.registration,
    this.onTap,
  });

  static Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await launcher.canLaunchUrl(uri)) {
      await launcher.launchUrl(
        uri,
        mode: launcher.LaunchMode.externalApplication,
      );
    }
  }

  static String sanitizePhone(String phone) =>
      phone.replaceAll(RegExp(r'[^\d+]'), '');

  Future<void> _confirmAction(
    BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) => ConfirmationDialog.show(
    context: context,
    title: title,
    content: content,
    dialogType: DialogType.warning,
    confirmLabel: title,
    onConfirm: onConfirm,
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final vehicleText =
        '${registration.vehicleBrand} ${registration.vehicleReference}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InitialsAvatar(
                    firstName: registration.firstName,
                    lastName: registration.lastName,
                    radius: 24,
                    backgroundColor: colorScheme.primary,
                    textStyle: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          registration.fullName,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.two_wheeler_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                vehicleText,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    EventStrings.formatTimeAgo(registration.createdDate),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: EventStrings.callAttendee,
                  icon: Icons.phone_rounded,
                  onPressed: () => openUrl('tel:${registration.phone}'),
                  isFullWidth: true,
                  height: 40,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WhatsAppButton(
                  label: EventStrings.whatsappAttendee,
                  onPressed: () => openUrl(
                    'https://wa.me/${sanitizePhone(registration.phone)}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: () => _confirmAction(
                    context,
                    title: EventStrings.approveRegistration,
                    content: EventStrings.approveConfirmMessage(
                      registration.firstName,
                    ),
                    onConfirm: () => context
                        .read<AttendeesCubit>()
                        .approveRegistration(registration.id!),
                  ),
                  borderRadius: BorderRadius.circular(24),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: colorScheme.error,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: () => _confirmAction(
                    context,
                    title: EventStrings.rejectRegistration,
                    content: EventStrings.rejectConfirmMessage(
                      registration.firstName,
                    ),
                    onConfirm: () => context
                        .read<AttendeesCubit>()
                        .rejectRegistration(registration.id!),
                  ),
                  borderRadius: BorderRadius.circular(24),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WhatsAppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _WhatsAppButton({required this.label, required this.onPressed});

  static const Color _whatsappGreen = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _whatsappGreen,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: context.labelLarge?.copyWith(
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
