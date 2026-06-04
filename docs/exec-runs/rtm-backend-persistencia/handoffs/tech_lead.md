# Tech Lead Handoff — rtm-backend-persistencia
Generated: 2026-06-04T17:50:58Z

---

## Veredicto

**READY** — sin blockers. La implementación es correcta, completa y coherente con los contratos del Architect.

---

## Hallazgos

### No blockers

Todos los criterios de aceptación §5 del PRD están satisfechos:

| AC | Estado | Nota |
|----|--------|------|
| 1 — model Tecnomecanica en schema | ✅ | Byte-idéntico al spec del Architect; `model Soat` intacto |
| 2 — Migración sin alterar Soat | ✅ | SQL contiene solo `CREATE TABLE "Tecnomecanica"` + `CREATE UNIQUE INDEX` |
| 3 — Firebase Auth en las 3 rutas | ✅ | Guard global `APP_GUARD` en `auth.module.ts`; las rutas heredan sin anotaciones adicionales |
| 4 — `validateVehicleOwnership` en upsert/find/delete | ✅ | Presente en las 3 operaciones del service |
| 5 — `400` cuando `expiryDate <= startDate`; acepta sin startDate | ✅ | Lógica correcta; skip de validación cuando `startDate` es undefined |
| 6 — `GET /tecnomecanica` → 404 cuando no existe | ✅ | `if (!rtm) throw new NotFoundException(...)` en gateway |
| 7 — `DELETE` → 404 si no existe; `{ success: true }` si borra | ✅ | Verificación de existencia antes de delete en el service |
| 8 — DTO rechaza required faltantes; acepta opcionales ausentes | ✅ | Decoradores class-validator correctos; ambas copias idénticas |
| 9 — `findTecnomecanicasExpiringIn` ventana UTC día-exacto | ✅ | Lógica idéntica a `findSoatsExpiringIn` |
| 10 — 18 tests verde | ✅ | Confirmado por QA |
| 11 — Build TS sin errores | ✅ | Confirmado por QA |
| 12 — Suite SOAT sigue verde | ✅ | 9/9 sin modificaciones |
| 13 — Gate humano migración local | ⚠️ GATE | Confirmado en backend.md; migración remota pendiente del humano |

### Observaciones (no bloqueantes)

**O1 — RTM gateway routes no tienen `catchError` explícito.**
Las tres rutas RTM en `api-gateway/src/vehicles/vehicles.controller.ts` usan `firstValueFrom(...pipe(timeout(10_000)))` sin `catchError`. Esto es **consistente** con las rutas SOAT recién añadidas (upsertSoat, getSoat, deleteSoat tienen el mismo patrón) y con el `RpcCustomExceptionFilter` global que mapea `RpcException{status, message}` a la respuesta HTTP correcta. No es un defecto — es una elección deliberada del codebase.

**O2 — `@IsDateString()` sin `@IsNotEmpty()` en `expiryDate`.**
Mismo patrón que `CreateSoatDto`. `@IsDateString()` rechaza strings vacíos, por lo que la protección existe. No hay divergencia.

**O3 — test de find devuelve `{ status: 200, data: null }` cuando no hay RTM y el owner coincide.**
El test "returns null (no document) when owner matches but no RTM exists" simula que `simulateFind` devuelve `{ status: 200, data: null }`. Esto es coherente con el comportamiento del MS real (`findUnique` devuelve `null`), pero el gateway convierte ese `null` en un `404 NotFoundException`. El test del spec refleja solo la capa MS; la semántica 404 se cubre por la lógica del gateway. No hay contradicción.

---

## Seguridad

- Sin secretos hardcodeados en ningún archivo del diff.
- Sin SQL concatenado; Prisma ORM con parámetros tipados en todos los queries.
- Sin PII en logs; el `logger.log('TecnomecanicaService DB connected')` no expone datos.
- Firebase Auth guard global cubre las 3 rutas REST — un request sin token recibe 401/403 antes de llegar al controller handler.
- `validateVehicleOwnership` previene cross-user access en las 3 operaciones de MS.
- `DATABASE_URL` leída de `process.env`; sin URLs hardcodeadas.

---

## Arquitectura

- Tablas separadas (`Tecnomecanica` vs `Soat`): constraint A1 respetado.
- DTO duplicado por paquete: constraint A2 respetado; ambas copias idénticas al spec del Architect.
- `startDate @IsOptional()`: corrección deliberada vs SOAT (A3); implementada correctamente.
- `GET 404 en ausencia de RTM` (A4): implementado con `NotFoundException` en el gateway; el MS devuelve `null` (no lanza) y el gateway lo eleva a 404.
- `TecnomecanicaService extends PrismaClient implements OnModuleInit` (A5): pattern idéntico a `SoatService`.
- Tests pure-logic (A6): sin mock de Prisma, solo helpers que replican la lógica del service.
- Migración local-first con gate humano (A7): cumplido.
- Ningún archivo fuera del change map fue modificado.
- `model Soat` y sus servicios/DTOs/routes son byte-idénticos al estado pre-fase.
- Sin `NotificationType` ni cron añadidos.

---

## Tests

- **18 tests RTM** (`tecnomecanica.service.spec.ts`): cubren todos los AC testables unitariamente.
- **9 tests SOAT** (`soat.service.spec.ts`): pasan verde sin modificaciones.
- **Gap documentado (AC 8)**: la validación `class-validator` solo puede cubrirse en e2e contra el gateway levantado. El patrón es idéntico al de SOAT (en producción desde hace tiempo). No es bloqueante para este sign-off; es una mejora futura.
- Build TS limpio en `vehicles-ms` y `api-gateway`.

---

## Pruebas manuales

Antes de commitear, el humano debe verificar:

1. **Auth guard (AC 3):**
   ```bash
   curl -X POST http://localhost:3000/api/vehicles/<uuid>/tecnomecanica \
     -H "Content-Type: application/json" \
     -d '{"certificateNumber":"CRT-001","cdaName":"CDA A","expiryDate":"2027-01-01"}'
   # Esperado: 401 Unauthorized (sin token)
   ```

2. **validateVehicleOwnership 403 (AC 4):**
   Autenticado como usuario A, `GET /api/vehicles/<vehicleId-de-usuario-B>/tecnomecanica` con token de A → debe devolver 403.

3. **GET 404 sin RTM (AC 6):**
   Con token válido del dueño, `GET /api/vehicles/<vehicleId-sin-rtm>/tecnomecanica` → debe devolver 404 (no 200 con null).

4. **Migración remota (AC 13 / Gate):**
   Ejecutar `prisma migrate deploy` en producción con el SQL de `vehicles-ms/prisma/migrations/20260604173849_add_tecnomecanica/migration.sql`. Responsabilidad del humano; no automatizable.
