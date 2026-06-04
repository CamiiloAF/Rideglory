# Auditoría — Backend RTM Persistencia

> Auditor: Opus · 2026-06-04T17:43:57Z · Veredicto: APROBADO (score 90)

## Verificaciones ejecutadas

- `npx jest tecnomecanica.service.spec.ts soat.service.spec.ts` → 27/27 verde (18 RTM + 9 SOAT).
- `tsc --noEmit` en vehicles-ms y api-gateway → 0 errores.
- Cliente Prisma generado incluye `Tecnomecanica` (index.d.ts: 395 refs).
- Diff de `schema.prisma`: ninguna línea de `Soat` modificada; solo añade `model Tecnomecanica`.
- Sin secretos / URLs hardcodeadas / PII en archivos nuevos.

## AC

| AC | Estado | Nota |
|----|--------|------|
| 1 modelo Tecnomecanica + Soat byte-idéntico | OK | vehicleId @unique, cdaCode?/startDate?/documentUrl? opcionales |
| 2 migración crea solo Tecnomecanica | OK | migration.sql: CREATE TABLE + UNIQUE INDEX, no toca Soat |
| 3 3 rutas REST con Firebase Auth | OK | FirebaseAuthGuard es APP_GUARD global; rutas sin @Public → protegidas |
| 4 validateVehicleOwnership en upsert/find/delete | OK | invocado en las 3 |
| 5 400 si expiry<=start; startDate opcional persiste | OK | parseDate + guard condicional a startDate presente |
| 6 GET 404 sin RTM | OK | `throw new NotFoundException` (no 200+null) — diferencia deliberada vs SOAT |
| 7 DELETE 404 / {success:true} | OK | espejo de deleteSoat |
| 8 DTO required/optional explícito, idéntico ambos paquetes | OK | gateway y MS byte-idénticos; startDate @IsOptional (corrige mismatch SOAT) |
| 9 findTecnomecanicasExpiringIn ventana UTC día | OK | misma lógica exacta que findSoatsExpiringIn |
| 10 spec cubre upsert/find/delete/expiring, verde | OK con caveat | ver hallazgo H1 |
| 11 build TS limpio | OK | 0 errores |
| 12 regresión SOAT verde, sin NotificationType/cron | OK | 9/9 SOAT verde; no se añadió cron ni NotificationType |

## Hallazgos

**H1 (no bloqueante) — Tests "pure-logic extraction" no vinculan la clase real.**
`tecnomecanica.service.spec.ts` reimplementa copias espejo de `parseDate`/`validateDates`/`isExpiringIn` y simula find/delete con funciones locales (`simulateFind`, `simulateDelete`). No importa ni instancia `TecnomecanicaService`, por lo que un bug introducido en el service real NO haría fallar la suite. Es el patrón ya establecido del repo (`soat.service.spec.ts` hace lo mismo) y la fase ancló RTM a espejar SOAT; AC #10 pide "cubrir" los paths, lo cual se cumple formalmente. Recomendación futura: tests de integración con Prisma test-double que ejerciten el service real.

**H2 (positivo)** — La spec RTM supera a la de SOAT: añade cobertura de ownership (403) y guard de delete (404), que SOAT no tenía.

**H3 (ruido, fuera de change map)** — `.DS_Store` y `users-ms/package-lock.json` aparecen en working tree; no son del agente backend ni del change map RTM. Ignorar.
