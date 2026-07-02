> Slim handoff — read this before handoffs/architect.md

# Architect → Backend

Repo: `rideglory-api` at `/Users/cami/Developer/Personal/rideglory-api` (super-repo, submódulos independientes). Sigue el orden abajo estrictamente (gotcha de rebuild de contratos).

## 1. `rideglory-contracts` (primero, `npm run build` al final)

- `src/events/dto/create-registration.dto.ts`: agregar, todos `@IsOptional()`:
  - `shareMedicalInfo?: boolean` (`@IsBoolean()`)
  - `allowOrganizerContact?: boolean` (`@IsBoolean()`)
  - `riskAcceptedAt?: Date` (`@Type(() => Date) @IsDate()`)
  - `riskAcceptanceVersion?: string` (`@IsString()`)
- `src/events/dto/event-registration.dto.ts`: agregar como campos de respuesta no-opcionales:
  - `shareMedicalInfo!: boolean`
  - `allowOrganizerContact!: boolean`
  - `riskAcceptedAt!: Date | null`
  - `riskAcceptanceVersion!: string | null`
- `src/events/dto/create-event.dto.ts`: agregar `organizerAcceptedResponsibilityAt?: Date` (`@IsOptional() @Type(() => Date) @IsDate()`). No tocar `update-event.dto.ts` — `UpdateEventDto extends PartialType(CreateEventDto)` lo hereda solo.
- Nuevo `src/users/dto/medical-consent.dto.ts`:
  ```ts
  export class MedicalConsentDto {
    @IsString() @MinLength(1) consentVersion!: string;
  }
  export class MedicalConsentResponseDto {
    medicalConsentAcceptedAt!: Date;
  }
  export const NOT_SHARED_SENTINEL = '__NOT_SHARED__' as const;
  ```
- `src/users/dto/index.ts`: `export * from './medical-consent.dto';`
- `npm run build` (exit 0, sin errores TS) antes de tocar ningún MS.

## 2. `events-ms`

- `prisma/schema.prisma`: 4 campos en `EventRegistration` (`shareMedicalInfo Boolean @default(false)`, `allowOrganizerContact Boolean @default(false)`, `riskAcceptedAt DateTime?`, `riskAcceptanceVersion String?`) + `organizerAcceptedResponsibilityAt DateTime?` en `Event` (NO tocar `sosTriggeredAt`, ya existe). DDL completo en `analysis/MIGRATION_PLAN.md`.
- Generar migración (`prisma migrate dev --create-only` o el flujo habitual del repo) — no aplicar contra prod sin aprobación humana.
- `pnpm install` (toma contracts nuevo).
- **CRÍTICO — `src/registrations/registrations.service.ts::create()` (líneas ~72-87):** el objeto `registrationData` se construye campo-por-campo, NO hace spread de `data`. Agregar explícitamente:
  ```ts
  shareMedicalInfo: data.shareMedicalInfo ?? false,
  allowOrganizerContact: data.allowOrganizerContact ?? false,
  riskAcceptedAt: data.riskAcceptedAt ?? null,
  riskAcceptanceVersion: data.riskAcceptanceVersion ?? null,
  ```
  Si se omite este paso, el DTO acepta los campos pero nunca se persisten (falla silenciosa de los criterios #5/#6).
- `update()` NO necesita cambios — ya hace `{ ...rest, status, medicalInsurance }`, spreadea todo.
- `owner-auto-registration.ts` y `events.service.ts` (`create`/`update` de Event) — verificado, NO necesitan cambios; Prisma aplica defaults y ambos spreadean el DTO completo.

## 3. `users-ms`

- `prisma/schema.prisma`: `medicalConsentAcceptedAt DateTime?` en `User`.
- Migración → `pnpm install`.
- `src/users/users.service.ts`: nuevo método `acceptMedicalConsent(email: string, consentVersion: string)` — reusa lógica de `findByEmail` (lanza `RpcException NOT_FOUND` si no existe), luego `this.user.update({ where: { id: user.id }, data: { medicalConsentAcceptedAt: new Date() } })`, retorna `{ medicalConsentAcceptedAt }`. `consentVersion` no tiene columna — loguear con `Logger.log` para auditoría (no hay campo de versión en el schema propuesto por el PRD).
- `src/users/users.controller.ts`: `@MessagePattern('acceptMedicalConsent') acceptMedicalConsent(@Payload() payload: { email: string; consentVersion: string })`.
- `GET /users/me` (`findByEmail`/`findUserByEmail`) NO necesita cambios de código — el campo aparece solo al estar en el schema (retorna el objeto Prisma completo).

## 4. `api-gateway`

- `pnpm install` (toma contracts).
- `src/users/users.controller.ts`: nuevo endpoint
  ```ts
  @Post('me/medical-consent')
  acceptMedicalConsent(@Req() request: AuthenticatedRequest, @Body() dto: MedicalConsentDto) {
    const email = request.user?.email;
    if (!email) throw new UnauthorizedException('Authenticated user email is required');
    return this.usersService.send('acceptMedicalConsent', { email, consentVersion: dto.consentVersion });
  }
  ```
  Mismo patrón que `findMe` (ya en el archivo) — auth global vía `APP_GUARD`, no requiere `@Public()`.

## Orden obligatorio

contracts (build) → events-ms (schema+migración+install+`registrations.service.ts`) → users-ms (schema+migración+install+service+controller) → api-gateway (install+controller).

## Verificación antes de reportar

- `prisma migrate status` "up to date" en `events-ms` y `users-ms`.
- `npm run build` en contracts, exit 0.
- `pnpm run start:dev` en `events-ms`, `users-ms`, `api-gateway` sin `MODULE_NOT_FOUND`.
- Smoke: `POST /events/:id/registrations` con los 4 campos nuevos → 201, valores persistidos en DB (no solo aceptados por el DTO).
- Smoke: `POST /users/me/medical-consent` con `{ consentVersion }` → 201 `{ medicalConsentAcceptedAt }`.
- `GET /users/me` incluye `medicalConsentAcceptedAt`.

> Full detail: handoffs/architect.md
