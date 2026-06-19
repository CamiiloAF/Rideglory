# Fase 1 — Contratos, schema de backend y endpoint medical-consent

**Slug:** `legal-privacidad-edad`
**Timestamp:** 2026-06-19T19:46:13Z
**Nivel:** full
**dependsOn:** []

---

## Objetivo

Habilitar en el backend toda la infraestructura de datos que las fases 2-7 necesitan: migraciones Prisma en `events-ms` (4 campos en `EventRegistration` + 1 en `Event`) y en `users-ms` (1 campo en `User`), actualización del submódulo `rideglory-contracts` con los DTOs ampliados y los dos nuevos contratos de consentimiento médico, y el nuevo endpoint `POST /users/me/medical-consent`. Al cierre de esta fase, el backend puede recibir y persistir todos los campos legales nuevos; los contratos están compilados y disponibles en todos los microservicios afectados.

---

## Alcance (entra / no entra)

### Entra

- Migración Prisma en **events-ms**: 4 campos en `EventRegistration` + 1 campo en `Event` (verificando si `sosTriggeredAt` ya existe — solo agregar `organizerAcceptedResponsibilityAt`).
- Migración Prisma en **users-ms**: campo `medicalConsentAcceptedAt DateTime?` en `User`.
- **rideglory-contracts**: ampliar `CreateRegistrationDto`, `EventRegistrationDto`, `CreateEventDto` / `UpdateEventDto`; agregar `MedicalConsentDto` y `MedicalConsentResponseDto`.
- Nuevo endpoint `POST /users/me/medical-consent` en `users-ms` + exposición en `api-gateway`.
- `GET /users/me` retorna `medicalConsentAcceptedAt` en la respuesta.
- Fijar el centinela semántico `"__NOT_SHARED__"` como constante documentada en contratos.
- Seguir el gotcha `project_contracts_rebuild_gotcha.md`: `npm run build` en `rideglory-contracts` + `pnpm install` en `events-ms`, `users-ms` y `api-gateway` antes de levantar cualquier servicio.

### No entra

- Lógica de validación de edad (`UNDERAGE_RIDER`) → Fase 2.
- Lógica de ofuscación condicional en `findByEvent` → Fase 2.
- Modelos y DTOs Flutter → Fase 3.
- UI de waiver, pantalla de responsabilidad del organizador, Ley 1581 → Fases 4-6.
- Tests unitarios de la lógica de negocio de las inscripciones → Fase 2.

---

## Que se debe hacer (pasos concretos y ordenados)

### Pre-flight

1. Verificar en `events-ms/prisma/schema.prisma` que `Event.sosTriggeredAt DateTime?` **ya existe** (confirmado en el scan: línea 77). No agregar de nuevo; solo documentarlo en el handoff para la Fase 2.
2. Verificar en `events-ms/prisma/schema.prisma` que `organizerAcceptedResponsibilityAt` **no existe** aún (confirmado por grep sin resultado). Proceder a agregarlo.
3. Verificar en `users-ms/prisma/schema.prisma` que `medicalConsentAcceptedAt` **no existe** (confirmado). Proceder a agregarlo.

### Paso 1 — Migración Prisma en events-ms

Agregar al modelo `EventRegistration` en `events-ms/prisma/schema.prisma`:

```prisma
shareMedicalInfo         Boolean   @default(false)
allowOrganizerContact    Boolean   @default(false)
riskAcceptedAt           DateTime?
riskAcceptanceVersion    String?
```

Agregar al modelo `Event` en el mismo schema:

```prisma
organizerAcceptedResponsibilityAt DateTime?
```

Generar la migración con nombre descriptivo:

```bash
cd /Users/cami/Developer/Personal/rideglory-api/events-ms
npx prisma migrate dev --name add_legal_fields_registration_and_event
```

Verificar que el SQL generado incluya los defaults seguros (`DEFAULT false`) para los booleanos y que `riskAcceptedAt` y `organizerAcceptedResponsibilityAt` sean nullable sin default (correcto para registros pre-migración).

### Paso 2 — Migración Prisma en users-ms

Agregar al modelo `User` en `users-ms/prisma/schema.prisma`:

```prisma
medicalConsentAcceptedAt DateTime?
```

Generar la migración:

```bash
cd /Users/cami/Developer/Personal/rideglory-api/users-ms
npx prisma migrate dev --name add_medical_consent_accepted_at
```

### Paso 3 — Contratos: ampliar CreateRegistrationDto

Archivo: `rideglory-contracts/src/events/dto/create-registration.dto.ts`

Agregar los 4 campos legales nuevos con sus decoradores `class-validator`:

```typescript
@IsBoolean()
shareMedicalInfo: boolean = false;

@IsBoolean()
allowOrganizerContact: boolean = false;

@IsOptional()
@Type(() => Date)
@IsDate()
riskAcceptedAt?: Date;

@IsOptional()
@IsString()
riskAcceptanceVersion?: string;
```

Nota de negocio para el implementador backend (no se valida en el DTO sino en el servicio): si `riskAcceptedAt` es `undefined` o `null` al crear una inscripción nueva, `RegistrationsService.create()` debe rechazar con `422 RISK_NOT_ACCEPTED`. Esta regla de negocio se implementa en Fase 2; aquí solo se declara el campo como `@IsOptional()` en el contrato porque las inscripciones pre-migración son válidas con `null`.

`UpdateRegistrationDto` hereda via `PartialType(OmitType(CreateRegistrationDto, ['eventId']))` — los 4 campos quedan opcionales automáticamente. No requiere cambios adicionales.

### Paso 4 — Contratos: ampliar EventRegistrationDto (respuesta)

Archivo: `rideglory-contracts/src/events/dto/event-registration.dto.ts`

Cambiar `bloodType` de `BloodType` a `BloodType | string` para soportar el centinela semántico en la respuesta del organizador:

```typescript
bloodType!: BloodType | string;  // BloodType enum o '__NOT_SHARED__' cuando ofuscado
```

Agregar los campos nuevos de privacidad y los campos potencialmente ofuscables como `string` (no como tipos específicos) para que el centinela pueda viajar sin romper el tipo:

```typescript
// Campos legales nuevos
shareMedicalInfo!: boolean;
allowOrganizerContact!: boolean;
riskAcceptedAt!: Date | null;
riskAcceptanceVersion!: string | null;
```

Agregar comentario de documentación del centinela semántico en el archivo (o en un archivo `CENTINELAS.md` bajo `rideglory-contracts/src/events/`):

```typescript
/**
 * Centinela semántico para campos no compartidos por política de privacidad.
 * El backend retorna '__NOT_SHARED__' en lugar de strings en español.
 * Flutter localiza este centinela a texto legible en la UI.
 */
export const NOT_SHARED_SENTINEL = '__NOT_SHARED__';
```

### Paso 5 — Contratos: ampliar CreateEventDto

Archivo: `rideglory-contracts/src/events/dto/create-event.dto.ts`

Agregar al final de la clase:

```typescript
@IsOptional()
@Type(() => Date)
@IsDate()
organizerAcceptedResponsibilityAt?: Date;
```

`UpdateEventDto` extiende `PartialType(CreateEventDto)` — el campo queda opcional automáticamente. No requiere cambios.

### Paso 6 — Contratos: nuevos DTOs de consentimiento médico

Crear archivo: `rideglory-contracts/src/users/dto/medical-consent.dto.ts`

```typescript
import { IsString, MinLength } from 'class-validator';

export class MedicalConsentDto {
  @IsString()
  @MinLength(1)
  consentVersion!: string;
}

export class MedicalConsentResponseDto {
  medicalConsentAcceptedAt!: Date;
}
```

Exportar desde `rideglory-contracts/src/users/dto/index.ts`:

```typescript
export * from './medical-consent.dto';
```

### Paso 7 — Compilar contratos y actualizar dependencias

Seguir el gotcha `project_contracts_rebuild_gotcha.md` de forma estricta:

```bash
# 1. Compilar contratos
cd /Users/cami/Developer/Personal/rideglory-api/rideglory-contracts
npm run build

# 2. Actualizar eventos-ms
cd /Users/cami/Developer/Personal/rideglory-api/events-ms
pnpm install

# 3. Actualizar users-ms
cd /Users/cami/Developer/Personal/rideglory-api/users-ms
pnpm install

# 4. Actualizar api-gateway
cd /Users/cami/Developer/Personal/rideglory-api/api-gateway
pnpm install
```

Si alguno falla con `MODULE_NOT_FOUND`, hacer `npm run build` nuevamente en `rideglory-contracts` y repetir el `pnpm install` en el MS afectado.

### Paso 8 — Nuevo endpoint medical-consent en users-ms

**users-ms — MessagePattern:**

Archivo: `users-ms/src/users/users.controller.ts`

Agregar handler con `@MessagePattern('acceptMedicalConsent')`:

```typescript
@MessagePattern('acceptMedicalConsent')
acceptMedicalConsent(@Payload() data: { userId: string; dto: MedicalConsentDto }): Promise<MedicalConsentResponseDto> {
  return this.usersService.acceptMedicalConsent(data.userId, data.dto);
}
```

**users-ms — Service:**

Archivo: `users-ms/src/users/users.service.ts`

Agregar método `acceptMedicalConsent(userId: string, dto: MedicalConsentDto)`:
- Hace `prisma.user.update({ where: { id: userId }, data: { medicalConsentAcceptedAt: new Date() } })`.
- Retorna `MedicalConsentResponseDto { medicalConsentAcceptedAt }`.
- No requiere validación adicional — el endpoint ya está protegido por autenticación Firebase en el gateway.

**api-gateway — UsersController:**

Archivo: `api-gateway/src/users/users.controller.ts`

Agregar endpoint REST:

```typescript
@Post('me/medical-consent')
acceptMedicalConsent(
  @Req() request: AuthenticatedRequest,
  @Body() dto: MedicalConsentDto,
) {
  const email = request.user?.email;
  if (!email) throw new UnauthorizedException('Authenticated user email is required');
  // Primero obtener el userId desde el email, luego llamar al MS
  return this.usersService.send('acceptMedicalConsent', { email, dto });
}
```

Nota de implementación: si `users-ms` actualmente busca usuario por email en `findUserByEmail`, el `acceptMedicalConsent` puede recibir `email` y buscar el `userId` internamente en el servicio, o el gateway puede hacer dos llamadas TCP (primero `findUserByEmail`, luego `acceptMedicalConsent` con el `id`). El implementador elige el patrón más consistente con el código existente y lo documenta en el handoff de la fase.

**`GET /users/me` — verificar que retorna `medicalConsentAcceptedAt`:**

El handler `findUserByEmail` en `users-ms` retorna el `User` completo de Prisma. Después de la migración, `medicalConsentAcceptedAt` aparecerá automáticamente en la respuesta. Verificar con curl/test que el campo aparece (puede ser `null` para usuarios existentes).

### Paso 9 — Verificación end-to-end de la fase

Ver sección Criterios de Aceptación.

---

## Archivos a crear/modificar (rutas reales)

### rideglory-api/events-ms

| Ruta | Acción | Qué cambia |
|------|--------|-----------|
| `events-ms/prisma/schema.prisma` | Modificar | +4 campos en `EventRegistration` + 1 campo `organizerAcceptedResponsibilityAt` en `Event` |
| `events-ms/prisma/migrations/<timestamp>_add_legal_fields_registration_and_event/migration.sql` | Crear (auto) | SQL generado por `prisma migrate dev` con los 5 campos y defaults seguros |

### rideglory-api/users-ms

| Ruta | Acción | Qué cambia |
|------|--------|-----------|
| `users-ms/prisma/schema.prisma` | Modificar | +1 campo `medicalConsentAcceptedAt DateTime?` en `User` |
| `users-ms/prisma/migrations/<timestamp>_add_medical_consent_accepted_at/migration.sql` | Crear (auto) | SQL generado por `prisma migrate dev` |
| `users-ms/src/users/users.controller.ts` | Modificar | +handler `@MessagePattern('acceptMedicalConsent')` |
| `users-ms/src/users/users.service.ts` | Modificar | +método `acceptMedicalConsent(userId, dto)` con `prisma.user.update` |

### rideglory-api/api-gateway

| Ruta | Acción | Qué cambia |
|------|--------|-----------|
| `api-gateway/src/users/users.controller.ts` | Modificar | +endpoint `POST /users/me/medical-consent` que envía `acceptMedicalConsent` TCP al users-ms |

### rideglory-api/rideglory-contracts

| Ruta | Acción | Qué cambia |
|------|--------|-----------|
| `rideglory-contracts/src/events/dto/create-registration.dto.ts` | Modificar | +4 campos con decoradores: `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt?`, `riskAcceptanceVersion?` |
| `rideglory-contracts/src/events/dto/event-registration.dto.ts` | Modificar | `bloodType` pasa a `BloodType \| string`; +4 campos nuevos (`shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`); +constante `NOT_SHARED_SENTINEL` |
| `rideglory-contracts/src/events/dto/create-event.dto.ts` | Modificar | +campo `organizerAcceptedResponsibilityAt?: Date` con `@IsOptional()` |
| `rideglory-contracts/src/users/dto/medical-consent.dto.ts` | Crear | Nuevas clases `MedicalConsentDto` y `MedicalConsentResponseDto` |
| `rideglory-contracts/src/users/dto/index.ts` | Modificar | +export del nuevo archivo `medical-consent.dto.ts` |

---

## Contratos / API rideglory-api

### Endpoint nuevo

**`POST /users/me/medical-consent`**
- Auth: Firebase ID token requerido (interceptor estándar del gateway).
- Body: `MedicalConsentDto { consentVersion: string }` (validado por `class-validator`).
- Respuesta 201: `MedicalConsentResponseDto { medicalConsentAcceptedAt: Date }`.
- Respuesta 401: si el token no es válido o no hay email en el JWT.
- Idempotente: si el usuario ya tiene `medicalConsentAcceptedAt`, sobreescribe con el nuevo timestamp (no es error — el rider puede volver a autorizar si hay una versión nueva del consentimiento).

### Endpoints modificados

**`GET /users/me`**
- Agrega `medicalConsentAcceptedAt: Date | null` en la respuesta (automático tras la migración Prisma; `null` para usuarios existentes).

**`POST /events/:eventId/registrations`**
- Acepta los 4 campos nuevos: `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt?`, `riskAcceptanceVersion?`.
- La validación de negocio que rechaza con `422 RISK_NOT_ACCEPTED` si `riskAcceptedAt` es null en una inscripción nueva se implementa en Fase 2, no aquí.

**`PATCH /registrations/:id`**
- Acepta los 4 campos como opcionales (herencia de `UpdateRegistrationDto`).

**`PATCH /events/:id`** / **`POST /events`**
- Acepta `organizerAcceptedResponsibilityAt?: Date`. La validación de negocio (exigirlo cuando `state === SCHEDULED`) se implementa en Fase 5.

### Centinela semántico (fijado en esta fase)

- Valor: `"__NOT_SHARED__"` (string literal, sin traducción en el backend).
- Constante exportada desde `rideglory-contracts/src/events/dto/event-registration.dto.ts` como `NOT_SHARED_SENTINEL`.
- Los separadores visuales `"••••"` son responsabilidad de la Fase 2 (ofuscación de emergencia/contacto) y usan el mismo patrón semántico.
- Flutter (Fase 3+) localiza los centinelas a texto en español al renderizar — el backend nunca retorna strings en español para datos ofuscados.

---

## Cambios de datos / migraciones

### events-ms — Una migración, 5 columnas nuevas

**Tabla `EventRegistration`:**

| Columna | Tipo Prisma | SQL | Retrocompatibilidad |
|---------|-------------|-----|---------------------|
| `shareMedicalInfo` | `Boolean @default(false)` | `BOOLEAN NOT NULL DEFAULT false` | Inscripciones pre-migración quedan con `false` — comportamiento correcto (datos médicos no compartidos por defecto) |
| `allowOrganizerContact` | `Boolean @default(false)` | `BOOLEAN NOT NULL DEFAULT false` | Idem — organizador no puede contactar por defecto |
| `riskAcceptedAt` | `DateTime?` | `TIMESTAMP(3)` nullable, sin default | Pre-migración quedan `NULL` — válido histórico; nuevas inscripciones deben proveerlo (Fase 2 valida) |
| `riskAcceptanceVersion` | `String?` | `VARCHAR` nullable, sin default | Idem |

**Tabla `Event`:**

| Columna | Tipo Prisma | SQL | Retrocompatibilidad |
|---------|-------------|-----|---------------------|
| `organizerAcceptedResponsibilityAt` | `DateTime?` | `TIMESTAMP(3)` nullable | Eventos existentes quedan `NULL` — válido histórico; la validación (Fase 5) solo aplica a nuevas publicaciones |

**Campo `sosTriggeredAt` en `Event`:** ya existe en el schema (línea 77, confirmado en pre-flight). No se toca.

### users-ms — Una migración, 1 columna nueva

**Tabla `User`:**

| Columna | Tipo Prisma | SQL | Retrocompatibilidad |
|---------|-------------|-----|---------------------|
| `medicalConsentAcceptedAt` | `DateTime?` | `TIMESTAMP(3)` nullable | Usuarios existentes quedan `NULL` — el wizard les pedirá consentimiento la primera vez (Fase 6) |

### Nota de seguridad sobre los defaults

Sin usuarios reales en producción (confirmado en `project_no_real_users.md`), los defaults retroactivos no afectan datos reales. La migración debe incluir un comentario explícito en el SQL sobre el comportamiento esperado para inscripciones pre-migración, como guía para cuando haya usuarios reales.

---

## Criterios de aceptacion

1. **Migración events-ms aplicada:** `prisma migrate status` en `events-ms` reporta "Database schema is up to date". Las 5 columnas nuevas existen en la tabla `EventRegistration` y `Event` en la base de datos local (verificar con `prisma studio` o query directa).

2. **Migración users-ms aplicada:** `prisma migrate status` en `users-ms` reporta "Database schema is up to date". La columna `medicalConsentAcceptedAt` existe en la tabla `User`.

3. **Contratos compilados sin errores:** `npm run build` en `rideglory-contracts` termina con código de salida 0 y no produce errores de TypeScript.

4. **Dependencias resueltas en todos los MS:** `pnpm install` en `events-ms`, `users-ms` y `api-gateway` termina sin errores. Los servicios levantan con `pnpm run start:dev` sin `MODULE_NOT_FOUND`.

5. **CreateRegistrationDto acepta los 4 campos:** un curl o test de integración a `POST /events/:id/registrations` con body que incluye `shareMedicalInfo: true`, `allowOrganizerContact: false`, `riskAcceptedAt: "2026-06-19T00:00:00Z"`, `riskAcceptanceVersion: "v0.1-2026-06"` retorna 201 (no 400 por campos desconocidos o inválidos). Verificar en la DB que los 4 campos se persistieron con los valores enviados.

6. **EventRegistrationDto de respuesta incluye los 4 campos:** un `GET /events/:id/registrations` retorna los 4 campos nuevos en cada inscripción (`shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`). Para inscripciones pre-migración, `shareMedicalInfo` y `allowOrganizerContact` son `false`; `riskAcceptedAt` y `riskAcceptanceVersion` son `null`.

7. **CreateEventDto acepta organizerAcceptedResponsibilityAt:** un curl a `POST /events` o `PATCH /events/:id` con `organizerAcceptedResponsibilityAt: "2026-06-19T00:00:00Z"` retorna 201/200 y persiste el valor. Verificar en la DB.

8. **Endpoint medical-consent funciona:** un curl autenticado a `POST /users/me/medical-consent` con body `{ "consentVersion": "v1.0-2026-06" }` retorna 201 con `{ "medicalConsentAcceptedAt": "<timestamp>" }`. El campo se persistió en la DB.

9. **GET /users/me retorna medicalConsentAcceptedAt:** la respuesta incluye el campo (puede ser `null` si el usuario no consintió aún).

10. **NOT_SHARED_SENTINEL exportado:** el archivo `rideglory-contracts/src/events/dto/event-registration.dto.ts` (o un archivo hermano) exporta la constante `NOT_SHARED_SENTINEL = '__NOT_SHARED__'` y puede importarse desde `events-ms` y `users-ms` sin errores de compilación.

---

## Pruebas

### Obligatorias en esta fase

**Test de integración — events-ms:**
- `POST /events/:id/registrations` con todos los campos legales → 201 y persistencia correcta en DB.
- `POST /events/:id/registrations` sin `riskAcceptedAt` → 201 (la validación de negocio no va en esta fase; solo se confirma que el campo es opcional en el contrato).
- `GET /events/:id/registrations` → respuesta incluye los 4 campos nuevos con sus valores.

**Test de integración — users-ms / api-gateway:**
- `POST /users/me/medical-consent` autenticado → 201 con `medicalConsentAcceptedAt`.
- `POST /users/me/medical-consent` no autenticado → 401.
- `GET /users/me` → incluye `medicalConsentAcceptedAt` (puede ser `null`).

**Verificación de contratos:**
- `npm run build` en `rideglory-contracts` sin errores.
- TypeScript acepta `bloodType: BloodType | string` sin errores de tipo en los consumidores.

### Diferidas a fases posteriores

- Test unitario de `UNDERAGE_RIDER` → Fase 2.
- Test unitario de ofuscación condicional → Fase 2.
- Test unitario de `toJson()` con los 4 campos → Fase 3 (criterio C1 del auditor).
- Tests de UI de switches y waiver → Fases 4-6.

---

## Riesgos y mitigaciones

| # | Riesgo | Probabilidad | Impacto | Mitigación |
|---|--------|-------------|---------|-----------|
| R1 | `rideglory-contracts` como cuello de botella: PR tarda en mergearse y bloquea el plan completo | Alta | Bloquea Fases 1-7 | Priorizar como primera acción de la fase. Usar `npm link` local mientras el PR está en revisión para que `events-ms`, `users-ms` y `api-gateway` consuman la versión local sin esperar el merge. Documentar el workaround en el handoff. |
| R2 | Gotcha `npm run build` + `pnpm install` omitido → `MODULE_NOT_FOUND` en runtime | Media | MS no levanta; bloquea verificación end-to-end | Seguir el Paso 7 de forma estricta en el orden indicado. Si falla, verificar que `rideglory-contracts` esté en `dependencies` (no `devDependencies`) de cada MS. |
| R3 | `bloodType: BloodType \| string` rompe TypeScript en consumidores que esperan `BloodType` estricto | Media | Error de compilación en `events-ms` al mapear la respuesta | El mapper de `findByEvent` en `events-ms` debe asignar `bloodType` como `string` siempre en la respuesta; el tipo union en el contrato hace que TypeScript lo acepte. Revisar cualquier `switch/case` sobre `bloodType` en el MS y protegerlo con `Object.values(BloodType).includes(value)`. |
| R4 | Default retroactivo `shareMedicalInfo = false` para inscripciones históricas | Baja (sin usuarios reales) | En producción futura: organizadores perderían acceso médico de rodadas activas pre-migración | Documentar en el SQL de la migración. Aceptable sin usuarios reales. Con usuarios reales: revisar si un default temporal `true` + banner de acción requerida sería mejor UX. |
| R5 | El endpoint `POST /users/me/medical-consent` necesita resolver `userId` desde email | Baja | El gateway recibe el email del JWT pero users-ms necesita el id para el `UPDATE` | Opciones: (a) users-ms resuelve email→id internamente; (b) gateway hace dos llamadas TCP. Elegir (a) para minimizar latencia y mantener coherencia con `findUserByEmail`. Documentar en el handoff. |
| R6 | `sosTriggeredAt` ya existe pero no está confirmado en todos los entornos (local / staging / prod) | Baja | La Fase 2b falla si el campo no existe en staging | Agregar al pre-flight de Fase 2: `prisma migrate status` en todos los entornos confirmando que la migración con `sosTriggeredAt` fue aplicada. |

---

## Dependencias

**Fase 1 no tiene dependencias de otras fases** — es la fase raíz del plan. Todas las demás fases dependen de ella.

**Dependencias de Fase 1 hacia el exterior:**
- `rideglory-contracts` debe ser un submódulo con un PR abierto o mergeado antes de que los MS puedan usar los tipos nuevos. Si el PR tarda, usar `npm link` local.
- La base de datos de desarrollo debe ser accesible para ejecutar `prisma migrate dev`.
- Las credenciales de Prisma (`.env` de cada MS) deben estar configuradas en el entorno de desarrollo.

**Qué desbloquea esta fase:**
- Fase 2 (validación de edad y ofuscación) puede empezar tan pronto los campos existan en Prisma y los contratos compilen.
- Fase 3 (modelos Flutter) puede desarrollarse en paralelo con Fase 2, una vez los contratos estén disponibles.
- Fase 5 (responsabilidad del organizador) depende del campo `organizerAcceptedResponsibilityAt` en `Event` — disponible tras esta fase.
- Fase 6 (Ley 1581) depende del endpoint `POST /users/me/medical-consent` — disponible tras esta fase.

---

## Ejecucion recomendada (nivel rg-exec: full)

**Por qué full y no normal:**

1. **Migraciones en 2 microservicios distintos con lógica diferente:** `events-ms` (5 columnas en 2 tablas) y `users-ms` (1 columna + nuevo endpoint con lógica de TCP). Cada uno tiene su propio Prisma client, su propio `pnpm install` y sus propias dependencias de contratos. Un error en cualquiera bloquea la verificación end-to-end.

2. **PR en submódulo `rideglory-contracts` bloquea todo el plan:** si el PR se cierra mal (falta un export, un tipo incorrecto, un `npm run build` que no se ejecutó), todas las fases 2-7 no pueden avanzar. El nivel full asegura que el auditor Opus valide cada cambio en los contratos antes de dar el visto bueno.

3. **Campos PII con defaults retroactivos:** `shareMedicalInfo = false` y `allowOrganizerContact = false` como defaults en Prisma son seguros para el estado actual (sin usuarios reales), pero la decisión debe estar auditada explícitamente. El auditor Opus valida que los defaults no crean deuda de compliance futura.

4. **Edge case `riskAcceptedAt` nullable en DB pero obligatorio en negocio:** la distinción entre "nullable en el schema Prisma (para registros pre-migración)" y "rechazado con 422 en lógica de negocio para inscripciones nuevas" es sutil y fácil de implementar mal. Requiere que el contrato (`@IsOptional()`) y la documentación del handoff sean precisos para que la Fase 2 no introduzca un bug de seguridad.

5. **Alto blast radius:** cualquier error en los contratos o en las migraciones requiere una migración de rollback o un hotfix, lo que consume más tiempo que haberlo hecho bien en primer lugar. El nivel full justifica la inversión de tiempo del auditor en esta fase precisamente porque evita el costo de un rollback.
