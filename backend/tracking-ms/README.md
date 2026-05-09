# Tracking MS (Rideglory)

Microservicio dedicado para live tracking de eventos. Mantiene presencia en tiempo real por `eventId`, publica snapshots y actualizaciones incrementales para el mapa en vivo.

## Responsabilidades

- Gestión de sesiones de tracking por evento.
- Ingesta de posiciones en tiempo real.
- Broadcast WebSocket a participantes del evento.
- TTL para limpieza de riders inactivos.

## API REST

- `POST /events/:eventId/tracking/session/start`
  - Body:
    ```json
    {
      "rider": {
        "userId": "u-1",
        "firstName": "Ana",
        "lastName": "Pérez",
        "role": "lead",
        "latitude": 4.81,
        "longitude": -75.69,
        "speedKmh": 0,
        "distanceMeters": 0,
        "batteryPercent": 98,
        "isActive": true,
        "deviceLabel": "Android",
        "lastUpdated": "2026-05-09T06:00:00.000Z"
      }
    }
    ```
- `POST /events/:eventId/tracking/session/stop`
  - Body:
    ```json
    {
      "userId": "u-1"
    }
    ```
- `GET /events/:eventId/tracking/snapshot`
  - Respuesta: `Rider[]`

## WebSocket

- URL: `ws://<host>/api/tracking/ws?eventId=<eventId>&token=<jwt>`
- Eventos client -> server:
  - `tracking.join`
  - `tracking.location.update`
  - `tracking.leave`
  - `tracking.heartbeat`
- Eventos server -> client:
  - `tracking.snapshot`
  - `tracking.rider.updated`
  - `tracking.rider.left`
  - `tracking.error`

## Ejemplo payload WebSocket

```json
{
  "type": "tracking.location.update",
  "data": {
    "eventId": "evt-1",
    "userId": "u-1",
    "latitude": 4.812,
    "longitude": -75.695,
    "speedKmh": 35.2,
    "distanceMeters": 1200,
    "batteryPercent": 86
  }
}
```

## Variables de entorno

- `PORT` (default `3010`)
- `TRACKING_TTL_MS` (default `45000`)
- `HEARTBEAT_INTERVAL_MS` (default `10000`)
