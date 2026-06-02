import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/http/api_routes.dart';
import 'package:rideglory/features/events/data/dto/rider_tracking_dto.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/domain/model/sos_alert_model.dart';
import 'package:rideglory/features/events/domain/model/update_location_request.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

@lazySingleton
class TrackingWsClient {
  TrackingWsClient(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final StreamController<List<RiderTrackingModel>> _ridersController =
      StreamController<List<RiderTrackingModel>>.broadcast();
  final StreamController<SosAlertModel> _sosController =
      StreamController<SosAlertModel>.broadcast();
  final StreamController<String> _sosClearedController =
      StreamController<String>.broadcast();
  final StreamController<void> _eventEndedController =
      StreamController<void>.broadcast();
  final Map<String, RiderTrackingModel> _ridersByUserId = {};

  Timer? _reconnectTimer;
  String? _activeEventId;
  String? _baseUrl;
  bool _manualDisconnect = false;

  /// Stream of SOS alerts broadcast by other riders.
  Stream<SosAlertModel> get sosAlerts => _sosController.stream;

  /// Stream emitting the userId of a rider whose SOS was cleared/cancelled.
  Stream<String> get sosCleared => _sosClearedController.stream;

  /// Stream that emits once when the organizer ends the ride.
  Stream<void> get eventEnded => _eventEndedController.stream;

  Stream<List<RiderTrackingModel>> watchRiders({
    required String eventId,
    required String baseUrl,
  }) {
    _activeEventId = eventId;
    _baseUrl = baseUrl;
    _manualDisconnect = false;
    unawaited(_connect(eventId: eventId, baseUrl: baseUrl));
    return _ridersController.stream;
  }

  /// Publishes a SOS alert to the tracking gateway.
  void publishSos({
    required String eventId,
    required String userId,
    double? latitude,
    double? longitude,
  }) {
    _channel?.sink.add(
      jsonEncode({
        'type': 'tracking.sos',
        'data': {
          'eventId': eventId,
          'userId': userId,
          'latitude': ?latitude,
          'longitude': ?longitude,
        },
      }),
    );
  }

  /// Cancels (clears) the current user's SOS alert on the gateway.
  void cancelSos({required String eventId, required String userId}) {
    _channel?.sink.add(
      jsonEncode({
        'type': 'tracking.sos.cancel',
        'data': {'eventId': eventId, 'userId': userId},
      }),
    );
  }

  Future<void> publishLocation(UpdateLocationRequest request) async {
    final channel = _channel;
    if (channel == null) {
      return;
    }
    channel.sink.add(
      jsonEncode({
        'type': 'tracking.location.update',
        'data': {
          'eventId': request.eventId,
          'userId': request.userId,
          'latitude': request.latitude,
          'longitude': request.longitude,
          'speedKmh': request.speedKmh,
          'distanceMeters': request.distanceMeters,
          'batteryPercent': request.batteryPercent,
        },
      }),
    );
  }

  Future<void> leaveSession({
    required String eventId,
    required String userId,
  }) async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _channel?.sink.add(
      jsonEncode({
        'type': 'tracking.leave',
        'data': {'eventId': eventId, 'userId': userId},
      }),
    );
    await _disposeChannel();
    _ridersByUserId.clear();
    if (!_ridersController.isClosed) {
      _ridersController.add(const <RiderTrackingModel>[]);
    }
  }

  Future<void> _connect({
    required String eventId,
    required String baseUrl,
  }) async {
    final existingChannel = _channel;
    if (existingChannel != null && _activeEventId == eventId) {
      developer.log('Tracking WS already connected for event $eventId');
      return;
    }

    if (existingChannel != null && _activeEventId != eventId) {
      developer.log(
        'Tracking WS reconnecting for new event. old=$_activeEventId new=$eventId',
      );
      await _disposeChannel();
    }

    final token = await _firebaseAuth.currentUser?.getIdToken();
    if (token == null || token.isEmpty) {
      developer.log('Tracking WS aborted: no auth token.');
      _ridersController.addError(StateError('No auth token for WS'));
      return;
    }
    final uri = _wsUri(baseUrl: baseUrl, eventId: eventId, token: token);
    developer.log('Tracking WS connecting to $uri');
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    _subscription = channel.stream.listen(
      _onMessage,
      onDone: _onDisconnected,
      onError: (error) {
        developer.log('Tracking WS stream error: $error');
        _onDisconnected();
      },
      cancelOnError: true,
    );
    developer.log('Tracking WS sending join for event $eventId');
    channel.sink.add(
      jsonEncode({'type': 'tracking.join', 'data': {'eventId': eventId}}),
    );
  }

  Uri _wsUri({
    required String baseUrl,
    required String eventId,
    required String? token,
  }) {
    final parsedBase = Uri.parse(baseUrl);
    final wsScheme = parsedBase.scheme == 'https' ? 'wss' : 'ws';
    final normalizedPath = parsedBase.path.endsWith('/')
        ? parsedBase.path.substring(0, parsedBase.path.length - 1)
        : parsedBase.path;
    final wsPath = '$normalizedPath${ApiRoutes.trackingWs}';
    return parsedBase.replace(
      scheme: wsScheme,
      path: wsPath,
      queryParameters: {
        'eventId': eventId,
        if (token != null && token.isNotEmpty) 'token': token,
      },
    );
  }

  void _onMessage(dynamic rawData) {
    if (rawData is! String) {
      return;
    }
    final decoded = jsonDecode(rawData);
    if (decoded is! Map<String, dynamic>) {
      return;
    }
    final type = decoded['type'];
    final data = decoded['data'];
    if (type == 'tracking.snapshot') {
      developer.log('Tracking WS received snapshot event.');
      _handleSnapshot(data);
      return;
    }
    if (type == 'tracking.rider.updated') {
      developer.log('Tracking WS received rider update event.');
      _handleRiderUpdated(data);
      return;
    }
    if (type == 'tracking.rider.left') {
      _handleRiderLeft(data);
      return;
    }
    if (type == 'tracking.sos.alert') {
      _handleSosAlert(data);
      return;
    }
    if (type == 'tracking.sos.cleared') {
      _handleSosCleared(data);
      return;
    }
    if (type == 'tracking.event.ended') {
      developer.log('Tracking WS received event.ended.');
      if (!_eventEndedController.isClosed) {
        _eventEndedController.add(null);
      }
    }
  }

  void _handleSnapshot(Object? payload) {
    if (payload is! Map<String, dynamic>) {
      return;
    }
    final list = payload['riders'];
    if (list is! List<dynamic>) {
      return;
    }
    _ridersByUserId.clear();
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        final rider = RiderTrackingDto.fromJson(item);
        _ridersByUserId[rider.userId] = rider;
      }
    }
    _emitRiders();
  }

  void _handleRiderUpdated(Object? payload) {
    if (payload is! Map<String, dynamic>) {
      return;
    }
    final rider = RiderTrackingDto.fromJson(payload);
    _ridersByUserId[rider.userId] = rider;
    _emitRiders();
  }

  void _handleRiderLeft(Object? payload) {
    if (payload is! Map<String, dynamic>) {
      return;
    }
    final userId = payload['userId'];
    if (userId is! String) {
      return;
    }
    _ridersByUserId.remove(userId);
    _emitRiders();
  }

  void _handleSosAlert(Object? payload) {
    if (payload is! Map<String, dynamic>) return;
    final userId = payload['userId'] as String?;
    final fullName = payload['fullName'] as String?;
    if (userId == null || fullName == null) return;

    final alert = SosAlertModel(
      userId: userId,
      riderName: fullName,
      latitude: (payload['latitude'] as num?)?.toDouble(),
      longitude: (payload['longitude'] as num?)?.toDouble(),
      phone: payload['phone'] as String?,
    );
    if (!_sosController.isClosed) {
      _sosController.add(alert);
    }
  }

  void _handleSosCleared(Object? payload) {
    if (payload is! Map<String, dynamic>) return;
    final userId = payload['userId'] as String?;
    if (userId == null) return;
    if (!_sosClearedController.isClosed) {
      _sosClearedController.add(userId);
    }
  }

  void _emitRiders() {
    if (_ridersController.isClosed) {
      return;
    }
    _ridersController.add(_ridersByUserId.values.toList(growable: false));
  }

  Future<void> _disposeChannel() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  void _onDisconnected() {
    developer.log('Tracking WS disconnected.');
    unawaited(_disposeChannel());
    if (_manualDisconnect) {
      return;
    }
    final eventId = _activeEventId;
    final baseUrl = _baseUrl;
    if (eventId == null || baseUrl == null) {
      return;
    }
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      unawaited(_connect(eventId: eventId, baseUrl: baseUrl));
    });
  }
}
