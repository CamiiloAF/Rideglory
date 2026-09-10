import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/sos_outbox_item.dart';
import '../dto/sos_alert_dto.dart';

/// Acceso directo a Supabase para SOS (D16). Sin `Either` ni
/// `DomainException` aquí: eso lo traduce el repositorio.
@injectable
class SosDatasource {
  const SosDatasource(this._client);

  final SupabaseClient _client;

  static const String _sosAlertsVisibleView = 'sos_alerts_visible';
  static const String _sosAlertsTable = 'sos_alerts';

  Future<SosAlertDto> raise(SosOutboxItem item) async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'raise_sos',
      params: {
        'p_client_id': item.clientId,
        'p_event_id': item.eventId,
        'p_lat': item.position.lat,
        'p_lng': item.position.lng,
        'p_accuracy_m': item.position.accuracyM,
        'p_message': item.message,
      },
    );
    return SosAlertDto.fromJson(row);
  }

  Future<SosAlertDto> close(String sosId) async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'close_sos',
      params: {'p_sos_id': sosId},
    );
    return SosAlertDto.fromJson(row);
  }

  Future<List<SosAlertDto>> _fetchAlerts(String eventId) async {
    final rows = await _client
        .from(_sosAlertsVisibleView)
        .select()
        .eq('event_id', eventId)
        .order('created_at', ascending: false);
    return rows.map(SosAlertDto.fromJson).toList();
  }

  Stream<List<SosAlertDto>> watchAlerts(String eventId) {
    // ignore: close_sinks -- se cierra en `onCancel` del propio controller.
    late final StreamController<List<SosAlertDto>> controller;
    RealtimeChannel? channel;

    Future<void> refresh() async {
      final alerts = await _fetchAlerts(eventId);
      if (!controller.isClosed) controller.add(alerts);
    }

    controller = StreamController<List<SosAlertDto>>(
      onListen: () {
        channel = _client
            .channel('sos-alerts-$eventId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: _sosAlertsTable,
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
}
