# PRD Normalizado — Fase 1: Backend soft-delete e integridad de datos

_Generated: 2026-06-16T18:27:35Z_
_Source: docs/plans/archive-vehicle-soft-delete/phases/phase-01-backend-soft-delete-e-integridad-de-datos.md_

---

## 1 Objetivo

Implementar soft-delete de vehículos en el backend (vehicles-ms + api-gateway) para que el usuario pueda eliminar permanentemente un vehículo desde la UI sin perder el historial de inscripciones ni mantenimientos. El endpoint `DELETE /api/vehicles/my/:vehicleId` autentica via Firebase, verifica ownership en el token (no en el body), encadena soft-delete de mantenimientos antes de marcar el vehículo como eliminado, y promueve automáticamente el siguiente vehículo activo como main si el eliminado lo era. Los filtros de listado de garaje excluyen vehículos eliminados y archivados; la búsqueda por `id` directo (usada por events-ms para snapshots históricos) permanece sin filtros.

---

## 2 Por qué

El flujo actual de eliminación (`DELETE /api/vehicles/hard-delete/:id`) borra la fila físicamente, destruyendo el historial de inscripciones a eventos y registros de mantenimiento asociados al vehículo. El soft-delete resuelve este problema marcando la fila como eliminada en lugar de borrarla, preservando la integridad referencial de los datos históricos mientras el garaje del usuario queda limpio. Sin esta base de datos backend, la Fase 4 (Flutter: eliminación desde el garaje) no puede implementarse de forma segura.

---

## 3 Alcance

### Entra

- Campo `isDeleted Boolean @default(false)` en el schema Prisma de vehicles-ms con su migración SQL (`add_soft_delete_to_vehicle`).
- Método `softDeleteVehicle(vehicleId, ownerId)` en `VehiclesService` (vehicles-ms): verifica ownership, ejecuta transacción soft-delete + promoción de main al siguiente activo por `createdAt desc`.
- `@MessagePattern('softDeleteVehicle')` en `VehiclesController` (vehicles-ms).
- Filtros `isDeleted: false, isArchived: false` en `findByOwnerId` y `findMainVehicleByOwnerId` (vehicles-ms).
- Corrección de bug en `create()` (vehicles-ms): conteo de vehículos existentes excluye `isArchived: true` e `isDeleted: true`.
- Nuevo endpoint `DELETE /api/vehicles/my/:vehicleId` en api-gateway: autenticado, encadena `softDeleteMaintenancesByVehicleId` (maintenances-ms, timeout 15s) → `softDeleteVehicle` (vehicles-ms).
- Mantener `DELETE /api/vehicles/hard-delete/:id` sin cambios como alias temporal hasta que Fase 4 Flutter esté en producción.
- Tests unitarios Jest en vehicles-ms cubriendo ownership, promoción de main, y filtros.
- Ejecución local de `prisma migrate dev` y verificación del SQL antes de cualquier despliegue.

### No entra

- Cambios en Flutter (`lib/`), `app_es.arb`, ni diseño en Pencil (Fases 2, 3 y 4).
- Filtrar `isDeleted` en `findByIdOrNull` — prohibido para no romper snapshots históricos de events-ms.
- Eliminar el endpoint `hard-delete/:id` (se hace en Fase 4 post-producción).
- Exponer `isDeleted` en la respuesta HTTP de `GET /api/vehicles/my` — campo interno al backend.
- Cambios en rideglory-contracts (no se necesita ningún DTO nuevo).

---

## 4 Áreas afectadas

| Repositorio / Servicio | Archivos principales |
|------------------------|---------------------|
| `rideglory-api/vehicles-ms` | `prisma/schema.prisma`, `prisma/migrations/<ts>_add_soft_delete_to_vehicle/migration.sql`, `src/vehicles/vehicles.service.ts`, `src/vehicles/vehicles.controller.ts` |
| `rideglory-api/api-gateway` | `src/vehicles/vehicles.controller.ts` |
| `rideglory-api/vehicles-ms` (tests) | `src/vehicles/vehicles.service.spec.ts` (crear si no existe) |
| Flutter (`Rideglory`) | Sin cambios en esta fase |
| rideglory-contracts | Sin cambios en esta fase |

---

## 5 Criterios de aceptación

1. `GET /api/vehicles/my` (con token válido) no retorna ningún vehículo con `isDeleted: true` ni con `isArchived: true`.
2. `DELETE /api/vehicles/my/:vehicleId` con token del owner retorna `200 { message: "Vehicle deleted successfully", status: 200 }` y no borra la fila de la tabla (verificable con Prisma Studio o `psql`: la fila existe con `isDeleted: true`).
3. `DELETE /api/vehicles/my/:vehicleId` con token de un usuario distinto al owner retorna `403`.
4. `DELETE /api/vehicles/my/:vehicleId` con un UUID inexistente retorna `404`.
5. Si el vehículo eliminado tenía `isMainVehicle: true`, el backend promueve el siguiente vehículo activo (`isArchived: false, isDeleted: false`) ordenado por `createdAt desc` como nuevo `isMainVehicle: true`. Si no existe ninguno, ningún vehículo queda como main.
6. Si el vehículo eliminado NO era main, ningún otro vehículo cambia su `isMainVehicle`.
7. `findByIdOrNull` (MessagePattern `'getVehicleById'`) sigue retornando el vehículo aunque tenga `isDeleted: true` — los snapshots históricos de events-ms permanecen accesibles.
8. Crear un vehículo nuevo cuando el único vehículo existente del owner está archivado o eliminado lo marca como `isMainVehicle: true` (bug de conteo corregido).
9. `findMainVehicleByOwnerId` no retorna un vehículo con `isArchived: true` ni `isDeleted: true`.
10. `prisma migrate dev` genera SQL estrictamente aditivo (`ALTER TABLE "Vehicle" ADD COLUMN "isDeleted" BOOLEAN NOT NULL DEFAULT false`) sin sentencias DROP ni modificaciones destructivas, y aplica limpiamente en base de datos local.
11. `dart analyze` y `flutter test` pasan en verde (sin cambios Flutter en esta fase).
12. TypeScript compila sin errores en vehicles-ms y api-gateway tras los cambios.

---

## 6 Guardrails de regresión

- **`findByIdOrNull` no filtra `isDeleted`**: verificar en code review que el método `findByIdOrNull` / MessagePattern `'getVehicleById'` NO recibe `isDeleted: false` en el `where`. Un error aquí rompe silenciosamente los snapshots de events-ms.
- **Ownership check obligatorio**: el service verifica `existing.ownerId !== ownerId` antes de ejecutar la transacción. Ningún usuario autenticado puede eliminar un vehículo ajeno.
- **Orden de rutas en api-gateway**: `@Delete('my/:vehicleId')` debe declararse **antes** de `@Delete(':id')` y antes de handlers `soat`/`tecnomecanica` para que NestJS no interprete "my" como un UUID o param genérico.
- **`hard-delete/:id` intacto**: no modificar ni eliminar el endpoint existente en esta fase. Es el fallback hasta que Fase 4 esté en producción.
- **Migración no destructiva**: el SQL generado debe contener únicamente `ALTER TABLE "Vehicle" ADD COLUMN`. Rechazar si contiene DROP, RENAME o modificaciones de tipo.
- **No exponer `isDeleted` al cliente**: la respuesta de `GET /api/vehicles/my` no debe incluir el campo `isDeleted`; es interno al backend.
- **Criterio de promoción de main canónico**: `findFirst({ where: { ownerId, isArchived: false, isDeleted: false }, orderBy: { createdAt: 'desc' } })`. Documentar para que Fase 3 Flutter lo replique exactamente.

---

## 7 Constraints heredados

- **Autenticación via Firebase**: ownership se deriva de `getAuthenticatedUser(request).id`; nunca del body del request.
- **Patrón microservicio**: vehicles-ms y maintenances-ms se comunican via `ClientProxy` con `MessagePattern`; api-gateway orquesta y propaga errores como `RpcException`.
- **Timeout 15s en maintenances-ms**: alineado con el timeout del pattern `hardDelete` existente. Si maintenances-ms falla (502), el vehículo no se soft-delete — consistencia conservada.
- **No commitear**: el árbol de trabajo queda sucio a propósito; el humano revisa y commitea.
- **Migrations locales primero**: ejecutar `prisma migrate dev` localmente y verificar con el humano antes de cualquier despliegue a entornos remotos.
- **rideglory-contracts**: no requiere build en esta fase porque no se añaden DTOs nuevos.
- **Flutter sin cambios**: ningún archivo bajo `lib/`, `app_es.arb`, ni tests Flutter se modifican en esta fase.
