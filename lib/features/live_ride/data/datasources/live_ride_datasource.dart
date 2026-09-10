import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/rider_position.dart';
import '../dto/live_ride_contacts_dto.dart';
import '../dto/live_rider_dto.dart';

/// Acceso directo a Supabase para el tracking en vivo (D15). Sin `Either`
/// ni `DomainException` aquí: eso lo traduce el repositorio.
@injectable
class LiveRideDatasource {
  const LiveRideDatasource(this._client);

  final SupabaseClient _client;

  static const String _liveRidersView = 'live_riders';
  static const String _livePositionsTable = 'live_positions';
  static const String _eventsTable = 'events';

  String get currentUserId => _client.auth.currentUser!.id;

  Future<List<LiveRiderDto>> _fetchRiders(String eventId) async {
    final rows = await _client
        .from(_liveRidersView)
        .select()
        .eq('event_id', eventId)
        .order('is_organizer', ascending: false);
    return rows.map(LiveRiderDto.fromJson).toList();
  }

  /// Realtime sobre `live_positions`, sin Broadcast (D15): cuando cambia
  /// una fila del evento, se relee la vista completa. Es más simple que
  /// mezclar el payload del cambio con el estado en memoria y sigue siendo
  /// robusto porque quien entra tarde ya recibe el primer `select`.
  Stream<List<LiveRiderDto>> watchRiders(String eventId) {
    // ignore: close_sinks -- se cierra en `onCancel` del propio controller.
    late final StreamController<List<LiveRiderDto>> controller;
    RealtimeChannel? channel;

    Future<void> refresh() async {
      final riders = await _fetchRiders(eventId);
      if (!controller.isClosed) controller.add(riders);
    }

    controller = StreamController<List<LiveRiderDto>>(
      onListen: () {
        channel = _client
            .channel('live-positions-$eventId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: _livePositionsTable,
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'event_id',
                value: eventId,
              ),
              callback: (payload) => refresh(),
            )
            .subscribe();
        refresh();
      },
      onCancel: () async {
        final activeChannel = channel;
        if (activeChannel != null) await _client.removeChannel(activeChannel);
      },
    );
    return controller.stream;
  }

  Future<void> upsertPosition(String eventId, RiderPosition position) {
    return _client.rpc<void>(
      'upsert_live_position',
      params: {
        'p_event_id': eventId,
        'p_lat': position.lat,
        'p_lng': position.lng,
        'p_speed_kmh': position.speedKmh,
        'p_heading': position.heading,
        'p_battery_pct': position.batteryPct,
        'p_accuracy_m': position.accuracyM,
        'p_recorded_at': position.recordedAt.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> endRide(String eventId) {
    return _client.rpc<void>('end_live_ride', params: {'p_event_id': eventId});
  }

  Future<LiveRideContactsDto> getContacts(String eventId) async {
    final rows = await _client.rpc<List<dynamic>>(
      'get_live_ride_contacts',
      params: {'p_event_id': eventId},
    );
    final row = rows.first as Map<String, dynamic>;
    return LiveRideContactsDto.fromJson(row);
  }

  Stream<bool> watchEventFinished(String eventId) {
    // ignore: close_sinks -- se cierra en `onCancel` del propio controller.
    late final StreamController<bool> controller;
    RealtimeChannel? channel;

    Future<void> refresh() async {
      final row = await _client
          .from(_eventsTable)
          .select('state')
          .eq('id', eventId)
          .single();
      if (!controller.isClosed) controller.add(row['state'] == 'finished');
    }

    controller = StreamController<bool>(
      onListen: () {
        channel = _client
            .channel('live-ride-event-$eventId')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: _eventsTable,
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'id',
                value: eventId,
              ),
              callback: (payload) => refresh(),
            )
            .subscribe();
        refresh();
      },
      onCancel: () async {
        final activeChannel = channel;
        if (activeChannel != null) await _client.removeChannel(activeChannel);
      },
    );
    return controller.stream;
  }
}
