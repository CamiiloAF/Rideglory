import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/events/presentation/tracking/cubit/live_tracking_cubit.dart';
import 'package:rideglory/features/events/presentation/tracking/cubit/live_tracking_cubit_factory.dart';

/// Keeps [LiveTrackingCubit] alive when the live map route is popped so
/// Firestore + GPS tracking continue until sign-out or switching events.
@lazySingleton
class LiveTrackingSessionHolder {
  LiveTrackingSessionHolder(this._factory, this._authService) {
    _authService.authStateChanges.listen((user) {
      if (user == null) {
        unawaited(_clearSession());
      }
    });
  }

  final LiveTrackingCubitFactory _factory;
  final AuthService _authService;

  LiveTrackingCubit? _cubit;
  String? _eventId;

  /// Returns the active cubit for [eventId], creating and starting it if needed.
  LiveTrackingCubit obtainForEvent({
    required String eventId,
    required String eventOwnerId,
  }) {
    if (_cubit != null && _eventId == eventId) {
      return _cubit!;
    }

    final previous = _cubit;
    final cubit = _factory.create(eventId: eventId, eventOwnerId: eventOwnerId);
    _cubit = cubit;
    _eventId = eventId;

    unawaited(() async {
      await previous?.close();
      if (identical(_cubit, cubit)) {
        await cubit.start();
      }
    }());

    return cubit;
  }

  /// Ends tracking for this event (e.g. organizer stopped the ride).
  Future<void> stopSessionForEvent(String eventId) async {
    if (_eventId == eventId) {
      await _clearSession();
    }
  }

  Future<void> _clearSession() async {
    final cubit = _cubit;
    _cubit = null;
    _eventId = null;
    await cubit?.close();
  }
}
