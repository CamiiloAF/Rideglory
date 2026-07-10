# Migration Plan — eliminacion-cuenta-phase-03

_Generado: 2026-07-10T19:31:56Z_

## Alcance

Migración Prisma **aditiva** en `rideglory-api/events-ms/prisma/schema.prisma`, modelo
`EventRegistration`. Relaja a nullable (`DROP NOT NULL`) las siguientes 8 columnas:

- `identificationNumber`
- `birthDate`
- `phone`
- `email`
- `residenceCity`
- `eps`
- `emergencyContactName`
- `emergencyContactPhone`

**NO tocar**: `bloodType` (permanece `NOT NULL`, tipo enum `BloodType`), `medicalInsurance`
(ya nullable), `fullName` (permanece `NOT NULL` — el backend siempre escribe
`'Usuario eliminado'`, nunca `null`), `shareMedicalInfo`/`allowOrganizerContact` (booleanos con
default, se actualizan a `false` en la anonimización pero no cambian de tipo/nulabilidad),
`riskAcceptedAt`/`riskAcceptanceVersion`/`medicalConsentAcceptedAt`/`medicalConsentVersion` (ya
nullable, no se tocan — evidencia legal preservada).

## Pasos

1. Editar `schema.prisma`: quitar el modificador de requerido en las 8 columnas listadas
   (`String` → `String?`, `DateTime` → `DateTime?`).
2. `npx prisma migrate dev --name registration_nullable_pii` desde `events-ms/` contra la BD
   local de `events-ms` — genera el SQL (`ALTER TABLE "EventRegistration" ALTER COLUMN "..."
   DROP NOT NULL;` x8) y lo aplica localmente.
3. Verificar contra datos reales locales (o un dump/copia de prod si está disponible) que las
   filas existentes no cambian de valor — un `DROP NOT NULL` no requiere backfill ni toca datos
   existentes, solo relaja el constraint.
4. `prisma generate` para regenerar el cliente (`PrismaClient` en `events-ms/src/generated/prisma`).
5. **No desplegar** — esperar verificación humana explícita antes de correr la migración contra
   la BD de producción (flujo de deploy ya establecido del proyecto, ver memoria
   `feedback_deploy_workflow`).

## Riesgo

Alto porque toca una tabla con datos reales de producción, pero el cambio en sí (relajar
`NOT NULL`) es de los más seguros posibles en Postgres: no bloquea la tabla de forma prolongada,
no requiere reescritura de filas, y es reversible (`SET NOT NULL` de vuelta) si no hubiera
ninguna fila con `NULL` todavía.

## Rollback

Si algo falla tras desplegar: `ALTER TABLE "EventRegistration" ALTER COLUMN "<col>" SET NOT
NULL;` por cada columna — solo es posible mientras ninguna fila tenga `NULL` en esa columna
(es decir, antes de que `anonymizeByUserId` se haya ejecutado alguna vez en prod). Una vez haya
registros anonimizados, el rollback de schema requeriría decidir qué valor placeholder usar —
fuera de alcance de esta fase (no se afirma una estrategia de rollback post-anonimización).
