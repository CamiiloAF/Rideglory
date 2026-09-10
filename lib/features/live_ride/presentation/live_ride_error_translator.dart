import 'package:flutter/widgets.dart';

import '../../../core/exceptions/domain_exception.dart';
import '../../../l10n/l10n_extensions.dart';
import '../domain/live_ride_error_code.dart';

/// Traduce el código semántico de un [DomainException] de `live_ride` a la
/// cadena en español que se muestra al rider.
String liveRideErrorMessage(BuildContext context, DomainException error) {
  return switch (error.message) {
    LiveRideErrorCode.notAParticipant =>
      context.l10n.live_ride_error_not_a_participant,
    LiveRideErrorCode.eventNotStarted =>
      context.l10n.live_ride_error_event_not_started,
    LiveRideErrorCode.sosNotFound => context.l10n.live_ride_error_sos_not_found,
    LiveRideErrorCode.notAllowedToClose =>
      context.l10n.live_ride_error_not_allowed_to_close,
    LiveRideErrorCode.locationPermissionDenied =>
      context.l10n.live_ride_error_location_permission_denied,
    LiveRideErrorCode.locationServiceDisabled =>
      context.l10n.live_ride_error_location_service_disabled,
    LiveRideErrorCode.locationUnavailable =>
      context.l10n.live_ride_error_location_unavailable,
    LiveRideErrorCode.offline => context.l10n.live_ride_error_offline,
    _ => context.l10n.live_ride_error_generic,
  };
}
