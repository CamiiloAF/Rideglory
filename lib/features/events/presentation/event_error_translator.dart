import 'package:flutter/widgets.dart';

import '../../../core/exceptions/domain_exception.dart';
import '../../../l10n/l10n_extensions.dart';
import '../domain/event_error_code.dart';

/// Traduce el código semántico de un [DomainException] de `events` a la
/// cadena en español que se muestra al rider.
String eventErrorMessage(BuildContext context, DomainException error) {
  return switch (error.message) {
    EventErrorCode.underage => context.l10n.events_register_underage_error,
    EventErrorCode.birthDateRequired =>
      context.l10n.events_register_underage_error,
    EventErrorCode.alreadyRegistered =>
      context.l10n.events_register_already_registered_error,
    EventErrorCode.offline => context.l10n.common_offline_body,
    _ => context.l10n.events_register_generic_error,
  };
}
