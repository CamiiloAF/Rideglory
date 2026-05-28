import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';

/// In-memory cache of attendees per eventId, shared between the event detail
/// preview and the full attendees screen so the same `/events/{id}/registrations`
/// request isn't issued twice in a single owner session.
class AttendeesCache {
  final Map<String, List<EventRegistrationModel>> _byEventId = {};

  List<EventRegistrationModel>? read(String eventId) => _byEventId[eventId];

  void write(String eventId, List<EventRegistrationModel> registrations) {
    _byEventId[eventId] = List<EventRegistrationModel>.unmodifiable(
      registrations,
    );
  }

  void updateStatus(
    String eventId,
    String registrationId,
    RegistrationStatus status,
  ) {
    final current = _byEventId[eventId];
    if (current == null) return;
    final index = current.indexWhere((r) => r.id == registrationId);
    if (index < 0) return;
    final updated = current[index].copyWith(status: status);
    _byEventId[eventId] = List<EventRegistrationModel>.unmodifiable(
      [...current]..[index] = updated,
    );
  }

  void invalidate(String eventId) => _byEventId.remove(eventId);
}
