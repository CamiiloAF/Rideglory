# Tech Lead Handoff — Phase 01: soft-delete de vehículos

**Date:** 2026-06-16T21:50:10Z
**Tech Lead:** claude-sonnet-4-6
**Veredicto:** READY

---

## Veredicto

**READY** — Sin blockers. Los cambios implementan exactamente lo especificado en el PRD y el change map del architect. BUG-01 (exposición de `isDeleted` al cliente) fue detectado por QA y corregido dentro de la misma fase. Los 17 tests Jest ejercitan el `VehiclesService` real. La migración es estrictamente aditiva. El endpoint nuevo en api-gateway está en posición correcta respecto al orden de rutas. Pruebas manuales de integración quedan pendientes para el humano antes de desplegar (condición documentada en REVIEW_CHECKLIST.md).

---

## Hallazgos

### PASS — Todos los AC cubiertos

| AC | Estado |
|----|--------|
| CA-01 `GET /my` excluye isDeleted/isArchived | PASS |
| CA-02 soft-delete retorna 200, no borra fila | PASS |
| CA-03 403 cuando owner distinto | PASS (con guard: $transaction no invocado) |
| CA-04 404 UUID inexistente | PASS |
| CA-05 promoción de main canónica (desc) | PASS (con guard de orden) |
| CA-06 no promoción cuando no era main | PASS |
| CA-07 findByIdOrNull sin filtro isDeleted | PASS (con guard) |
| CA-08 create() cuenta solo activos | PASS |
| CA-09 findMainVehicleByOwnerId filtra ambos | PASS |
| CA-10 migración aditiva | PASS |
| CA-11 isDeleted no expuesto al cliente | PASS (BUG-01 resuelto; omit) |
| CA-12 TypeScript 0 errores | PASS |

### Observación menor (no bloqueante)

`isArchived` no está en el `omit` de `findByOwnerId` — pero este campo ya existía en la API antes de esta fase y no es nuevo. Consistente con el comportamiento anterior. No es un AC de esta fase.

---

## Seguridad

- Sin secretos, URLs hardcodeadas ni PII en logs.
- Sin SQL concatenado — todo via Prisma ORM parametrizado.
- Ownership derivado exclusivamente de `getAuthenticatedUser(request).id` (Firebase token), nunca del body del request.
- `ParseUUIDPipe` en el path param `vehicleId` previene inyección de valores malformados.
- `$transaction` garantiza atomicidad: ownership check → soft-delete → promoción de main en un bloque; rollback automático si algún paso falla.
- `RpcCustomExceptionFilter` normaliza correctamente los `RpcException` con `{ status, message }` antes de responder al cliente.
- Campo `isDeleted` excluido de la respuesta HTTP via `omit: { isDeleted: true }` en Prisma (Prisma 7.x). Protegido por tests TC-11.

---

## Arquitectura

- **Change map completado al 100%**: los 6 archivos del change map del architect están modificados/creados. Sin archivos fuera del mapa.
- **Orden de rutas en api-gateway**: `@Delete('my/:vehicleId')` en línea 103, antes de `@Get(':id')` (140) y `@Delete('hard-delete/:id')` (169). Sin `@Delete(':id')` genérico. Guardrail cumplido.
- **`findByIdOrNull` intacto**: `where: { id }` sin filtro `isDeleted`. Snapshots históricos de events-ms preservados. Guardrail crítico cumplido.
- **`hard-delete/:id` intacto**: línea 169 del api-gateway controller, sin modificaciones.
- **Orquestación api-gateway**: maintenances-ms primero (timeout 15s), vehicles-ms segundo. Si maintenances-ms falla con 502, el vehículo NO se soft-delete — consistencia conservadora según spec.
- **Criterio de promoción canónico**: `findFirst({ where: { ownerId, isArchived: false, isDeleted: false }, orderBy: { createdAt: 'desc' } })` dentro de `$transaction`. Documentado para Fase 3.
- **Flutter**: sin cambios, `dart analyze` limpio.

---

## Tests

- **17 tests Jest** (`vehicles.service.spec.ts`) — ejercitan el `VehiclesService` real con Prisma mockeado via `jest.mock('../generated/prisma')`. Cada test falla si se revierte el cambio que cubre.
- **Guards críticos presentes**:
  - TC-03: aserta que `$transaction` no se invoca cuando el ownership falla (403 antes del commit).
  - TC-05: aserta `orderBy: { createdAt: 'desc' }` exactamente; falla si se cambia a `asc`.
  - TC-08: aserta que `call.where` no tiene propiedad `isDeleted` (guard para `findByIdOrNull`).
  - TC-11: aserta que `call.omit` tiene `isDeleted: true` en la llamada a `findMany`.
- **Suite baseline**: 3 suites / 43 tests (27 baseline + 16 nuevos en la primera iteración, reescritos a 17 tests reales en la segunda iteración de QA).
- **TypeScript**: `tsc --noEmit` exit 0 en ambos microservicios.

---

## Pruebas manuales

Pendientes para el humano antes de desplegar. Ver `REVIEW_CHECKLIST.md` para la lista completa (M-01 a M-09). Requieren:

1. Aplicar migración localmente: `cd rideglory-api/vehicles-ms && npx prisma migrate dev`
2. Levantar el backend completo localmente.
3. Ejecutar los 9 casos manuales (soft-delete exitoso, exclusión del listado, verificación de fila en DB, 403, 404, promoción de main, sin main tras delete del único, hard-delete intacto, vehículo nuevo como main).

La QA clasifica la calidad como **conditional** hasta que M-01 a M-09 se ejecuten manualmente.
