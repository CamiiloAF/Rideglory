# Sentry Bug Report — 2026-06-16

Proyectos auditados: **rideglory** (Flutter) · **rideglory-nestjs** (NestJS/api-gateway)  
Período: últimas 24 h · Issues activos sin resolver: **9 Flutter + 1 NestJS**

---

## Resumen ejecutivo

| # | Severidad | Issue(s) | Afecta |
|---|-----------|----------|--------|
| 1 | 🔴 CRÍTICO | NESTJS-B · RIDEGLORY-D · RIDEGLORY-E | Backend + Flutter |
| 2 | 🔴 CRÍTICO | (sin issue Sentry propio) | Backend + Flutter |
| 3 | 🟡 MEDIO | RIDEGLORY-A · RIDEGLORY-9 | Flutter |
| 4 | 🟡 MEDIO | RIDEGLORY-F · RIDEGLORY-B | Flutter |
| 5 | 🟢 BAJO | RIDEGLORY-8 | Flutter |
| 6 | 🟢 BAJO | RIDEGLORY-7 | Flutter |
| 7 | 🟢 BAJO | RIDEGLORY-C | Flutter |

---

## Bug 1 — 🔴 TypeError: `null` status code en api-gateway (mantenimientos)

**Issues:** [NESTJS-B](https://camilo-agudelo.sentry.io/issues/RIDEGLORY-NESTJS-B) · [RIDEGLORY-D](https://camilo-agudelo.sentry.io/issues/RIDEGLORY-D) · [RIDEGLORY-E](https://camilo-agudelo.sentry.io/issues/RIDEGLORY-E)  
**Ocurrencias:** 11 en backend · 9+2 en Flutter  
**Endpoint:** `GET /api/maintenances/vehicle/:vehicleId`  
**Pantalla Flutter:** `/vehicles/detail`

### Síntoma
El usuario ve un error al cargar los mantenimientos de un vehículo en la pantalla de detalle. El backend lanza un `TypeError: Invalid status code: null` en `RpcCustomExceptionFilter`.

### Cadena causal (confirmada)

```
Flutter (vehicles/detail)
  → GET /api/maintenances/vehicle/:vehicleId
    → api-gateway: MaintenancesController.findByVehicleId
      → validateVehicleOwner(vehicleId, user.id)
        → vehiclesService.send('findOneVehicle', { id: vehicleId })
          → vehicles-ms: VehiclesService.findOne(id)
            ← throw RpcException("Vehicle with id X not found")   ← ❌ string, no objeto
      ← RpcCustomExceptionFilter.catch(exception)
        normalized.status = null  (la excepción es string, no { status, message })
        response.status(null)     ← TypeError: Invalid status code: null
    ← HTTP 500
  ← DioException [bad response] 500
```

### Código problemático

**`vehicles-ms/src/vehicles/vehicles.service.ts:135`** — `findOne` lanza una cadena en lugar de un objeto estructurado:

```typescript
// ❌ ACTUAL — lanza string
throw new RpcException(`Vehicle with id ${id} not found`);

// ✅ CORRECTO — lanza objeto con status
throw new RpcException({
  status: HttpStatus.NOT_FOUND,
  message: `Vehicle with id ${id} not found`,
});
```

El mismo patrón incorrecto existe en `findOne` (línea 135). El método `findByIdOrNull` (línea 142) retorna `null` sin lanzar excepción y es el correcto para uso interno.

### Cuándo se reproduce
Cuando el vehículo fue eliminado (hard delete) y el gateway intenta validar ownership del vehicleId en cache de Flutter. Ver **Bug 2** para la causa raíz del hard delete.

### Fix
1. **`vehicles-ms/vehicles.service.ts`** — cambiar `RpcException(string)` → `RpcException({ status: HttpStatus.NOT_FOUND, message })` en `findOne`.
2. Adicionalmente: `validateVehicleOwner` en `maintenances.controller.ts` debería manejar el 404 con un mensaje claro en lugar de dejar que el filtro global lo procese.

---

## Bug 2 — 🔴 Vehículo eliminado no visible en detalle de inscripción (hard delete vs soft delete)

**Issue Sentry:** No existe issue propio, pero está relacionado con RIDEGLORY-D/E  
**Reportado por el usuario:** ✅ Confirmado  
**Afecta:** `events-ms` + `vehicles-ms`

### Síntoma
Un usuario se inscribe a un evento con su vehículo, luego elimina el vehículo desde el garaje. Al ver el detalle de la inscripción, el campo de vehículo aparece vacío.

### Causa raíz

**El delete de vehículos es un hard delete (eliminación física):**

```typescript
// vehicles-ms/src/vehicles/vehicles.service.ts:185
await tx.vehicle.delete({ where: { id } });  // ← elimina el registro de la DB
```

El servicio de registros construye `vehicleSummary` en tiempo real llamando al `vehicles-ms`:

```typescript
// events-ms registrations.service.ts:424-432
private async buildVehicleSummary<T extends { vehicleId: string | null }>(
  registration: T,
): Promise<T & { vehicleSummary: VehicleSummary | null }> {
  if (!registration.vehicleId) return { ...registration, vehicleSummary: null };
  const vehicle = await this.fetchVehicleById(registration.vehicleId);
  return { ...registration, vehicleSummary: vehicle }; // ← null si fue eliminado
}
```

`fetchVehicleById` retorna `null` cuando el vehículo no existe → `vehicleSummary: null` → Flutter no muestra el nombre.

### Fix — dos partes

**Parte A — `vehicles-ms`: implementar soft delete**

La tabla de mantenimientos ya usa `isDeleted`. Hacer lo mismo en vehículos:

1. Agregar `isDeleted Boolean @default(false)` (y opcionalmente `deletedAt DateTime?`) al modelo `Vehicle` en `prisma/schema.prisma`.
2. Cambiar `remove()` para hacer update en lugar de delete:
   ```typescript
   // vehicles-ms/vehicles.service.ts — remove()
   await tx.vehicle.update({
     where: { id },
     data: { isDeleted: true },
   });
   ```
3. Filtrar `isDeleted: false` en `findByOwnerId`, `findMainVehicleByOwnerId`, `findAll`.
4. **`findByIdOrNull` y `getVehicleById`** (usado por registrations) NO deben filtrar `isDeleted` — deben retornar el vehículo aunque esté marcado como eliminado para que las inscripciones históricas sigan mostrando la info.

**Parte B — `events-ms` (opcional pero robusto)**

Guardar un snapshot del nombre del vehículo en la tabla `EventRegistration` al momento del registro. Esto desacopla el historial del estado del vehículo. No estrictamente necesario si se hace el soft delete correctamente.

---

## Bug 3 — 🟡 Mapbox `PlatformException` en mapa de rutas

**Issues:** [RIDEGLORY-A](https://camilo-agudelo.sentry.io/issues/RIDEGLORY-A) (6 ocurrencias) · [RIDEGLORY-9](https://camilo-agudelo.sentry.io/issues/RIDEGLORY-9) (2 ocurrencias)  
**Pantalla:** `/events/detail` · `/events/registration`  
**Archivos:** `route_map_preview.dart`

### Síntoma
```
PlatformException: Unable to establish connection on channel:
  "dev.flutter.pigeon.mapbox_maps_flutter._PointAnnotationMessenger.deleteAll.0"
PlatformException: Unable to establish connection on channel:
  "dev.flutter.pigeon.mapbox_maps_flutter._PointAnnotationMessenger.create.0"
```

### Causa
El widget del mapa (`_RouteMapPreviewState`) ejecuta operaciones asíncronas sobre el `PointAnnotationManager` (`_renderWaypointMode` → `_updateWaypointAnnotations`) después de que el widget fue disposed. El canal de Pigeon ya no existe cuando se intenta llamar `deleteAll` o `create`.

### Fix
Agregar guard de lifecycle en `route_map_preview.dart` antes de cada operación asíncrona sobre el mapa:

```dart
if (!mounted) return;
await _annotationManager?.deleteAll();
if (!mounted) return;
// ... resto de operaciones
```

Alternativamente, cancelar las operaciones pendientes en `dispose()` usando un `CancelToken` o flag local.

---

## Bug 4 — 🟡 `StateError: Cannot emit after close` (SoatCubit · otro Cubit)

**Issues:** [RIDEGLORY-F](https://camilo-agudelo.sentry.io/issues/RIDEGLORY-F) · [RIDEGLORY-B](https://camilo-agudelo.sentry.io/issues/RIDEGLORY-B)  
**Plataforma:** iOS (iPhone 14, iOS 26.4.2)  
**Archivos:** `soat_cubit.dart:30-32` · `bloc_base.dart:100`

### Síntoma
```
StateError: Bad state: Cannot emit new states after calling close
  at SoatCubit.load (soat_cubit.dart:30)
  at BlocBase.emit (bloc_base.dart:100)
```

### Causa
El cubit es cerrado (widget sale del árbol) mientras una petición HTTP está en vuelo. Cuando la petición retorna, el `fold` del `Either` intenta hacer `emit` pero el cubit ya está cerrado.

### Fix
En `soat_cubit.dart` (y el cubit afectado por RIDEGLORY-B), verificar `isClosed` antes de emitir:

```dart
// soat_cubit.dart
Future<void> load(String vehicleId) async {
  emit(const ResultState.loading());
  final result = await _getSoatByVehicleIdUseCase.execute(vehicleId);
  if (isClosed) return;  // ← guard
  result.fold(
    (error) => emit(ResultState.error(error: error)),
    (data) => emit(data == null ? const ResultState.empty() : ResultState.data(data: data)),
  );
}
```

---

## Bug 5 — 🟢 Apple Sign In cancelado se reporta como error

**Issue:** [RIDEGLORY-8](https://camilo-agudelo.sentry.io/issues/RIDEGLORY-8) (3 ocurrencias)

### Síntoma
```
SignInWithAppleAuthorizationException(AuthorizationErrorCode.canceled,
  The operation couldn't be completed. (com.apple.AuthenticationServices.AuthorizationError error 1001.))
```

### Causa
Error 1001 es cancelación explícita por el usuario (`AuthorizationErrorCode.canceled`). No es un crash — el usuario simplemente tocó "Cancelar" en el diálogo de Apple ID. Se está reportando a Sentry como error.

### Fix
En `rest_client_functions.dart` dentro de `handlerExceptionHttpTestable`, filtrar las excepciones de tipo `SignInWithAppleAuthorizationException` con `code == AuthorizationErrorCode.canceled` antes de reportarlas:

```dart
if (e is SignInWithAppleAuthorizationException &&
    e.code == AuthorizationErrorCode.canceled) {
  return Left(DomainException(...)); // manejar silenciosamente
}
```

---

## Bug 6 — 🟢 `syscall` — error de bajo nivel sin detalles

**Issue:** [RIDEGLORY-7](https://camilo-agudelo.sentry.io/issues/RIDEGLORY-7) (4 ocurrencias, primeras 16 h atrás)

### Descripción
Error genérico de sistema operativo sin stacktrace de primera parte. Suele ocurrir por problemas de red (socket cerrado abruptamente, timeout de TCP). Relacionado posiblemente con la inestabilidad del servidor en ese período.

### Acción
Monitorear. Si sigue ocurriendo después de resolver Bug 1, investigar si coincide temporalmente con timeouts del servidor.

---

## Bug 7 — 🟢 `Connection closed before full header was received` (mantenimientos)

**Issue:** [RIDEGLORY-C](https://camilo-agudelo.sentry.io/issues/RIDEGLORY-C) (1 ocurrencia)  
**URL:** `http://13.222.116.14:3000/api/maintenances/vehicle/:vehicleId`

### Descripción
El servidor cerró la conexión TCP antes de enviar los headers HTTP. Muy probablemente ocurrió mientras el servidor estaba en un estado de error (relacionado con Bug 1) o durante un restart del contenedor.

### Acción
Probable consecuencia secundaria de Bug 1. Resolver Bug 1 y monitorear.

---

## Plan de acción priorizado

| Prioridad | Bug | Repo | Complejidad |
|-----------|-----|------|-------------|
| 1 | Bug 1 — `RpcException` string en vehicles-ms | `vehicles-ms` | Baja (1 línea) |
| 2 | Bug 2A — Soft delete de vehículos | `vehicles-ms` | Media (migración Prisma + lógica) |
| 3 | Bug 4 — `isClosed` guard en cubits | `rideglory` | Baja |
| 4 | Bug 3 — `mounted` guard en Mapbox | `rideglory` | Baja |
| 5 | Bug 5 — Filtrar cancelación Apple Sign In | `rideglory` | Baja |
| 6 | Bug 2B — Snapshot vehicleName en registro | `events-ms` | Alta (migración + lógica) |

> Bug 1 y Bug 2 están relacionados: el hard delete de vehículos causa que `findOneVehicle` lance la excepción mal formada, lo que a su vez produce el TypeError 500. Resolverlos juntos elimina la mayoría de los eventos activos en Sentry.
