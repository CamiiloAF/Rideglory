import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/features/events/data/service/tracking_ws_client.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

/// Minimal local WebSocket server used to exercise [TrackingWsClient]
/// against a real socket connection without hitting the network or
/// depending on the actual Rideglory backend.
class _FakeTrackingServer {
  _FakeTrackingServer._(this._server) {
    unawaited(
      _server.forEach((request) async {
        final socket = await WebSocketTransformer.upgrade(request);
        _connections.add(socket);
      }),
    );
  }

  static Future<_FakeTrackingServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return _FakeTrackingServer._(server);
  }

  final HttpServer _server;
  final StreamController<WebSocket> _connections =
      StreamController<WebSocket>.broadcast();

  String get baseUrl =>
      'http://${_server.address.address}:${_server.port}';

  /// Waits for and returns the next client connection accepted by the
  /// fake server.
  Future<WebSocket> nextConnection() =>
      _connections.stream.first.timeout(const Duration(seconds: 5));

  Stream<WebSocket> get connections => _connections.stream;

  Future<void> close() async {
    await _connections.close();
    await _server.close(force: true);
  }
}

void send(WebSocket socket, Map<String, dynamic> message) {
  socket.add(jsonEncode(message));
}

Map<String, dynamic> riderJson({
  required String userId,
  String fullName = 'Jane Rider',
  double latitude = 4.6,
  double longitude = -74.1,
  double speedKmh = 30,
  double distanceMeters = 100,
  int batteryPercent = 80,
  bool isActive = true,
  String deviceLabel = 'iPhone 14',
}) {
  return {
    'userId': userId,
    'fullName': fullName,
    'role': 'rider',
    'latitude': latitude,
    'longitude': longitude,
    'speedKmh': speedKmh,
    'distanceMeters': distanceMeters,
    'batteryPercent': batteryPercent,
    'isActive': isActive,
    'deviceLabel': deviceLabel,
    'lastUpdated': DateTime.now().toIso8601String(),
  };
}

void main() {
  late MockFirebaseAuth firebaseAuth;
  late MockUser user;
  late _FakeTrackingServer server;
  late TrackingWsClient client;

  setUp(() async {
    firebaseAuth = MockFirebaseAuth();
    user = MockUser();
    when(() => firebaseAuth.currentUser).thenReturn(user);
    when(() => user.getIdToken()).thenAnswer((_) async => 'fake-token');

    server = await _FakeTrackingServer.start();
    client = TrackingWsClient(firebaseAuth);
  });

  tearDown(() async {
    await server.close();
  });

  group('watchRiders snapshot handling', () {
    test('emits the rider list contained in a tracking.snapshot message', () async {
      final riderStream = client.watchRiders(
        eventId: 'event-1',
        baseUrl: server.baseUrl,
      );
      // ignore: close_sinks -- ephemeral test socket cleaned up by tearDown's forced server close
      final socket = await server.nextConnection();

      final emissions = <List<RiderTrackingModel>>[];
      final subscription = riderStream.listen(emissions.add);

      send(socket, {
        'type': 'tracking.snapshot',
        'data': {
          'riders': [
            riderJson(userId: 'user-1'),
            riderJson(userId: 'user-2'),
          ],
        },
      });

      await pumpEventQueue();

      expect(emissions, hasLength(1));
      expect(
        emissions.single.map((rider) => rider.userId).toSet(),
        {'user-1', 'user-2'},
      );

      await subscription.cancel();
    });
  });

  group('tracking.rider.updated', () {
    test('updates the cache and re-emits the full rider list', () async {
      final riderStream = client.watchRiders(
        eventId: 'event-1',
        baseUrl: server.baseUrl,
      );
      // ignore: close_sinks -- ephemeral test socket cleaned up by tearDown's forced server close
      final socket = await server.nextConnection();

      final emissions = <List<RiderTrackingModel>>[];
      final subscription = riderStream.listen(emissions.add);

      send(socket, {
        'type': 'tracking.snapshot',
        'data': {
          'riders': [riderJson(userId: 'user-1', speedKmh: 10)],
        },
      });
      await pumpEventQueue();

      send(socket, {
        'type': 'tracking.rider.updated',
        'data': riderJson(userId: 'user-1', speedKmh: 55),
      });
      await pumpEventQueue();

      expect(emissions, hasLength(2));
      expect(emissions.last, hasLength(1));
      expect(emissions.last.single.userId, 'user-1');
      expect(emissions.last.single.speedKmh, 55);

      await subscription.cancel();
    });

    test('adds a brand-new rider that was not part of the snapshot', () async {
      final riderStream = client.watchRiders(
        eventId: 'event-1',
        baseUrl: server.baseUrl,
      );
      // ignore: close_sinks -- ephemeral test socket cleaned up by tearDown's forced server close
      final socket = await server.nextConnection();

      final emissions = <List<RiderTrackingModel>>[];
      final subscription = riderStream.listen(emissions.add);

      send(socket, {
        'type': 'tracking.rider.updated',
        'data': riderJson(userId: 'user-new'),
      });
      await pumpEventQueue();

      expect(emissions, hasLength(1));
      expect(emissions.single.single.userId, 'user-new');

      await subscription.cancel();
    });
  });

  group('tracking.rider.left', () {
    test('removes the rider from the emitted list', () async {
      final riderStream = client.watchRiders(
        eventId: 'event-1',
        baseUrl: server.baseUrl,
      );
      // ignore: close_sinks -- ephemeral test socket cleaned up by tearDown's forced server close
      final socket = await server.nextConnection();

      final emissions = <List<RiderTrackingModel>>[];
      final subscription = riderStream.listen(emissions.add);

      send(socket, {
        'type': 'tracking.snapshot',
        'data': {
          'riders': [
            riderJson(userId: 'user-1'),
            riderJson(userId: 'user-2'),
          ],
        },
      });
      await pumpEventQueue();

      send(socket, {
        'type': 'tracking.rider.left',
        'data': {'userId': 'user-1'},
      });
      await pumpEventQueue();

      expect(emissions, hasLength(2));
      final remaining = emissions.last;
      expect(remaining, hasLength(1));
      expect(remaining.single.userId, 'user-2');

      await subscription.cancel();
    });
  });

  group('SOS alerts', () {
    test('tracking.sos.alert propagates a SosAlertModel on sosAlerts', () async {
      client.watchRiders(eventId: 'event-1', baseUrl: server.baseUrl);
      // ignore: close_sinks -- ephemeral test socket cleaned up by tearDown's forced server close
      final socket = await server.nextConnection();

      final alerts = <dynamic>[];
      final subscription = client.sosAlerts.listen(alerts.add);

      send(socket, {
        'type': 'tracking.sos.alert',
        'data': {
          'userId': 'user-1',
          'fullName': 'Jane Rider',
          'latitude': 4.6,
          'longitude': -74.1,
          'phone': '3001234567',
        },
      });
      await pumpEventQueue();

      expect(alerts, hasLength(1));
      expect(alerts.single.userId, 'user-1');
      expect(alerts.single.riderName, 'Jane Rider');
      expect(alerts.single.phone, '3001234567');

      await subscription.cancel();
    });

    test('tracking.sos.alert without userId/fullName is ignored', () async {
      client.watchRiders(eventId: 'event-1', baseUrl: server.baseUrl);
      // ignore: close_sinks -- ephemeral test socket cleaned up by tearDown's forced server close
      final socket = await server.nextConnection();

      final alerts = <dynamic>[];
      final subscription = client.sosAlerts.listen(alerts.add);

      send(socket, {
        'type': 'tracking.sos.alert',
        'data': {'latitude': 4.6, 'longitude': -74.1},
      });
      await pumpEventQueue();

      expect(alerts, isEmpty);

      await subscription.cancel();
    });

    test('tracking.sos.cleared emits the cleared userId on sosCleared', () async {
      client.watchRiders(eventId: 'event-1', baseUrl: server.baseUrl);
      // ignore: close_sinks -- ephemeral test socket cleaned up by tearDown's forced server close
      final socket = await server.nextConnection();

      final cleared = <String>[];
      final subscription = client.sosCleared.listen(cleared.add);

      send(socket, {
        'type': 'tracking.sos.cleared',
        'data': {'userId': 'user-1'},
      });
      await pumpEventQueue();

      expect(cleared, ['user-1']);

      await subscription.cancel();
    });

    test('an alert followed by its clearance surfaces both events in order', () async {
      client.watchRiders(eventId: 'event-1', baseUrl: server.baseUrl);
      // ignore: close_sinks -- ephemeral test socket cleaned up by tearDown's forced server close
      final socket = await server.nextConnection();

      final alerts = <dynamic>[];
      final cleared = <String>[];
      final alertSub = client.sosAlerts.listen(alerts.add);
      final clearedSub = client.sosCleared.listen(cleared.add);

      send(socket, {
        'type': 'tracking.sos.alert',
        'data': {'userId': 'user-1', 'fullName': 'Jane Rider'},
      });
      await pumpEventQueue();
      send(socket, {
        'type': 'tracking.sos.cleared',
        'data': {'userId': 'user-1'},
      });
      await pumpEventQueue();

      expect(alerts, hasLength(1));
      expect(cleared, ['user-1']);

      await alertSub.cancel();
      await clearedSub.cancel();
    });
  });

  group('tracking.event.ended', () {
    test('emits once on the eventEnded stream', () async {
      client.watchRiders(eventId: 'event-1', baseUrl: server.baseUrl);
      // ignore: close_sinks -- ephemeral test socket cleaned up by tearDown's forced server close
      final socket = await server.nextConnection();

      var endedCount = 0;
      final subscription = client.eventEnded.listen((_) => endedCount++);

      send(socket, {'type': 'tracking.event.ended', 'data': null});
      await pumpEventQueue();

      expect(endedCount, 1);

      await subscription.cancel();
    });
  });

  group('message parsing edge cases', () {
    test('ignores non-JSON-object and unknown-type messages without throwing', () async {
      final riderStream = client.watchRiders(
        eventId: 'event-1',
        baseUrl: server.baseUrl,
      );
      // ignore: close_sinks -- ephemeral test socket cleaned up by tearDown's forced server close
      final socket = await server.nextConnection();

      final emissions = <List<RiderTrackingModel>>[];
      final subscription = riderStream.listen(emissions.add);

      socket.add(jsonEncode(['not', 'a', 'map']));
      socket.add(jsonEncode({'type': 'tracking.unknown.event', 'data': {}}));
      await pumpEventQueue();

      expect(emissions, isEmpty);

      await subscription.cancel();
    });
  });

  group('leaveSession', () {
    test('clears the cached riders and emits an empty list', () async {
      final riderStream = client.watchRiders(
        eventId: 'event-1',
        baseUrl: server.baseUrl,
      );
      // ignore: close_sinks -- ephemeral test socket cleaned up by tearDown's forced server close
      final socket = await server.nextConnection();

      final emissions = <List<RiderTrackingModel>>[];
      final subscription = riderStream.listen(emissions.add);

      send(socket, {
        'type': 'tracking.snapshot',
        'data': {
          'riders': [riderJson(userId: 'user-1')],
        },
      });
      await pumpEventQueue();
      expect(emissions.last, hasLength(1));

      await client.leaveSession(eventId: 'event-1', userId: 'user-1');
      await pumpEventQueue();

      expect(emissions.last, isEmpty);

      await subscription.cancel();
    });
  });

  group('automatic reconnection', () {
    test(
      'attempts to reconnect a few seconds after a non-manual disconnect',
      () async {
        client.watchRiders(eventId: 'event-1', baseUrl: server.baseUrl);
        final firstSocket = await server.nextConnection();

        final secondConnection = server.connections.first.timeout(
          const Duration(seconds: 5),
        );

        // Simulate the server dropping the connection unexpectedly.
        await firstSocket.close();

        final reconnected = await secondConnection;
        expect(reconnected, isNotNull);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    test('does not reconnect after an explicit leaveSession call', () async {
      client.watchRiders(eventId: 'event-1', baseUrl: server.baseUrl);
      await server.nextConnection();

      await client.leaveSession(eventId: 'event-1', userId: 'user-1');

      final gotReconnection = await server.connections
          .first
          .timeout(
            const Duration(seconds: 4),
            onTimeout: () => throw TimeoutException('no reconnection'),
          )
          .then((_) => true)
          .catchError((_) => false);

      expect(gotReconnection, isFalse);
    });
  });
}
