# Fase 1 — Backend: soft-delete e integridad de datos

_Generated: 2026-06-16T16:23:59Z_

---

## Objetivo

El usuario puede eliminar permanentemente un vehículo sin perder el historial de inscripciones ni mantenimientos. El endpoint de eliminación es autenticado, verifica ownership en el token Firebase (no requiere pasar `ownerId` en el body), y delega el soft-delete de mantenimientos antes de marcar el vehículo como eliminado. Los filtros de listado excluyen vehículos eliminados y archivados de la vista del garaje; la búsqueda por `id` directo (usada por events-ms para snapshots históricos) permanece sin filtros.

---

## Alcance (entra / no entra)

### Entra

- Nuevo campo `isDeleted Boolean @default(false)` en el schema Prisma de vehicles-ms, con su migración SQL correspondiente.
- Nuevo método `softDeleteVehicle({ vehicleId, ownerId })` en `VehiclesService` (vehicles-ms): verifica ownership, ejecuta transacción que marca `isDeleted: true`, encadena promoción de main al siguiente activo no archivado por `createdAt desc`.
- Nuevo `@MessagePattern('softDeleteVehicle')` en `VehiclesController` (vehicles-ms).
- Filtros `isDeleted: false` y `isArchived: false` en `findByOwnerId` (vehicles-ms).
- Filtro `isArchived: false` en `findMainVehicleByOwnerId` (vehicles-ms) — no agrega `isDeleted` porque un vehículo eliminado ya no debería ser main, pero el filtro explícito de isDeleted es defensivo y se incluye.
- Corrección del bug en `create()` (vehicles-ms): el conteo que decide si el primer vehículo es main excluye `isArchived: true` y `isDeleted: true`.
- Nuevo endpoint `DELETE /api/vehicles/my/:vehicleId` en api-gateway: autenticado via `getAuthenticatedUser`, llama `softDeleteMaintenancesByVehicleId` en maintenances-ms (timeout 15s), luego `softDeleteVehicle` en vehicles-ms con `{ vehicleId, ownerId: user.id }`.
- Mantener `DELETE /api/vehicles/hard-delete/:id` sin cambios como alias temporal hasta confirmar que Fase 4 Flutter está en producción.
- `findByIdOrNull` (vehicles-ms) permanece sin cambios — no recibe filtro `isDeleted`.
- Ejecución local de `prisma migrate dev` y verificación del SQL antes de cualquier despliegue.
- Build de rideglory-contracts si se añade algún DTO (ver sección de contratos — en este caso no se necesita ninguno nuevo).

### No entra

- Cambios en Flutter (ningún archivo bajo `lib/`).
- Cambios en claves `app_es.arb` (Fases 3 y 4).
- Diseño en Pencil (Fase 2).
- Eliminación del endpoint `hard-delete/:id` (se hace cuando Fase 4 esté en producción).
- Filtrar `isDeleted` en `findByIdOrNull` — prohibido para no romper snapshots históricos de events-ms.
- Exponer `isDeleted` en la respuesta HTTP de `GET /api/vehicles/my` — el campo es interno al backend.

---

## Que se debe hacer (pasos concretos y ordenados)

### 1. Añadir `isDeleted` al schema Prisma (vehicles-ms)

Editar `vehicles-ms/prisma/schema.prisma`: añadir `isDeleted Boolean @default(false)` al model `Vehicle`, inmediatamente después de `isMainVehicle`.

### 2. Generar la migración SQL

Dentro de `vehicles-ms/`, ejecutar:

```bash
npx prisma migrate dev --name add_soft_delete_to_vehicle
```

Revisar el SQL generado en `prisma/migrations/<timestamp>_add_soft_delete_to_vehicle/migration.sql`. Debe ser únicamente:

```sql
ALTER TABLE "Vehicle" ADD COLUMN "isDeleted" BOOLEAN NOT NULL DEFAULT false;
```

Confirmar que no hay sentencias DROP ni modificaciones destructivas.

### 3. Corregir filtros en `findByOwnerId` (vehicles-ms)

En `VehiclesService.findByOwnerId`: cambiar el `where` para excluir archivados y eliminados:

```typescript
where: { ownerId, isArchived: false, isDeleted: false },
```

El `orderBy: { createdAt: 'desc' }` se mantiene.

### 4. Corregir filtro en `findMainVehicleByOwnerId` (vehicles-ms)

En `VehiclesService.findMainVehicleByOwnerId`: añadir `isArchived: false, isDeleted: false` al `where`:

```typescript
where: { ownerId, isMainVehicle: true, isArchived: false, isDeleted: false },
```

### 5. Corregir bug de conteo en `create()` (vehicles-ms)

En `VehiclesService.create()`, la línea actual es:

```typescript
const existingCount = await this.vehicle.count({
  where: { ownerId: createVehicleDto.ownerId },
});
```

Cambiar a:

```typescript
const existingCount = await this.vehicle.count({
  where: {
    ownerId: createVehicleDto.ownerId,
    isArchived: false,
    isDeleted: false,
  },
});
```

Esto garantiza que un nuevo vehículo no quede huérfano de `isMainVehicle: true` si el único vehículo existente estaba archivado o eliminado.

### 6. Implementar `softDeleteVehicle` en `VehiclesService` (vehicles-ms)

Añadir método nuevo (no modificar `remove()`):

```typescript
async softDeleteVehicle(vehicleId: string, ownerId: string) {
  const existing = await this.vehicle.findUnique({
    where: { id: vehicleId },
  });

  if (!existing) {
    throw new RpcException({
      status: HttpStatus.NOT_FOUND,
      message: `Vehicle with id ${vehicleId} not found`,
    });
  }

  if (existing.ownerId !== ownerId) {
    throw new RpcException({
      status: HttpStatus.FORBIDDEN,
      message: 'Vehicle does not belong to the authenticated user',
    });
  }

  const wasMain = existing.isMainVehicle;

  return this.$transaction(async (tx) => {
    await tx.vehicle.update({
      where: { id: vehicleId },
      data: { isDeleted: true, isMainVehicle: false },
    });

    if (wasMain) {
      const next = await tx.vehicle.findFirst({
        where: { ownerId, isArchived: false, isDeleted: false },
        orderBy: { createdAt: 'desc' },
      });

      if (next) {
        await tx.vehicle.update({
          where: { id: next.id },
          data: { isMainVehicle: true },
        });
      }
    }

    return { message: 'Vehicle soft-deleted successfully', vehicleId };
  });
}
```

Criterio de promoción de main: `findFirst({ where: { ownerId, isArchived: false, isDeleted: false }, orderBy: { createdAt: 'desc' } })`. Este criterio es el canónico que Flutter replicará en Fase 3.

### 7. Registrar `softDeleteVehicle` como MessagePattern (vehicles-ms)

En `VehiclesController` (vehicles-ms), añadir:

```typescript
@MessagePattern('softDeleteVehicle')
softDelete(@Payload() payload: { vehicleId: string; ownerId: string }) {
  return this.vehiclesService.softDeleteVehicle(payload.vehicleId, payload.ownerId);
}
```

### 8. Crear el nuevo endpoint en api-gateway

En `VehiclesController` (api-gateway), añadir el handler `DELETE my/:vehicleId` antes de los handlers de SOAT/RTM (mantener `hard-delete/:id` intacto):

```typescript
@Delete('my/:vehicleId')
async softDeleteMyVehicle(
  @Req() request: AuthenticatedRequest,
  @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
) {
  const user = await this.getAuthenticatedUser(request);

  await firstValueFrom(
    this.maintenancesService
      .send('softDeleteMaintenancesByVehicleId', { vehicleId })
      .pipe(
        timeout(15_000),
        catchError((error) => {
          throw new RpcException({
            message:
              error?.message ??
              'Failed to soft-delete vehicle maintenances before deletion',
            status: HttpStatus.BAD_GATEWAY,
          });
        }),
      ),
  );

  await firstValueFrom(
    this.vehiclesService
      .send('softDeleteVehicle', { vehicleId, ownerId: user.id })
      .pipe(
        catchError((error) => {
          throw new RpcException({
            message: error.message,
            status: error?.status ?? HttpStatus.NOT_FOUND,
          });
        }),
      ),
  );

  return {
    message: 'Vehicle deleted successfully',
    status: HttpStatus.OK,
  };
}
```

Verificar que `@Delete('my/:vehicleId')` está declarado **antes** de `@Delete(':id')` y `@Delete(':vehicleId/soat')` / `@Delete(':vehicleId/tecnomecanica')` para que NestJS no interprete "my" como un UUID. La ruta `my/:vehicleId` no pasa `ParseUUIDPipe` en el segmento "my" — solo en `vehicleId`. Si hay conflicto de orden de rutas con `hard-delete/:id`, asegurarse de que `my/:vehicleId` esté declarado antes.

### 9. Ejecutar `prisma generate` y compilar vehicles-ms

```bash
cd vehicles-ms && npx prisma generate && npm run build
```

Confirmar que TypeScript compila sin errores con el nuevo campo `isDeleted` disponible en el tipo generado.

### 10. Verificar migración localmente

```bash
cd vehicles-ms && npx prisma migrate dev
```

Confirmar con `psql` o Prisma Studio que la columna existe y que filas existentes tienen `isDeleted = false`.

### 11. Tests unitarios en vehicles-ms

Ver sección "Pruebas" más abajo.

---

## Archivos a crear/modificar (rutas reales)

### rideglory-api/vehicles-ms

| Ruta | Acción | Qué cambia |
|------|--------|------------|
| `prisma/schema.prisma` | Modificar | Añadir `isDeleted Boolean @default(false)` al model `Vehicle` |
| `prisma/migrations/<timestamp>_add_soft_delete_to_vehicle/migration.sql` | Crear (auto por prisma) | `ALTER TABLE "Vehicle" ADD COLUMN "isDeleted" BOOLEAN NOT NULL DEFAULT false` |
| `src/vehicles/vehicles.service.ts` | Modificar | (1) `findByOwnerId`: añadir `isArchived: false, isDeleted: false` al where. (2) `findMainVehicleByOwnerId`: añadir `isArchived: false, isDeleted: false` al where. (3) `create()`: conteo con `isArchived: false, isDeleted: false`. (4) Nuevo método `softDeleteVehicle(vehicleId, ownerId)` con transacción soft-delete + promoción de main. |
| `src/vehicles/vehicles.controller.ts` | Modificar | Nuevo `@MessagePattern('softDeleteVehicle')` que delega a `vehiclesService.softDeleteVehicle()` |

### rideglory-api/api-gateway

| Ruta | Acción | Qué cambia |
|------|--------|------------|
| `src/vehicles/vehicles.controller.ts` | Modificar | Nuevo handler `@Delete('my/:vehicleId')` autenticado: encadena `softDeleteMaintenancesByVehicleId` (maintenances-ms) → `softDeleteVehicle` (vehicles-ms). Mantener `@Delete('hard-delete/:id')` sin cambios. |

### rideglory-contracts

No se requieren cambios. El nuevo endpoint `DELETE /api/vehicles/my/:vehicleId` no necesita DTO de request (solo el `vehicleId` en la URL y el token Bearer). El campo `isDeleted` es interno al backend y no viaja al cliente Flutter.

---

## Contratos / API rideglory-api

### Nuevo endpoint

```
DELETE /api/vehicles/my/:vehicleId
Auth:    Bearer <Firebase ID token>
Params:  vehicleId (UUID) — vía URL
Body:    ninguno
Success: 200 { message: "Vehicle deleted successfully", status: 200 }
Errors:
  401 — token inválido o ausente (FirebaseAuthGuard)
  400 — vehicleId no es UUID válido (ParseUUIDPipe)
  403 — el vehículo no pertenece al usuario autenticado
  404 — vehículo no encontrado
  502 — timeout o error de maintenances-ms al soft-delete mantenimientos
```

### Endpoint existente preservado

```
DELETE /api/vehicles/hard-delete/:id
```

Se mantiene sin cambios como alias temporal. El MS subyacente (`hardDeleteVehicle`) sigue ejecutando hard-delete físico. Se eliminará una vez que Fase 4 Flutter esté confirmada en producción.

### Cambio de comportamiento interno (sin cambio de firma HTTP)

```
GET /api/vehicles/my
```

La firma HTTP no cambia. La respuesta ahora excluye vehículos con `isArchived: true` OR `isDeleted: true`. Los clientes Flutter existentes no requieren ningún cambio para consumirlo.

### MessagePattern nuevo (interno, vehicles-ms ↔ api-gateway)

```typescript
// Pattern: 'softDeleteVehicle'
// Payload: { vehicleId: string, ownerId: string }
// Returns: { message: string, vehicleId: string }
// Errors:  RpcException 404 (not found) | 403 (not owner)
```

---

## Cambios de datos / migraciones

### Migración: `add_soft_delete_to_vehicle`

**Tipo:** No destructiva. `ALTER TABLE "Vehicle" ADD COLUMN "isDeleted" BOOLEAN NOT NULL DEFAULT false`.

- Todas las filas existentes arrancan con `isDeleted = false`. No se modifica ningún dato existente.
- La columna no es nullable (`NOT NULL DEFAULT false`): no hay riesgo de NPE en código TypeScript si se omite en `findMany` sin `select` parcial.
- Ejecutar localmente con `prisma migrate dev` para generar el SQL. Revisar el archivo SQL antes de hacer `migrate deploy` en producción.
- Desplegar en ventana de bajo tráfico. La operación es un simple `ALTER TABLE ADD COLUMN` — en PostgreSQL moderno es casi instantánea para tablas sin millones de filas.

**Rollback:** `ALTER TABLE "Vehicle" DROP COLUMN "isDeleted"`. Solo es necesario si hay un bug crítico; los datos no se pierden (los vehículos soft-deleted están marcados, no borrados).

---

## Criterios de aceptacion

1. `GET /api/vehicles/my` (con token válido) no retorna ningún vehículo con `isDeleted: true` ni con `isArchived: true`.
2. `DELETE /api/vehicles/my/:vehicleId` con token del owner retorna `200 { message: "Vehicle deleted successfully", status: 200 }` y no borra la fila de la tabla (verificable con `prisma studio` o `findUnique` vía Prisma: la fila existe con `isDeleted: true`).
3. `DELETE /api/vehicles/my/:vehicleId` con token de un usuario distinto al owner retorna `403`.
4. `DELETE /api/vehicles/my/:vehicleId` con un UUID inexistente retorna `404`.
5. Si el vehículo eliminado tenía `isMainVehicle: true`, el backend promueve el siguiente vehículo activo (`isArchived: false, isDeleted: false`) ordenado por `createdAt desc` como nuevo `isMainVehicle: true`. Si no existe ninguno, ningún vehículo queda como main.
6. Si el vehículo eliminado NO era main, ningún otro vehículo cambia su `isMainVehicle`.
7. `findByIdOrNull` (MessagePattern `'getVehicleById'`) sigue retornando el vehículo aunque tenga `isDeleted: true` — los snapshots históricos de events-ms permanecen accesibles.
8. Crear un vehículo nuevo cuando el único vehículo existente del owner está archivado o eliminado lo marca como `isMainVehicle: true` (bug del conteo corregido).
9. `findMainVehicleByOwnerId` no retorna un vehículo con `isArchived: true` ni `isDeleted: true`.
10. `prisma migrate dev` genera SQL no destructivo y la migración aplica limpiamente en base de datos local (verificado antes de despliegue).
11. `dart analyze` y `flutter test` pasan en verde (sin cambios Flutter en esta fase).
12. TypeScript compila sin errores en vehicles-ms y api-gateway tras los cambios.

---

## Pruebas (unitarias/widget/integracion)

### vehicles-ms — Tests unitarios (Jest)

Ubicación recomendada: `vehicles-ms/src/vehicles/vehicles.service.spec.ts` (crear si no existe).

**Casos a cubrir:**

| Test | Descripción |
|------|-------------|
| `softDeleteVehicle — owner correcto` | Dado un vehículo existente cuyo `ownerId` coincide con el `ownerId` del payload, el método actualiza `isDeleted: true` y devuelve el objeto de respuesta. Verificar con mock de Prisma que NO se llama `vehicle.delete()`. |
| `softDeleteVehicle — vehículo no encontrado` | `findUnique` retorna `null` → lanza `RpcException` con status 404. |
| `softDeleteVehicle — ownership incorrecto` | `findUnique` retorna vehículo con `ownerId` distinto → lanza `RpcException` con status 403. |
| `softDeleteVehicle — era main, existe sucesor` | Dado vehículo main con otro vehículo activo (`isArchived: false, isDeleted: false`), tras el soft-delete el sucesor recibe `isMainVehicle: true`. Verificar criterio `orderBy: { createdAt: 'desc' }`. |
| `softDeleteVehicle — era main, sin sucesor` | Dado vehículo main sin otros activos, tras el soft-delete ningún vehículo recibe `isMainVehicle: true`. |
| `findByOwnerId — excluye archivados y eliminados` | El `where` incluye `isArchived: false, isDeleted: false`. Mock de `findMany` captura el `where` y verifica los filtros. |
| `findMainVehicleByOwnerId — excluye archivados y eliminados` | Ídem para `findFirst` con `isMainVehicle: true`. |
| `create — conteo excluye archivados y eliminados` | Mock de `vehicle.count` captura el `where` y verifica `isArchived: false, isDeleted: false`. |

### api-gateway — Tests de integración (Jest + supertest, opcional para esta fase)

Si el proyecto tiene suite e2e en api-gateway, añadir:

- `DELETE /api/vehicles/my/:vehicleId` con token válido → 200 (mock de vehicles-ms retorna éxito, mock de maintenances-ms retorna éxito).
- `DELETE /api/vehicles/my/:vehicleId` con token inválido → 401.
- `DELETE /api/vehicles/my/:vehicleId` cuando vehicles-ms retorna RpcException 403 → el gateway relanza el error apropiado.

### Verificación manual mínima

1. Crear un vehículo con `POST /api/vehicles/my`.
2. Llamar `DELETE /api/vehicles/my/:vehicleId`.
3. Llamar `GET /api/vehicles/my` — verificar que el vehículo ya no aparece.
4. Consultar la base de datos directamente (`prisma studio` o `psql`) — verificar que la fila existe con `isDeleted = true`.
5. Si el vehículo era main y había otro activo, verificar que ese otro tiene `isMainVehicle = true`.

---

## Riesgos y mitigaciones

| # | Riesgo | Prob. | Impacto | Mitigación |
|---|--------|-------|---------|------------|
| R-1 | **Migración en producción con filas existentes**: `ALTER TABLE ADD COLUMN` puede bloquear brevemente en PostgreSQL con lock `ACCESS EXCLUSIVE` | Baja | Alto | Ejecutar en ventana de bajo tráfico. Confirmar que la operación no requiere rewrite de tabla (columna NOT NULL con DEFAULT es segura en PostgreSQL 11+). Revisar el SQL generado antes de `migrate deploy`. |
| R-2 | **`isDeleted` filtra `findByIdOrNull` por error**: un developer añade el filtro al método equivocado y rompe snapshots históricos de events-ms | Baja | Alto | Documentado explícitamente en este archivo: `findByIdOrNull` NO recibe filtro `isDeleted`. Revisar en code review. |
| R-3 | **Orden de rutas en api-gateway**: `DELETE my/:vehicleId` puede ser capturado por un handler de `:id` o `:vehicleId/soat` si el orden de declaración es incorrecto | Media | Medio | Declarar `@Delete('my/:vehicleId')` antes de `@Delete(':id')` (si existe) y antes de los handlers de SOAT/RTM. Verificar con `curl` o Postman que la ruta resuelve correctamente. |
| R-4 | **Despliegue descoordinado Flutter/backend**: Flutter sigue apuntando a `/api/vehicles/hard-delete/{id}` (Retrofit actual) | Media | Alto | Mantener `hard-delete/:id` operativo hasta que Fase 4 Flutter esté confirmada en producción (gate explícito en Fase 4). No eliminar el alias en esta fase. |
| R-5 | **Promoción de main diverge entre backend y Flutter**: Flutter en Fases 3/4 debe usar exactamente el mismo criterio (`createdAt desc`) | Media | Medio | Este archivo documenta el criterio canónico. El implementador de Fase 3 debe replicar `findFirst({ orderBy: { createdAt: 'desc' }, where: { isArchived: false, isDeleted: false } })` en el cubit local (con tie-break por `id` asc para nulls). |
| R-6 | **`softDeleteMaintenancesByVehicleId` timeout en maintenances-ms**: la cadena falla y el vehículo queda sin soft-delete | Baja | Medio | Timeout de 15s alineado con el pattern existente en `hardDelete`. Si falla, el api-gateway retorna 502 y el cliente puede reintentar. Los mantenimientos no son soft-deleted hasta que el vehículo lo sea — consistencia conservada. |

---

## Dependencias (fases prerequisito y por que)

**Esta fase no tiene prerequisitos.** Es la primera en el plan y puede ejecutarse de forma independiente desde el inicio.

**Esta fase bloquea:**
- **Fase 4** (Flutter: eliminación permanente desde archivados): requiere que `DELETE /api/vehicles/my/:vehicleId` esté desplegado y respondiendo en el entorno de prueba antes de que Flutter implemente el consumo del endpoint. El gate de entrada de Fase 4 es explícito: confirmar el endpoint disponible antes de iniciar.

**Fases independientes de esta fase:**
- Fase 2 (Diseño Pencil) puede ejecutarse en paralelo con Fase 1.
- Fase 3 (Flutter archivar/restaurar) no depende de esta fase — usa `PATCH /api/vehicles/:id` existente.
- Fase 5 (Flutter home coherente) es completamente independiente.

---

## Ejecucion recomendada (nivel rg-exec: full)

**Nivel: full**

**Por que ese nivel:** Esta fase combina tres fuentes de riesgo que individualmente ya justificarían `normal`, y en conjunto requieren auditor Opus iterativo (`full`):

1. **Migración de datos en producción** (`isDeleted`): aunque el SQL es no destructivo, un error en el schema Prisma o en el archivo de migración puede dejar la base de datos en estado inconsistente o requerir intervención manual. El auditor debe verificar el SQL generado antes de aprobar.

2. **Nuevo endpoint autenticado con verificación de ownership** (`DELETE /api/vehicles/my/:vehicleId`): la lógica de ownership se implementa manualmente comparando `existing.ownerId !== ownerId` dentro del service, sin un guard declarativo. Un error aquí permite a cualquier usuario autenticado eliminar vehículos de otros. El auditor debe revisar el flujo completo: `getAuthenticatedUser` → `user.id` → payload → `softDeleteVehicle` → verificación de ownership.

3. **Cambio de contrato en rideglory-api (vehicles-ms + api-gateway)**: los filtros en `findByOwnerId` y `findMainVehicleByOwnerId` cambian el comportamiento observable de `GET /api/vehicles/my`. Si `isDeleted` filtra un método que no debía filtrar (p.ej. `findByIdOrNull`), los snapshots históricos de events-ms se rompen silenciosamente — difícil de detectar sin cobertura de tests.

4. **Blast radius alto**: un filtro mal aplicado hace que el garaje muestre vehículos fantasma (si no filtra) o pierda vehículos activos (si filtra de más). La promoción de main incorrecta deja al usuario sin vehículo principal en home. Ambos escenarios son difíciles de revertir sin una migración inversa que restaure `isDeleted = false`.

El implementador (Sonnet) escribe los cambios; el auditor (Opus) verifica en cada iteración: (a) que el SQL de migración es estrictamente aditivo, (b) que `findByIdOrNull` no recibe filtros, (c) que el ownership check es correcto, (d) que el orden de rutas en api-gateway no introduce conflictos, y (e) que los tests cubren los casos de ownership y promoción de main.
