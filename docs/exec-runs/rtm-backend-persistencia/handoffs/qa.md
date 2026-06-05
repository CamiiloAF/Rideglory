# QA Handoff — rtm-backend-persistencia
Generated: 2026-06-04T17:47:22Z

---

## Catalogo

Mapa de cada AC §5 contra su cobertura de test.

| AC | Descripción | Test / Mecanismo | Estado |
|----|-------------|-----------------|--------|
| 1 | `model Tecnomecanica` en schema con campos correctos | Inspección de `schema.prisma`: todos los campos presentes (`vehicleId @unique`, `certificateNumber`, `cdaName`, `cdaCode?`, `startDate?`, `expiryDate`, `documentUrl?`, `createdAt`, `updatedAt`). `model Soat` byte-idéntico. | ✅ PASS |
| 2 | Migración crea `Tecnomecanica` sin alterar `Soat` | SQL de `20260604173849_add_tecnomecanica/migration.sql` solo contiene `CREATE TABLE "Tecnomecanica"` y `CREATE UNIQUE INDEX`. Sin DDL sobre `Soat`. | ✅ PASS |
| 3 | Rutas REST protegidas por Firebase Auth | `FirebaseAuthGuard` registrado como `APP_GUARD` global en `auth.module.ts` (`provide: APP_GUARD`). Las 3 rutas RTM heredan la protección automáticamente sin anotaciones adicionales. | ✅ PASS |
| 4 | `validateVehicleOwnership` en upsert/find/delete | Presente en las 3 operaciones del service. Tests de simulación cubren owner-coincide y no-coincide en los 3 casos. | ✅ PASS |
| 5 | `400` cuando `expiryDate <= startDate` | Tests: "rejects when expiryDate equals startDate" + "rejects when expiryDate is before startDate" → 18/18 verde. | ✅ PASS |
| 5b | Acepta body sin `startDate` | Test: "accepts when startDate is absent (optional field)" → pasa. `@IsOptional()` en DTO. | ✅ PASS |
| 6 | `GET /tecnomecanica` → 404 cuando no existe RTM | Gateway: `if (!rtm) { throw new NotFoundException(...) }`. Correcto — diferencia deliberada con SOAT (que retorna `null`). | ✅ PASS |
| 7 | `DELETE /tecnomecanica` → 404 si no existe; `{ success: true }` si borra | Service verifica existencia antes de borrar; test "returns 404 when no RTM exists" + "returns { success: true }..." → pasa. | ✅ PASS |
| 8 | DTO rechaza sin `certificateNumber`, `cdaName` o `expiryDate`; acepta sin `startDate`/`cdaCode`/`documentUrl` | `class-validator` decoradores: `@IsNotEmpty()` en los 3 required; `@IsOptional()` en los 3 opcionales. Idéntico en `api-gateway` y `vehicles-ms`. | ✅ PASS (validación de runtime class-validator; gap: sin test e2e de DTO rejection) |
| 9 | `findTecnomecanicasExpiringIn` usa ventana UTC día-exacto | 5 tests de ventana temporal cubren: hoy (day 0), +2 días vs day 0, +7 días, ya expirada, +30 días vs day 7. Todos pasan. | ✅ PASS |
| 10 | `tecnomecanica.service.spec.ts` pasa verde | `npx jest --testPathPatterns=tecnomecanica` → 18/18 tests, 0 failures. | ✅ PASS |
| 11 | Build TS sin errores nuevos | `npm run build` en `vehicles-ms` y `api-gateway` → exit 0, sin errores de compilación. | ✅ PASS |
| 12 | Suite SOAT sigue verde | `npx jest --testPathPatterns=soat` → 9/9 tests, 0 failures. | ✅ PASS |
| 13 | Gate: migración local validada por humano | Confirmado en `backend.md`: migración aplicada en `localhost:5430`, tabla `Tecnomecanica` listada en `\dt`. No automatizable. | ⚠️ GATE HUMANO |

**Gap identificado (AC 8):** La validación del DTO en capa de transporte solo puede probarse en e2e contra el gateway levantado. Los tests unitarios actuales simulan la lógica de negocio pero no pasan por `class-validator`. Esto no bloquea el sign-off dado que el patrón es idéntico al DTO de SOAT (mismo mecanismo, ya en producción).

---

## Matriz de regresion

| Guardrail §6 | Mecanismo de verificación | Estado |
|-------------|--------------------------|--------|
| `model Soat` no se toca; diff solo añade líneas | `grep -A20 "model Soat" schema.prisma` confirma que el modelo termina antes del nuevo `model Tecnomecanica`. SQL de migración no incluye ninguna sentencia sobre `Soat`. | ✅ |
| `soat.service.spec.ts` pasa verde sin modificaciones | `npx jest --testPathPatterns=soat` → 9/9 verde. | ✅ |
| No se añade `NotificationType` ni cron | `grep -rn "NotificationType\|@Cron" vehicles-ms/src/` → sin resultados. | ✅ |
| Rutas REST SOAT sin cambios funcionales | Métodos `upsertSoat`, `getSoat`, `deleteSoat` en `api-gateway/src/vehicles/vehicles.controller.ts` no fueron modificados (lectura del archivo). | ✅ |
| `@MessagePattern` existentes no alterados | Los 4 patrones RTM fueron añadidos **después** de los de SOAT. Los 4 patterns SOAT (`upsertSoat`, `findSoatByVehicle`, `deleteSoat`, `findSoatsExpiringIn`) permanecen intactos. | ✅ |
| Migración remota no disparada por workflow | El archivo SQL existe en `migrations/` para uso manual. No hay script automatizado de deploy en el diff. | ✅ |

---

## Ejecucion

### Backend (vehicles-ms)
```
npx jest --testPathPatterns=tecnomecanica
  Test Suites: 1 passed, 1 total
  Tests:       18 passed, 18 total
  Time:        0.211 s

npx jest --testPathPatterns=soat
  Test Suites: 1 passed, 1 total
  Tests:       9 passed, 9 total
  Time:        0.16 s

npm run build (vehicles-ms)  → exit 0, 0 errores TS
npm run build (api-gateway)  → exit 0, 0 errores TS
```

### Flutter (Rideglory)
```
dart analyze → No issues found!
flutter test → +656 tests, 0 failures
```

No hay cambios en código Flutter en este diff (la fase es backend-only).

### Nota sobre `npm test -- --testPathPattern`
La versión de Jest instalada en el repo ya no acepta `--testPathPattern` (singular); usa `--testPathPatterns`. El handoff `architect-for-qa.md` documenta la sintaxis antigua. Se invocó directamente con `npx jest --testPathPatterns=<pattern>` para evitar el error de lifecycle. Pre-existing issue, no regresión del diff.

---

## Bugs

Ningún bug de regresión encontrado. El gap de AC 8 (sin test e2e de DTO rejection) es documentado como **mejora futura**, no bloqueante.

---

## Pruebas manuales

Las siguientes verificaciones requieren entorno levantado y no son automatizables:

1. **Auth guard activo (AC 3):** `curl -X POST http://localhost:3000/api/vehicles/<uuid>/tecnomecanica` sin header `Authorization` → debe devolver 401.
2. **validateVehicleOwnership 403 (AC 4):** Autenticado como usuario A, intentar `GET /api/vehicles/<vehicleId-de-usuario-B>/tecnomecanica` → debe devolver 403.
3. **GET 404 sin RTM (AC 6):** `GET /api/vehicles/<vehicleId-válido-sin-rtm>/tecnomecanica` con token válido del dueño → debe devolver 404 (no 200 con null).
4. **Migración remota (AC 13 / Gate):** `prisma migrate deploy` en producción, responsabilidad del humano; el SQL está en `vehicles-ms/prisma/migrations/20260604173849_add_tecnomecanica/migration.sql`.

---

## Sign-off

**GREEN** — Todos los criterios automatizables pasan. La lógica de negocio RTM está correctamente implementada y testeada (18 tests nuevos). Las suites de regresión SOAT (9 tests) siguen verde. Builds TS limpios en ambos paquetes. Flutter analyzer y 656 tests sin cambios. El único gate pendiente es la validación humana de la migración remota (AC 13), que es deliberadamente no automatizable según el PRD.
