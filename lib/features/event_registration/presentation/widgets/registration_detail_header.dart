import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/event_registration/constants/registration_strings.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/shared/widgets/initials_avatar.dart';
import 'package:rideglory/features/events/presentation/shared/widgets/registration_status_chip.dart';

class RegistrationDetailHeader extends StatelessWidget {
  const RegistrationDetailHeader({super.key, required this.registration});

  final EventRegistrationModel registration;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final dateText = registration.createdDate != null
        ? '${RegistrationStrings.appliedOnPrefix}${DateFormat('d MMM yyyy', 'es').format(registration.createdDate!)}'
        : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              InitialsAvatar(
                firstName: registration.firstName,
                lastName: registration.lastName,
                radius: 48,
              ),
              Positioned(
                bottom: -8,
                child: RegistrationStatusChip(status: registration.status),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            registration.fullName,
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (dateText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              dateText,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
