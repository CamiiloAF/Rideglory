import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dto/event_dto.dart';
import '../dto/event_registrant_dto.dart';
import '../dto/event_route_change_dto.dart';
import '../dto/event_vehicle_option_dto.dart';

/// Acceso directo a Supabase para eventos. Sin `Either` ni
/// `DomainException` aquí: eso lo traduce el repositorio.
@injectable
class EventsDatasource {
  const EventsDatasource(this._client);

  final SupabaseClient _client;

  static const String _eventsPublicView = 'events_public';
  static const String _eventsTable = 'events';
  static const String _registrationsTable = 'event_registrations';
  static const String _routeChangesTable = 'event_route_changes';
  static const String _organizerView = 'event_registrations_for_organizer';
  static const String _bucket = 'event-images';
  static const Duration _signedUrlTtl = Duration(hours: 1);

  String get currentUserId => _client.auth.currentUser!.id;

  Future<List<EventDto>> fetchUpcomingEvents() async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final rows = await _client
        .from(_eventsPublicView)
        .select()
        .inFilter('state', ['published', 'started'])
        .gte('start_at', nowIso)
        .order('start_at');
    final events = rows.map(EventDto.fromJson).toList();
    return _withMyRegistrationStatus(events);
  }

  Future<List<EventDto>> fetchMyEvents() async {
    final userId = currentUserId;
    final myRegistrations = await _client
        .from(_registrationsTable)
        .select('event_id')
        .eq('user_id', userId);
    final registeredEventIds = myRegistrations
        .map((row) => row['event_id'] as String)
        .toSet();

    final ownedRows = await _client
        .from(_eventsPublicView)
        .select()
        .eq('owner_id', userId);

    final events = <String, EventDto>{
      for (final row in ownedRows)
        (row['id'] as String): EventDto.fromJson(row),
    };

    if (registeredEventIds.isNotEmpty) {
      final registeredRows = await _client
          .from(_eventsPublicView)
          .select()
          .inFilter('id', registeredEventIds.toList());
      for (final row in registeredRows) {
        events[row['id'] as String] = EventDto.fromJson(row);
      }
    }

    final sorted = events.values.toList()
      ..sort((a, b) => b.startAt.compareTo(a.startAt));
    return _withMyRegistrationStatus(sorted);
  }

  Future<EventDto> fetchEventDetail(String eventId) async {
    final row = await _client
        .from(_eventsPublicView)
        .select()
        .eq('id', eventId)
        .single();
    final dto = EventDto.fromJson(row);
    final withStatus = await _withMyRegistrationStatus([dto]);
    return withStatus.first;
  }

  Future<List<EventDto>> _withMyRegistrationStatus(
    List<EventDto> events,
  ) async {
    if (events.isEmpty) return events;
    final userId = currentUserId;
    final ids = events.map((event) => event.id).toList();
    final registrationRows = await _client
        .from(_registrationsTable)
        .select('event_id, status')
        .eq('user_id', userId)
        .inFilter('event_id', ids);
    final statusByEventId = {
      for (final row in registrationRows)
        row['event_id'] as String: row['status'] as String,
    };
    return events
        .map(
          (event) =>
              event.copyWithRegistrationStatus(statusByEventId[event.id]),
        )
        .toList();
  }

  Future<String?> createSignedImageUrl(String? imagePath) async {
    if (imagePath == null) return null;
    return _client.storage
        .from(_bucket)
        .createSignedUrl(imagePath, _signedUrlTtl.inSeconds);
  }

  Future<List<EventRouteChangeDto>> fetchRouteChanges(String eventId) async {
    final rows = await _client
        .from(_routeChangesTable)
        .select()
        .eq('event_id', eventId)
        .order('created_at', ascending: false);
    return rows.map(EventRouteChangeDto.fromJson).toList();
  }

  Future<List<EventVehicleOptionDto>> fetchMyVehicles() async {
    final rows = await _client
        .from('vehicles')
        .select('id, name, brand, model, license_plate')
        .eq('owner_id', currentUserId)
        .filter('archived_at', 'is', null)
        .order('is_main', ascending: false);
    return rows.map(EventVehicleOptionDto.fromJson).toList();
  }

  Future<String> createDraftEvent(Map<String, dynamic> values) async {
    final row = await _client
        .from(_eventsTable)
        .insert({...values, 'owner_id': currentUserId, 'state': 'draft'})
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> publishEvent(String eventId) async {
    await _client
        .from(_eventsTable)
        .update({'state': 'published'})
        .eq('id', eventId);
  }

  Future<void> startEvent(String eventId) async {
    await _client
        .from(_eventsTable)
        .update({'state': 'started'})
        .eq('id', eventId);
  }

  Future<void> cancelEvent(String eventId) async {
    await _client
        .from(_eventsTable)
        .update({'state': 'cancelled'})
        .eq('id', eventId);
  }

  Future<void> addRouteChange(String eventId, String message) async {
    await _client.from(_routeChangesTable).insert({
      'event_id': eventId,
      'message': message,
    });
  }

  Future<void> insertRegistration(Map<String, dynamic> values) async {
    await _client.from(_registrationsTable).insert({
      ...values,
      'user_id': currentUserId,
    });
  }

  Future<void> cancelMyRegistration(String eventId) async {
    await _client
        .from(_registrationsTable)
        .update({'status': 'cancelled'})
        .eq('event_id', eventId)
        .eq('user_id', currentUserId);
  }

  Future<List<EventRegistrantDto>> fetchRegistrants(String eventId) async {
    final rows = await _client
        .from(_organizerView)
        .select()
        .eq('event_id', eventId)
        .order('created_at');
    return rows.map(EventRegistrantDto.fromJson).toList();
  }

  Future<void> setRegistrationStatus(
    String registrationId,
    String status,
  ) async {
    await _client.rpc<void>(
      'organizer_set_registration_status',
      params: {'p_registration_id': registrationId, 'p_status': status},
    );
  }

  Future<String> uploadEventImage(String eventId, String localFilePath) async {
    final file = File(localFilePath);
    final extension = localFilePath.split('.').last.toLowerCase();
    final path = '$currentUserId/$eventId.$extension';
    await _client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          await file.readAsBytes(),
          fileOptions: FileOptions(
            contentType: 'image/$extension',
            upsert: true,
          ),
        );
    await _client
        .from(_eventsTable)
        .update({'image_path': path})
        .eq('id', eventId);
    return path;
  }
}
