const express = require('express');
const cors = require('cors');
const { WebSocketServer } = require('ws');
const { createServer } = require('http');
const { TrackingStore } = require('./tracking_store');

const PORT = Number.parseInt(process.env.PORT ?? '3010', 10);
const TRACKING_TTL_MS = Number.parseInt(
  process.env.TRACKING_TTL_MS ?? `${45 * 1000}`,
  10,
);
const HEARTBEAT_INTERVAL_MS = Number.parseInt(
  process.env.HEARTBEAT_INTERVAL_MS ?? `${10 * 1000}`,
  10,
);

const app = express();
app.use(cors());
app.use(express.json());

const trackingStore = new TrackingStore();
const socketsByEventId = new Map();

app.get('/health', (_, response) => {
  response.json({ ok: true, service: 'tracking-ms' });
});

app.post('/events/:eventId/tracking/session/start', (request, response) => {
  const eventId = request.params.eventId;
  const rider = request.body?.rider;
  if (!rider?.userId) {
    response.status(400).json({ message: 'rider.userId is required' });
    return;
  }

  const normalizedRider = normalizeRiderPayload(rider);
  trackingStore.upsertRider(eventId, normalizedRider);
  broadcast(eventId, {
    type: 'tracking.rider.updated',
    data: normalizedRider,
  });
  response.status(202).json({ accepted: true });
});

app.post('/events/:eventId/tracking/session/stop', (request, response) => {
  const eventId = request.params.eventId;
  const userId = request.body?.userId;
  if (!userId) {
    response.status(400).json({ message: 'userId is required' });
    return;
  }
  trackingStore.removeRider(eventId, userId);
  broadcast(eventId, {
    type: 'tracking.rider.left',
    data: { userId },
  });
  response.status(202).json({ accepted: true });
});

app.get('/events/:eventId/tracking/snapshot', (request, response) => {
  const eventId = request.params.eventId;
  response.json(trackingStore.snapshot(eventId));
});

const httpServer = createServer(app);

const wsServer = new WebSocketServer({
  server: httpServer,
  path: '/api/tracking/ws',
});

wsServer.on('connection', (socket, incomingRequest) => {
  const url = new URL(incomingRequest.url, 'http://localhost');
  const eventId = url.searchParams.get('eventId');
  if (!eventId) {
    socket.send(
      JSON.stringify({
        type: 'tracking.error',
        data: { message: 'eventId query param is required' },
      }),
    );
    socket.close();
    return;
  }

  attachSocketToEvent(eventId, socket);
  socket.send(
    JSON.stringify({
      type: 'tracking.snapshot',
      data: { riders: trackingStore.snapshot(eventId) },
    }),
  );

  socket.on('message', (rawMessage) => {
    try {
      const decoded = JSON.parse(rawMessage.toString());
      handleSocketMessage({
        eventId,
        socket,
        message: decoded,
      });
    } catch (error) {
      socket.send(
        JSON.stringify({
          type: 'tracking.error',
          data: { message: 'invalid_json', details: `${error}` },
        }),
      );
    }
  });

  socket.on('close', () => {
    detachSocketFromEvent(eventId, socket);
  });
});

setInterval(() => {
  trackingStore.pruneInactive(TRACKING_TTL_MS);
  for (const [eventId] of socketsByEventId.entries()) {
    broadcast(eventId, {
      type: 'tracking.snapshot',
      data: { riders: trackingStore.snapshot(eventId) },
    });
  }
}, HEARTBEAT_INTERVAL_MS);

httpServer.listen(PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`tracking-ms running on port ${PORT}`);
});

function handleSocketMessage({ eventId, socket, message }) {
  const type = message?.type;
  const data = message?.data ?? {};

  if (type === 'tracking.join') {
    socket.send(
      JSON.stringify({
        type: 'tracking.snapshot',
        data: { riders: trackingStore.snapshot(eventId) },
      }),
    );
    return;
  }

  if (type === 'tracking.location.update') {
    const normalizedRider = normalizeRiderPayload(data);
    if (!normalizedRider.userId) {
      socket.send(
        JSON.stringify({
          type: 'tracking.error',
          data: { message: 'tracking.location.update requires userId' },
        }),
      );
      return;
    }
    trackingStore.upsertRider(eventId, normalizedRider);
    broadcast(eventId, {
      type: 'tracking.rider.updated',
      data: normalizedRider,
    });
    return;
  }

  if (type === 'tracking.leave') {
    const userId = data.userId;
    if (!userId) {
      return;
    }
    trackingStore.removeRider(eventId, userId);
    broadcast(eventId, {
      type: 'tracking.rider.left',
      data: { userId },
    });
    return;
  }

  if (type === 'tracking.heartbeat') {
    socket.send(JSON.stringify({ type: 'tracking.pong', data: {} }));
  }
}

function normalizeRiderPayload(riderData) {
  return {
    userId: String(riderData.userId ?? ''),
    firstName: String(riderData.firstName ?? ''),
    lastName: String(riderData.lastName ?? ''),
    role: riderData.role === 'lead' ? 'lead' : 'rider',
    latitude: Number(riderData.latitude ?? 0),
    longitude: Number(riderData.longitude ?? 0),
    speedKmh: Number(riderData.speedKmh ?? 0),
    distanceMeters: Number(riderData.distanceMeters ?? 0),
    batteryPercent: Number(riderData.batteryPercent ?? -1),
    isActive: riderData.isActive !== false,
    deviceLabel: String(riderData.deviceLabel ?? ''),
    lastUpdated:
      typeof riderData.lastUpdated === 'string'
        ? riderData.lastUpdated
        : new Date().toISOString(),
  };
}

function attachSocketToEvent(eventId, socket) {
  if (!socketsByEventId.has(eventId)) {
    socketsByEventId.set(eventId, new Set());
  }
  socketsByEventId.get(eventId).add(socket);
}

function detachSocketFromEvent(eventId, socket) {
  const sockets = socketsByEventId.get(eventId);
  if (!sockets) {
    return;
  }
  sockets.delete(socket);
  if (sockets.size == 0) {
    socketsByEventId.delete(eventId);
  }
}

function broadcast(eventId, payload) {
  const sockets = socketsByEventId.get(eventId);
  if (!sockets || sockets.size === 0) {
    return;
  }
  const serializedPayload = JSON.stringify(payload);
  for (const socket of sockets) {
    if (socket.readyState === 1) {
      socket.send(serializedPayload);
    }
  }
}
