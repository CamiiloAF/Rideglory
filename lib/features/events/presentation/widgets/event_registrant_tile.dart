import 'package:flutter/widgets.dart';

import '../../../../design_system/components/event_registrant_card.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/event_registrant.dart';
import '../event_external_actions.dart';
import '../registration_labels.dart';

/// Adapta un [EventRegistrant] al componente compartido
/// [EventRegistrantCard], resolviendo las acciones de llamada.
class EventRegistrantTile extends StatelessWidget {
  const EventRegistrantTile({required this.registrant, super.key});

  final EventRegistrant registrant;

  @override
  Widget build(BuildContext context) {
    return EventRegistrantCard(
      name: registrant.fullName,
      subtitle: registrantSubtitle(registrant),
      callLabel: context.l10n.events_registrants_call,
      emergencyContactLabel: context.l10n.events_registrants_call_emergency,
      onCall: registrant.phone == null
          ? null
          : () => openPhoneDialer(registrant.phone!),
      onCallEmergencyContact: registrant.emergencyContactPhone == null
          ? null
          : () => openPhoneDialer(registrant.emergencyContactPhone!),
    );
  }
}
