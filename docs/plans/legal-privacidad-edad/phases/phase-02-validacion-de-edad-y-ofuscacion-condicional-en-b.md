# Fase 2 — Validación de edad y ofuscación condicional en backend

**Slug:** `legal-privacidad-edad`
**Fase id:** 2
**Timestamp:** 2026-06-19T19:58:07Z (rev: correcciones Auditor Opus — mock explícito de PrismaClient + config con envs; setup TC-Age-2/TC-Age-3)
**Nivel rg-exec:** full
**dependsOn:** [1]

---

## Objetivo

Garantizar que ningún menor de edad pueda inscribirse a un evento, y que el organizador solo vea datos médicos o PII de los riders cuando las reglas de privacidad lo permitan — todo a nivel de backend, en `events-ms`, sin que Flutter necesite lógica de ofuscación propia.

---

## Alcance (entra / no entra)

### Entra

- **Pre-flight gate:** verificar que `Event.sosTriggeredAt DateTime?` existe en `schema.prisma` de `events-ms`. Si no existe (Fase 1 no lo agregó), agregar la columna y generar la migración Prisma antes de cualquier código de la sub-tarea 2b. Bloqueo duro: no avanzar a 2b sin este campo confirmado en DB.
- **2a — Validación de edad en `RegistrationsService.create()`:** calcular edad desde `birthDate`; rechazar con `RpcException({ status: 422, message: 'UNDERAGE_RIDER' })` si el rider tiene menos de 18 años al momento de la inscripción.
- **2b — Ofuscación condicional en `RegistrationsService.findByEvent()`:** aplicar las 4 capas de ofuscación por campo con el centinela semántico acordado en Fase 1 (`"__NOT_SHARED__"` para datos médicos, `"••••"` para PII de contacto/identificación).
- **Tests unitarios** para ambas sub-tareas: casos límite de edad (2a) y cada capa de ofuscación (2b).
- Ajuste en el mapper de respuesta para que `bloodType` se asigne como `string` puro (no como enum `BloodType`) cuando está ofuscado.

### No entra

- Cambios en Flutter (Fases 3-7).
- Ofuscación en `findMyRegistrationForEvent` — ese endpoint es del rider sobre su propia inscripción; la ofuscación no aplica.
- Ofuscación en `findMyRegistrations` — vista propia del rider.
- Validación de `riskAcceptedAt` al crear inscripción (ya definida en Fase 1 como `422 RISK_NOT_ACCEPTED`).
- Validación de `organizerAcceptedResponsibilityAt` al publicar evento (Fase 1 y Fase 5).
- Cambios en `rideglory-contracts` (cerrados en Fase 1, incluyendo `bloodType: BloodType | string` en `EventRegistrationDto`).

---

## Que se debe hacer (pasos concretos y ordenados)

### Pre-flight — gate accionable antes de cualquier código

1. Abrir `events-ms/prisma/schema.prisma`.
2. Verificar que el modelo `Event` contiene la línea `sosTriggeredAt DateTime?`.
   - El scan (01-scan.md) confirma que `sosTriggeredAt` **ya existe** en la línea 77 del schema actual. Validar que siga ahí después de la migración de Fase 1.
   - Si Fase 1 lo borró o si no existe: agregar `sosTriggeredAt  DateTime?` al modelo `Event`, generar migración (`npx prisma migrate dev --name add_sos_triggered_at`), y ejecutar localmente antes de continuar.
3. Confirmar que los 4 campos de Fase 1 también existen en `EventRegistration`: `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`. Si Fase 1 está completa, ya estarán. Si no, **no avanzar**: este es el gate de la dependencia [1].

### Sub-tarea 2a — Validación de edad (abordar primero)

4. En `events-ms/src/registrations/registrations.service.ts`, en el método `create()`, agregar la validación de edad **inmediatamente después de `await this.ensureUserHasNoActiveRegistration(eventId, userId)`** y **antes de `this.ensureVehicleIdForNonOwner()`** (es decir, antes de la cadena de validaciones subsiguientes: `ensureVehicleIdForNonOwner`, `validateAllowedBrands`, `persistRiderProfile` y el bloque `registrationData`). El objetivo es fail-fast: detectar al rider menor antes de persistir su perfil (`persistRiderProfile`) o construir los datos de la inscripción.

   Referencia de la cadena actual en `create()` (flujo de control real al 2026-06-19):
   ```
   ensureEventExists()           → captura el evento
   [guard] ownerId === userId    → throw FORBIDDEN
   ensureUserHasNoActiveRegistration()
   ← INSERTAR AQUÍ la validación de edad →
   ensureVehicleIdForNonOwner()
   validateAllowedBrands()
   [if saveToProfile] persistRiderProfile()
   registrationData = { ... }
   eventRegistration.upsert(...)
   ```

   Código a insertar:
   ```typescript
   // Calcular edad del rider al momento de la inscripción
   const today = new Date();
   const birth = new Date(data.birthDate);
   const ageYears =
     today.getFullYear() - birth.getFullYear() -
     (today < new Date(today.getFullYear(), birth.getMonth(), birth.getDate()) ? 1 : 0);
   if (ageYears < 18) {
     throw new RpcException({
       status: 422,
       message: 'UNDERAGE_RIDER',
     });
   }
   ```

   La fórmula es precisa para el caso límite: 17 años 364 días = rechazado; 18 años exactos el día de hoy = aceptado.

   **Nota de coordinación cross-fase (A5):** El error se devuelve como `{ status: 422, message: 'UNDERAGE_RIDER' }`. Fase 4 (`RegistrationFormCubit`) debe mapear sobre el campo `message` (no sobre un hipotético campo `code`) para detectar este error y mostrar el mensaje l10n correcto. La síntesis (05-sintesis.md, sección A5) usó la expresión `code: 'UNDERAGE_RIDER'` en un contexto descriptivo, pero el codebase (observado en todos los `RpcException` de este servicio) usa `message` como portador del código semántico. **El implementador de Fase 4 debe leer sobre el campo `message`, no `code`.**

5. Crear archivo de tests: `events-ms/src/registrations/registrations.service.age-validation.spec.ts`.

   **Patrón de instanciación del servicio:** `RegistrationsService` recibe **dos** `ClientProxy` en su constructor (`usersService` y `vehiclesService`), a diferencia de `EventsService` (que recibe solo uno). El spec de `events.service.spec.ts` no es copiable tal cual — se deben proveer dos mocks independientes:

   ```typescript
   const mockUsersClientProxy = { send: jest.fn() };
   const mockVehiclesClientProxy = { send: jest.fn() };

   // Al instanciar manualmente:
   service = new RegistrationsService(
     mockUsersClientProxy as any,
     mockVehiclesClientProxy as any,
   );
   ```

   También se necesita mockear `config` con **todas** las exportaciones que el módulo real provee — `envs` incluido, porque otros imports del servicio (o sus dependencias transitivas) lo consumen:
   ```typescript
   jest.mock('../config', () => ({
     envs: {
       port: 3001,
       usersMsPort: 3002,
       usersMsHost: 'localhost',
       vehiclesMsPort: 3003,
       vehiclesMsHost: 'localhost',
     },
     USERS_SERVICE: 'USERS_SERVICE',
     VEHICLES_SERVICE: 'VEHICLES_SERVICE',
   }));
   ```

   El mock de `'../generated/prisma'` debe exponer exactamente los campos de instancia que `RegistrationsService` (que extiende `PrismaClient`) usa en sus métodos. Seguir el patrón de `events.service.spec.ts` (campos de instancia en la clase, no `jest.spyOn`):

   ```typescript
   const mockEventFindUnique = jest.fn();
   const mockRegistrationFindFirst = jest.fn();
   const mockRegistrationFindMany = jest.fn();
   const mockRegistrationUpsert = jest.fn();
   const mockRegistrationUpdate = jest.fn();
   const mockConnect = jest.fn().mockResolvedValue(undefined);

   jest.mock('../generated/prisma', () => ({
     PrismaClient: class {
       event = { findUnique: mockEventFindUnique };
       eventRegistration = {
         findFirst: mockRegistrationFindFirst,
         findMany: mockRegistrationFindMany,
         upsert: mockRegistrationUpsert,
         update: mockRegistrationUpdate,
       };
       $connect = mockConnect;
     },
   }));
   ```

   **Setup compartido en `beforeEach`:**
   - `mockEventFindUnique` retorna un evento válido con `ownerId: 'owner-id'` (distinto del `userId` de prueba `'user-id'`), `allowedBrands: []` (lista vacía — `validateAllowedBrands` acepta cualquier marca cuando la lista está vacía o contiene solo `'*'`).
   - `mockRegistrationFindFirst` retorna `null` (sin inscripción activa previa, para pasar `ensureUserHasNoActiveRegistration`).
   - `mockRegistrationUpsert` retorna un objeto inscription mínimo con `vehicleId: null`.
   - `mockVehiclesClientProxy.send` configurado en `beforeEach` para retornar un observable observable que resuelve a un vehículo (`{ id: 'v-1', brand: 'Honda' }`) o a `null` según el test.

   **TC-Age-1 (criterio unitario):** `birthDate` = 17 años y 364 días antes de hoy → `RegistrationsService.create()` lanza `RpcException` con `status: 422` y `message: 'UNDERAGE_RIDER'`. Para este caso el payload no necesita `vehicleId` — la excepción se lanza antes de `ensureVehicleIdForNonOwner` (ver orden del paso 4).

   **TC-Age-2 (criterio unitario):** `birthDate` = exactamente 18 años antes de hoy (cumpleaños hoy) → `create()` **no** lanza excepción; retorna la inscripción. Para que la ejecución llegue hasta `upsert` sin errores previos, el payload debe incluir un `vehicleId: 'v-1'` válido, y el evento mockeado por `mockEventFindUnique` debe tener `allowedBrands: []` (lista vacía acepta cualquier marca). `mockVehiclesClientProxy.send` debe retornar un observable que resuelve a `{ id: 'v-1', brand: 'Honda' }`. El `ownerId` del evento (`'owner-id'`) debe ser distinto del `userId` de prueba (`'user-id'`) para no caer en el guard `OWNER_CANNOT_REGISTER_MANUALLY`.

   **TC-Age-3 (criterio unitario):** `birthDate` = 25 años antes de hoy → `create()` **no** lanza excepción. Mismos mocks que TC-Age-2 (payload con `vehicleId: 'v-1'`, `allowedBrands: []`, `ownerId` distinto).

   **TC-Age-4:** `birthDate` inválida o `undefined` → documentar el comportamiento actual. Si `birthDate` es campo requerido y validado en `CreateRegistrationDto` por class-validator, este caso no puede ocurrir en runtime en events-ms (la validación ocurre en api-gateway antes). Documentarlo como nota en el test (`it.todo` o `it.skip` con explicación), no como test de comportamiento indefinido.

### Sub-tarea 2b — Ofuscación condicional en `findByEvent` (abordar segundo, después de 2a)

6. Modificar `RegistrationsService.findByEvent()` para capturar el retorno de `ensureEventExists()`.

   **Estado actual del código (línea 202-211 del servicio al 2026-06-19):**
   ```typescript
   async findByEvent(eventId: string) {
     await this.ensureEventExists(eventId);  // ← retorno descartado

     const registrations = await this.eventRegistration.findMany({
       where: { eventId },
       orderBy: { createdAt: 'asc' },
     });

     return this.enrichRegistrationsWithVehicle(registrations);
   }
   ```

   **Cambio requerido:** cambiar `await this.ensureEventExists(eventId)` (retorno descartado) por `const event = await this.ensureEventExists(eventId)` para capturar `event.state` y `event.sosTriggeredAt`. Sin este cambio, la ofuscación no tiene acceso al estado del evento.

   ```typescript
   async findByEvent(eventId: string) {
     const event = await this.ensureEventExists(eventId);  // ← capturar retorno

     const registrations = await this.eventRegistration.findMany({
       where: { eventId },
       orderBy: { createdAt: 'asc' },
     });

     const enriched = await this.enrichRegistrationsWithVehicle(registrations);
     return enriched.map((r) => this.applyPrivacyMask(r, event));
   }
   ```

7. Extraer la lógica de ofuscación a un método privado `applyPrivacyMask(registration, event)` en `RegistrationsService`.

   **Orden de operaciones respecto a `enrichRegistrationsWithVehicle`:** aplicar `applyPrivacyMask` **después** del spread de `vehicleSummary`. Razón: `enrichRegistrationsWithVehicle` agrega el campo `vehicleSummary` al objeto registration via spread (`{ ...registration, vehicleSummary }`). Si se aplica `applyPrivacyMask` antes, el objeto aún no tiene `vehicleSummary` y se pierde ese campo en el retorno. El orden correcto es: Prisma records → `enrichRegistrationsWithVehicle` → `applyPrivacyMask` por cada registro enriquecido.

   **Hoy no existe ningún mapper entre Prisma y la respuesta:** `findByEvent` retorna los registros Prisma crudos directamente (pasados a través de `enrichRegistrationsWithVehicle` que solo añade `vehicleSummary`). No hay una clase mapper ni una función de transformación existente. `applyPrivacyMask` es el primer y único punto de transformación de campos para la vista del organizador.

   Tabla de reglas (centinelas fijados en Fase 1):

   | Campo(s) | Condición para mostrar valor real | Centinela si ofuscado |
   |---|---|---|
   | `eps`, `medicalInsurance`, `bloodType` | `event.state === 'IN_PROGRESS' && registration.shareMedicalInfo === true` | `"__NOT_SHARED__"` |
   | `emergencyContactName`, `emergencyContactPhone` | `event.state === 'IN_PROGRESS'` | `"••••"` |
   | `phone` | `registration.allowOrganizerContact === true` | `"••••"` |
   | `identificationNumber`, `email`, `residenceCity` | `event.sosTriggeredAt !== null` (SOS activo) | `"••••"` |

   Implementación del método privado:

   ```typescript
   private applyPrivacyMask<T extends {
     shareMedicalInfo: boolean;
     allowOrganizerContact: boolean;
     eps: string;
     medicalInsurance: string | null;
     bloodType: string;
     emergencyContactName: string;
     emergencyContactPhone: string;
     phone: string;
     identificationNumber: string;
     email: string;
     residenceCity: string;
   }>(
     registration: T,
     event: { state: string; sosTriggeredAt: Date | null },
   ): T {
     const showMedical =
       event.state === 'IN_PROGRESS' && registration.shareMedicalInfo === true;
     const showEmergency = event.state === 'IN_PROGRESS';
     const showPhone = registration.allowOrganizerContact === true;
     const showPii = event.sosTriggeredAt !== null;

     return {
       ...registration,
       eps: showMedical ? registration.eps : '__NOT_SHARED__',
       medicalInsurance: showMedical ? registration.medicalInsurance : '__NOT_SHARED__',
       bloodType: showMedical ? (registration.bloodType as string) : '__NOT_SHARED__',
       emergencyContactName: showEmergency ? registration.emergencyContactName : '••••',
       emergencyContactPhone: showEmergency ? registration.emergencyContactPhone : '••••',
       phone: showPhone ? registration.phone : '••••',
       identificationNumber: showPii ? registration.identificationNumber : '••••',
       email: showPii ? registration.email : '••••',
       residenceCity: showPii ? registration.residenceCity : '••••',
     };
   }
   ```

   **Nota sobre `bloodType`:** el tipo Prisma es `BloodType` (enum). En `applyPrivacyMask`, declarar el campo de entrada como `bloodType: string` (no como `BloodType`) para permitir la asignación del centinela sin cast adicional en cada rama. El contrato de Fase 1 ya declara `bloodType: BloodType | string` en `EventRegistrationDto`, por lo que el tipo de retorno es compatible.

   **Nota sobre `medicalInsurance`:** es `String?` en Prisma (campo opcional). En modo real: pasar el valor tal cual (puede ser `null`); en modo ofuscado: pasar `"__NOT_SHARED__"` (string, nunca `null`).

8. Crear archivo de tests: `events-ms/src/registrations/registrations.service.privacy-mask.spec.ts`.

   **Patrón de instanciación del servicio:** igual que en el paso 5 — dos `ClientProxy` mock (`mockUsersClientProxy` y `mockVehiclesClientProxy`). Reusar el mismo bloque de `jest.mock('../generated/prisma')` con todos los campos de instancia (`event`, `eventRegistration`, `$connect`) y el mismo `jest.mock('../config')` con `envs` + `USERS_SERVICE` + `VEHICLES_SERVICE`. Definir las mismas funciones `mockEventFindUnique`, `mockRegistrationFindMany` (y las demás aunque no se usen en estos tests) para que el constructor de `RegistrationsService` no falle al inicializar.

   - `mockEventFindUnique` retorna el evento con los valores apropiados de `state` y `sosTriggeredAt` según cada test case.
   - `mockRegistrationFindMany` retorna una lista con 1 inscripción con todos los campos rellenos (valores reales del rider), incluyendo `shareMedicalInfo` y `allowOrganizerContact` según el test case.
   - `mockVehiclesClientProxy.send` retornando un observable que resuelve a `null` (sin vehículo para simplificar — `vehicleSummary: null`). Esto evita la llamada real a `vehicles-ms` y simplifica el setup de cada caso.

   **TC-Privacy-1 — Evento no iniciado, sin SOS:**
   - `event.state = 'SCHEDULED'`, `event.sosTriggeredAt = null`
   - `registration.shareMedicalInfo = true`, `registration.allowOrganizerContact = true`
   - Resultado esperado: `eps = "__NOT_SHARED__"`, `medicalInsurance = "__NOT_SHARED__"`, `bloodType = "__NOT_SHARED__"`, `emergencyContactName = "••••"`, `emergencyContactPhone = "••••"`, `phone = valor_real`, `identificationNumber = "••••"`, `email = "••••"`, `residenceCity = "••••"`.
   - Nota: médicos ofuscados porque `state !== IN_PROGRESS`. Emergencia ofuscada por la misma razón. Teléfono real porque `allowOrganizerContact = true`. PII ofuscada porque `sosTriggeredAt = null`.

   **TC-Privacy-2 — Evento en curso, sin consentimiento médico:**
   - `event.state = 'IN_PROGRESS'`, `event.sosTriggeredAt = null`
   - `registration.shareMedicalInfo = false`, `registration.allowOrganizerContact = false`
   - Resultado esperado: `eps = "__NOT_SHARED__"`, `bloodType = "__NOT_SHARED__"`, `medicalInsurance = "__NOT_SHARED__"`, `emergencyContactName = valor_real`, `emergencyContactPhone = valor_real`, `phone = "••••"`, `identificationNumber = "••••"`, `email = "••••"`, `residenceCity = "••••"`.

   **TC-Privacy-3 — Evento en curso, con consentimiento médico:**
   - `event.state = 'IN_PROGRESS'`, `event.sosTriggeredAt = null`
   - `registration.shareMedicalInfo = true`, `registration.allowOrganizerContact = true`
   - Resultado esperado: todos los campos médicos y de emergencia muestran valor real. Teléfono real. PII sigue ofuscada (`sosTriggeredAt = null`).

   **TC-Privacy-4 — SOS activo:**
   - `event.state = 'IN_PROGRESS'`, `event.sosTriggeredAt = new Date()`
   - `registration.shareMedicalInfo = false`, `registration.allowOrganizerContact = false`
   - Resultado esperado: PII completa visible (`identificationNumber`, `email`, `residenceCity` = valores reales). Médicos ofuscados (`shareMedicalInfo = false`). Contacto emergencia visible (`IN_PROGRESS`). Teléfono ofuscado (`allowOrganizerContact = false`).

   **TC-Privacy-5 — Máximo acceso (SOS + IN_PROGRESS + todos los consentimientos):**
   - `event.state = 'IN_PROGRESS'`, `event.sosTriggeredAt = new Date()`
   - `registration.shareMedicalInfo = true`, `registration.allowOrganizerContact = true`
   - Resultado esperado: todos los campos retornan valores reales del rider.

9. Ejecutar los tests: `cd events-ms && npx jest registrations.service.age-validation registrations.service.privacy-mask --no-coverage`.

10. Ejecutar `npx tsc --noEmit` en `events-ms` para confirmar tipado correcto, especialmente el campo `bloodType: string` en el mapper.

---

## Archivos a crear/modificar (rutas reales)

| Acción | Ruta | Qué cambia |
|---|---|---|
| **Modificar** | `events-ms/prisma/schema.prisma` | Solo si `sosTriggeredAt` no existe tras Fase 1: agregar `sosTriggeredAt DateTime?` al modelo `Event`. |
| **Crear migración** | `events-ms/prisma/migrations/20260619000000_add_sos_triggered_at/migration.sql` | Solo si el campo no existía. Contenido: `ALTER TABLE "Event" ADD COLUMN "sosTriggeredAt" TIMESTAMP(3);` |
| **Modificar** | `events-ms/src/registrations/registrations.service.ts` | (1) Validación de edad en `create()` inmediatamente después de `ensureUserHasNoActiveRegistration()`. (2) Capturar retorno de `ensureEventExists()` en `findByEvent()` (`const event = await …`). (3) Aplicar `applyPrivacyMask()` a cada registro enriquecido antes de retornar. (4) Nuevo método privado `applyPrivacyMask(registration, event)`. |
| **Crear** | `events-ms/src/registrations/registrations.service.age-validation.spec.ts` | Tests unitarios de los 4 casos límite de validación de edad, instanciando `RegistrationsService` con dos mocks de `ClientProxy`. |
| **Crear** | `events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` | Tests unitarios de las 5 combinaciones de ofuscación por capa, instanciando `RegistrationsService` con dos mocks de `ClientProxy`. |

---

## Contratos / API rideglory-api

Los contratos se cerraron en Fase 1. Esta fase no modifica `rideglory-contracts`. Los cambios relevantes que Fase 1 ya aplicó y que esta fase consume:

- `EventRegistrationDto` en contratos: `bloodType: BloodType | string` (permite retornar el centinela).
- `EventRegistrationDto` en contratos: campos `shareMedicalInfo: boolean`, `allowOrganizerContact: boolean`, `riskAcceptedAt: Date | null`, `riskAcceptanceVersion: string | null` ya presentes.
- `CreateRegistrationDto`: `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion` ya definidos.

Si Fase 1 no cerró estos contratos, esta fase no puede implementarse. Bloqueo duro.

**Recordatorio de gotcha (`project_contracts_rebuild_gotcha.md`):** si en Fase 1 se modificaron los contratos, verificar que `npm run build` se ejecutó en `rideglory-contracts` y `pnpm install` en `events-ms` antes de desarrollar esta fase. Si el build falla con `MODULE_NOT_FOUND`, re-ejecutar esos dos comandos.

---

## Cambios de datos / migraciones

### Caso A: `sosTriggeredAt` ya existe (confirmado en scan actual — línea 77 de schema.prisma)

Si Fase 1 no tocó este campo, **ninguna migración adicional** en esta fase.

### Caso B: `sosTriggeredAt` fue eliminado accidentalmente o no existe

Crear migración manual:

```
events-ms/prisma/migrations/20260619000000_add_sos_triggered_at/migration.sql
```

```sql
-- AlterTable
ALTER TABLE "Event" ADD COLUMN "sosTriggeredAt" TIMESTAMP(3);
```

Ejecutar: `cd events-ms && npx prisma migrate dev --name add_sos_triggered_at`

**Importante:** Los campos `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion` en `EventRegistration` fueron migrados en Fase 1. Esta fase solo los lee — no los migra.

---

## Criterios de aceptacion (numerados, observables, testeables)

Los criterios 1 y 2 son **criterios unitarios** verificables por los tests del paso 5. Los criterios 3-11 son verificables tanto por los tests unitarios del paso 8 como por pruebas de integración manuales.

1. **(Unitario)** `RegistrationsService.create()` lanza `RpcException` con `status: 422` y `message: 'UNDERAGE_RIDER'` cuando `birthDate` corresponde a 17 años 364 días antes de hoy.
2. **(Unitario)** `RegistrationsService.create()` retorna la inscripción sin lanzar excepción cuando `birthDate` corresponde a exactamente 18 años antes de hoy (cumpleaños hoy).
3. Un `GET /events/:eventId/registrations` con evento en estado `SCHEDULED` retorna los campos `eps`, `medicalInsurance`, `bloodType` con valor `"__NOT_SHARED__"`, independientemente de `shareMedicalInfo`.
4. Un `GET /events/:eventId/registrations` con evento en `IN_PROGRESS` y `registration.shareMedicalInfo = true` retorna `eps`, `bloodType` con valores reales del rider.
5. Un `GET /events/:eventId/registrations` con evento en `IN_PROGRESS` y `registration.shareMedicalInfo = false` retorna `eps`, `bloodType` con valor `"__NOT_SHARED__"`.
6. Un `GET /events/:eventId/registrations` con `registration.allowOrganizerContact = false` retorna `phone` con valor `"••••"`.
7. Un `GET /events/:eventId/registrations` con `registration.allowOrganizerContact = true` retorna `phone` con el número real del rider.
8. Un `GET /events/:eventId/registrations` con `event.sosTriggeredAt = null` retorna `identificationNumber`, `email`, `residenceCity` con valor `"••••"`.
9. Un `GET /events/:eventId/registrations` con `event.sosTriggeredAt` distinto de `null` retorna `identificationNumber`, `email`, `residenceCity` con valores reales.
10. El campo `bloodType` nunca lanza excepción de tipado TypeScript en el mapper cuando retorna `"__NOT_SHARED__"` (verificado con `npx tsc --noEmit`).
11. `GET /events/:eventId/registrations/me` (endpoint del rider) NO aplica ofuscación — retorna todos los campos con valores reales del rider sobre su propia inscripción.
12. Todos los tests unitarios pasan: `npx jest registrations.service.age-validation registrations.service.privacy-mask` → 0 failures.

---

## Pruebas

### Unitarias (obligatorias)

**Archivo:** `events-ms/src/registrations/registrations.service.age-validation.spec.ts`

- `jest.mock('../generated/prisma')` con `PrismaClient` como clase con campos de instancia: `event = { findUnique: mockEventFindUnique }`, `eventRegistration = { findFirst: mockRegistrationFindFirst, findMany: mockRegistrationFindMany, upsert: mockRegistrationUpsert, update: mockRegistrationUpdate }`, `$connect = mockConnect`.
- `jest.mock('../config')` exportando `{ envs: { port, usersMsPort, usersMsHost, vehiclesMsPort, vehiclesMsHost }, USERS_SERVICE: 'USERS_SERVICE', VEHICLES_SERVICE: 'VEHICLES_SERVICE' }` — `envs` es obligatorio para evitar errores de módulo en imports transitivos.
- `jest.mock('@prisma/adapter-pg')` siguiendo el patrón de `events.service.spec.ts`.
- `RegistrationsService` instanciado manualmente con **dos** `ClientProxy` mock (`mockUsersClientProxy`, `mockVehiclesClientProxy`).
- Setup en `beforeEach`: evento con `ownerId: 'owner-id'` y `allowedBrands: []`, `mockRegistrationFindFirst` retorna `null`, `mockRegistrationUpsert` retorna un objeto mínimo.
- TC-Age-2 y TC-Age-3 incluyen `vehicleId: 'v-1'` en el payload y `mockVehiclesClientProxy.send` retorna observable con `{ id: 'v-1', brand: 'Honda' }`.
- Cuatro test cases (TC-Age-1 a TC-Age-4) descritos en el paso 5.
- No requiere base de datos real.

**Archivo:** `events-ms/src/registrations/registrations.service.privacy-mask.spec.ts`

- Mismos `jest.mock` que el spec de age-validation: `'../generated/prisma'`, `'../config'` (con `envs`), `'@prisma/adapter-pg'`.
- `RegistrationsService` instanciado manualmente con **dos** `ClientProxy` mock.
- `mockVehiclesClientProxy.send` retorna observable que resuelve a `null` (simplifica setup — `vehicleSummary: null`).
- Cinco test cases (TC-Privacy-1 a TC-Privacy-5) descritos en el paso 8.
- No requiere base de datos real.

### Integración / manual (opcional pero recomendado)

- Con el backend levantado localmente, usar `curl` o Thunder Client para:
  - Crear un rider menor de 18 y verificar `422 UNDERAGE_RIDER`.
  - Como organizador, obtener `GET /events/:id/registrations` en cada estado del evento y verificar los centinelas esperados.
- Este nivel de prueba no es bloqueante para cerrar la fase, pero es recomendable antes del PR.

### No aplica

- Tests de widgets Flutter (Fases 4 y 7).
- Tests de integración E2E (fuera del scope de esta fase).

---

## Riesgos y mitigaciones

| # | Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|---|
| R1 | `bloodType` como enum en el mapper genera error de TypeScript al asignar `"__NOT_SHARED__"` | Alta | Build falla en CI | Declarar `bloodType` como `string` en la firma genérica de `applyPrivacyMask`. Verificar con `npx tsc --noEmit`. El contrato de Fase 1 ya declara `bloodType: BloodType \| string`. |
| R2 | `medicalInsurance` es nullable en Prisma; el centinela lo convierte en string | Media | Flutter recibe `"__NOT_SHARED__"` donde esperaba `null`, posible UI break | Aceptable — Flutter (Fase 3) implementa getter de parse seguro para `bloodType?` y renderiza el string crudo si no parsea como enum. Para `medicalInsurance`, la UI mostrará `"__NOT_SHARED__"` si está ofuscado. Coordinar con Fase 7. |
| R3 | Tests fallan porque el mock de `RegistrationsService` se instancia solo con un `ClientProxy` (copiando `events.service.spec.ts` sin adaptar) | Alta | Tests no compilan o el constructor lanza error de DI | El paso 5 detalla explícitamente los dos mocks requeridos y el mock del módulo `config`. No copiar el spec de `events.service.spec.ts` sin adaptar. |
| R4 | `ensureEventExists()` en `findByEvent()` — retorno descartado actualmente; el cambio a `const event = await ...` puede generar lint warnings si el objeto tiene campos extra | Baja | Warning `no-unused-vars` | El objeto `event` se usa inmediatamente en `applyPrivacyMask`. No hay campo sin usar. |
| R5 | `applyPrivacyMask` aplicado antes de `enrichRegistrationsWithVehicle` — el campo `vehicleSummary` desaparece del retorno | Media | El organizador no ve el resumen del vehículo del rider | Orden correcto documentado en el paso 7: enriquecer primero con `vehicleSummary`, luego aplicar `applyPrivacyMask`. Verificar con TC-Privacy-1 que `vehicleSummary` sigue presente en el resultado. |
| R6 | Campos de Fase 1 (`shareMedicalInfo`, etc.) no existen en `EventRegistration` Prisma porque Fase 1 no se completó | Alta (bloqueante) | Sub-tarea 2b no puede implementarse correctamente | Gate de pre-flight: verificar existencia antes de escribir código. Detener y comunicar al PO si los campos no están. |

---

## Dependencias (fases prerequisito y por que)

### Fase 1 (bloqueante dura)

La Fase 2 depende de Fase 1 por tres razones:

1. **Campos de Prisma:** `EventRegistration.shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion` deben existir en la base de datos para que la lógica de ofuscación pueda leerlos. Sin la migración de Fase 1, Prisma no conoce estos campos y cualquier acceso a ellos devuelve `undefined`.

2. **Contratos TypeScript:** `EventRegistrationDto` en `rideglory-contracts` debe declarar `bloodType: BloodType | string` y los 4 campos nuevos. Sin esto, el mapper de `findByEvent()` no puede asignar strings ofuscados sin errores de compilación.

3. **Centinela semántico acordado:** Fase 1 fija el contrato `"__NOT_SHARED__"` (médicos) y `"••••"` (PII/contacto). La ofuscación de Fase 2 usa estos valores literales. Si Fase 1 no cerró la decisión, existe riesgo de inconsistencia con Flutter y otros consumidores del API.

---

## Ejecucion recomendada (nivel rg-exec: full)

**Nivel:** `full`

**Por que ese nivel:** Esta fase concentra la lógica de seguridad y privacidad más sensible de todo el plan. La justificación por sub-componente:

- **Lógica de seguridad central (UNDERAGE_RIDER):** Un error en la fórmula de edad (especialmente en los casos límite de cumpleaños exacto o año bisiesto) permite que menores se inscriban. El auditor Opus debe verificar explícitamente la fórmula de cálculo y los casos límite.

- **Ofuscación PII por capas:** Cuatro capas independientes con condiciones booleanas que se pueden mezclar incorrectamente. Un error en la precedencia de condiciones (ej: verificar `IN_PROGRESS` antes de `shareMedicalInfo` vs al revés) puede exponer datos médicos cuando no debería, o retener datos de emergencia cuando son críticos para la seguridad del rider durante una rodada. Cada combinación debe auditarse.

- **Edge case del enum `BloodType`:** La asignación de un string literal donde TypeScript espera un enum puede silenciarse localmente (cast `as string`) pero romper en runtime si el tipo de retorno no fue actualizado correctamente en el contrato. El auditor debe confirmar que `npx tsc --noEmit` pasa sin errores antes de aprobar.

- **Tests unitarios obligatorios por capa:** 9 test cases (4 de edad + 5 de ofuscación) que el auditor debe ejecutar y verificar que todos pasan. Nivel `normal` no garantiza que el auditor ejecute los tests; nivel `full` lo hace obligatorio.

- **Cross-cutting en events-ms:** Los cambios tocan el servicio más crítico del microservicio (`RegistrationsService`), que también maneja aprobaciones, cancelaciones y validaciones de marca de vehículo. Una regresión puede romper flujos de inscripción completos. El auditor Opus itera con el implementador hasta que los tests cubren todos los casos sin regresiones.

La complejidad acumulada de las dos sub-tareas secuenciales (2a luego 2b), los edge cases de tipos, y la obligatoriedad de tests por cada capa de ofuscación justifican `full` sobre `normal`.
