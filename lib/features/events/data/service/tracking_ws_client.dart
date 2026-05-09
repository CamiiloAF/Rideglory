import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/http/api_routes.dart';
import 'package:rideglory/features/events/data/dto/rider_tracking_dto.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
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
  final Map<String, RiderTrackingModel> _ridersByUserId = {};

  Timer? _reconnectTimer;
  String? _activeEventId;
  String? _baseUrl;
  bool _manualDisconnect = false;

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
    if (_channel != null) {
      return;
    }
    final token = await _firebaseAuth.currentUser?.getIdToken();
    final uri = _wsUri(baseUrl: baseUrl, eventId: eventId, token: token);
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    _subscription = channel.stream.listen(
      _onMessage,
      onDone: _onDisconnected,
      onError: (_) => _onDisconnected(),
      cancelOnError: true,
    );
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
      _handleSnapshot(data);
      return;
    }
    if (type == 'tracking.rider.updated') {
      _handleRiderUpdated(data);
      return;
    }
    if (type == 'tracking.rider.left') {
      _handleRiderLeft(data);
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
