# Migration plan — legal-privacidad-edad-fase1

No se ejecuta contra DB real en esta fase (regla dura del workflow). Backend genera las migraciones
(`prisma migrate dev`) y reporta status; el humano decide cuándo aplicarlas en cada entorno.

## events-ms

Schema (`events-ms/prisma/schema.prisma`):

```prisma
model EventRegistration {
  // ...campos existentes sin cambios...
  shareMedicalInfo       Boolean   @default(false)
  allowOrganizerContact  Boolean   @default(false)
  riskAcceptedAt         DateTime?
  riskAcceptanceVersion  String?
}

model Event {
  // ...campos existentes sin cambios, incluyendo sosTriggeredAt (línea ~77, NO tocar)...
  organizerAcceptedResponsibilityAt DateTime?
}
```

DDL esperado (generado por Prisma, no escrito a mano):

```sql
ALTER TABLE "EventRegistration"
  ADD COLUMN "shareMedicalInfo" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "allowOrganizerContact" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "riskAcceptedAt" TIMESTAMP(3),
  ADD COLUMN "riskAcceptanceVersion" TEXT;

ALTER TABLE "Event"
  ADD COLUMN "organizerAcceptedResponsibilityAt" TIMESTAMP(3);
```

Naturaleza: additive, sin backfill necesario (defaults seguros para booleanos, nullable para el resto).
Filas existentes de `EventRegistration` quedan con `shareMedicalInfo=false`, `allowOrganizerContact=false`,
`riskAcceptedAt=NULL`, `riskAcceptanceVersion=NULL` — comportamiento esperado por criterio de aceptación #6
del PRD.

## users-ms

Schema (`users-ms/prisma/schema.prisma`):

```prisma
model User {
  // ...campos existentes sin cambios...
  medicalConsentAcceptedAt DateTime?
}
```

DDL esperado:

```sql
ALTER TABLE "User" ADD COLUMN "medicalConsentAcceptedAt" TIMESTAMP(3);
```

Naturaleza: additive, nullable, sin backfill.

## Orden y comandos (referencia para Backend)

1. `rideglory-contracts`: editar DTOs → `npm run build`.
2. `events-ms`: editar schema → `npx prisma migrate dev --name add_medical_consent_risk_fields --create-only` (o `migrate dev` directo según convención del repo) → revisar SQL generado coincide con lo anterior → aplicar → `pnpm install` (contracts) → editar `registrations.service.ts::create()`.
3. `users-ms`: editar schema → `npx prisma migrate dev --name add_medical_consent_accepted_at` → `pnpm install` → editar `users.service.ts`/`users.controller.ts`.
4. `api-gateway`: `pnpm install` → editar `users.controller.ts`.
5. Verificar `prisma migrate status` en ambos MS reporta "Database schema is up to date" (criterios #1, #2).

## Riesgo

Bajo — ambas migraciones son puramente additivas. Único cuidado: no re-declarar `sosTriggeredAt` en
`Event` (ya existe) al editar el schema — solo agregar `organizerAcceptedResponsibilityAt` al final del
modelo.
