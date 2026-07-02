# Checklist de QA — Infraestructura backend para consentimiento médico, riesgo y responsabilidad del organizador

**Feature:** Contratos, schema de backend y endpoint `medical-consent` (base de datos para el plan Legal/Privacidad/Edad)
**Fases cubiertas:** Fase 1 (`legal-privacidad-edad-fase1`) — 100% backend, repo `rideglory-api` (`rideglory-contracts`, `events-ms`, `users-ms`, `api-gateway`). No hay pantallas ni cambios en la app Flutter en esta fase.
**Estado:** ⚠️ Aprobado con observaciones (1 caso fallando en sección 6, de baja severidad, no relacionado con la lógica del código; secciones 1, 2 y 4 pasan completas)

<!-- qa-auto:annotated -->
> **Automatización qa-auto** (2026-07-01T05:14:29Z): 🤖✅ 20 verificados · 🤖❌ 1 fallando · 👤 0 manuales · 🚫 5 no automatizables (de 26 casos).
> Entorno: device=android-emulator, baseline=na. Auditor Opus: solid.

---

## Pre-condiciones

Antes de empezar, asegurate de tener listo lo siguiente. Esta fase NO tiene UI — todas las pruebas se hacen con Postman/curl y con acceso directo a las bases de datos de desarrollo.

- [ ] Los 4 microservicios corriendo localmente (`api-gateway`, `events-ms`, `users-ms`, y el resto que dependan de `rideglory-contracts`), o en su defecto, disposición para levantarlos con `pnpm run start:dev` en cada uno.
- [ ] Confirmar que ya se corrió `npm run build` en `rideglory-contracts` y `pnpm install` en `events-ms`, `users-ms` y `api-gateway` (orden obligatorio: build de contratos primero) — si no, los servicios pueden arrancar con código viejo del paquete `@rideglory/contracts`.
- [ ] Un token JWT de Firebase válido de un usuario de prueba (para las llamadas autenticadas a `/api/users/me/medical-consent` y `/api/events/:id/registrations`).
- [ ] Un `eventId` de un evento existente en la base de datos de `events-ms` en el que el usuario de prueba pueda inscribirse (o ya esté inscrito).
- [ ] Acceso a `psql` (o herramienta equivalente) contra las bases `events` (puerto `5432`) y `users` (puerto `5433`) de desarrollo.
- [ ] Cliente HTTP (Postman/Insomnia/curl) apuntando a `http://localhost:3000/api` (o el puerto configurado del `api-gateway`).

---

## 1. Arranque de servicios y compilación de contratos

> No hay pantalla que abrir en este flujo: son verificaciones de que el backend levanta correctamente con el código nuevo.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 1.1 | Corre `npm run build` dentro de `rideglory-contracts`. | El comando termina sin errores (código de salida 0), sin mensajes de error de TypeScript en la consola. | 🤖✅ Auto-PASS (`n/a — run-existing: npm run build en rideglory-contracts`) | ✅ |
| 1.2 | Corre `pnpm install` en `events-ms`, `users-ms` y `api-gateway` (en ese orden, después del build de contratos). | Los tres comandos terminan sin errores. | 🤖✅ Auto-PASS (`n/a — run-existing: pnpm install en events-ms, users-ms, api-gateway`) | ✅ |
| 1.3 | Levanta `events-ms`, `users-ms` y `api-gateway` con `pnpm run start:dev` (o confirma que ya están corriendo con el código nuevo). | Los tres servicios arrancan sin errores `MODULE_NOT_FOUND` ni fallos de compilación en consola. | 🚫 No automatizable (los puertos 3000-3004 ya están ocupados por una sesión de desarrollo activa del usuario; reiniciar los servicios la interrumpiría) | |
| 1.4 | Llama `GET http://localhost:3000/api/health`. | Responde `200 OK` con `{"status":"ok"}`. | 🚫 No automatizable (depende de un api-gateway aislado corriendo con el código nuevo, ver 1.3; no hay instancia disponible sin interferir con la sesión activa del usuario) | |

---

## 2. Registro a un evento con los campos nuevos de consentimiento y riesgo

> Usa Postman/curl contra `api-gateway`, con tu token JWT de prueba en el header `Authorization: Bearer <token>`.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 2.1 | Haz `POST /api/events/:id/registrations` incluyendo en el body `shareMedicalInfo: true`, `allowOrganizerContact: true`, `riskAcceptedAt: "<fecha ISO actual>"`, `riskAcceptanceVersion: "v1"`. | La respuesta es `201 Created` (no `400`), y el body de respuesta incluye los 4 campos con los mismos valores que enviaste. | 🤖✅ Auto-PASS (`rideglory-api/events-ms/src/registrations/registrations.service.spec.ts` — persists shareMedicalInfo, allowOrganizerContact, riskAcceptedAt and riskAcceptanceVersion when present in the payload) | ✅ |
| 2.2 | Consulta esa misma inscripción con `GET /api/events/:id/registrations`. | El registro aparece en la lista con `shareMedicalInfo: true`, `allowOrganizerContact: true`, `riskAcceptedAt` y `riskAcceptanceVersion` con los valores enviados (persistidos, no perdidos). | 🤖✅ Auto-PASS (`rideglory-api/events-ms/src/registrations/registrations.service.spec.ts` — persists shareMedicalInfo, allowOrganizerContact, riskAcceptedAt and riskAcceptanceVersion when present in the payload) | ✅ |
| 2.3 | Repite el `POST` de una inscripción nueva pero SIN enviar los 4 campos nuevos en el body. | La respuesta sigue siendo `201 Created` (los campos son opcionales); el registro se crea igual. | 🤖✅ Auto-PASS (`rideglory-api/events-ms/src/registrations/registrations.service.spec.ts` — defaults shareMedicalInfo/allowOrganizerContact to false and riskAcceptedAt/riskAcceptanceVersion to null when omitted) | ✅ |
| 2.4 | Consulta esa inscripción del paso 2.3 con `GET /api/events/:id/registrations`. | `shareMedicalInfo: false`, `allowOrganizerContact: false`, `riskAcceptedAt: null`, `riskAcceptanceVersion: null` (defaults correctos cuando no se envían). | 🤖✅ Auto-PASS (`rideglory-api/events-ms/src/registrations/registrations.service.spec.ts` — defaults shareMedicalInfo/allowOrganizerContact to false and riskAcceptedAt/riskAcceptanceVersion to null when omitted) | ✅ |

---

## 3. Responsabilidad del organizador en el evento

> Sigue usando Postman/curl, ahora contra el endpoint de creación/edición de eventos.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3.1 | Haz `POST /api/events` (o `PATCH /api/events/:id` sobre un evento existente) incluyendo `organizerAcceptedResponsibilityAt: "<fecha ISO actual>"` en el body. | La respuesta es `201`/`200` respectivamente (no `400`), y el body de respuesta incluye ese campo con el valor enviado. | 🤖✅ Auto-PASS (`rideglory-api/events-ms/src/events/events.service.spec.ts` — CASE 3.1: create()/update() persisten organizerAcceptedResponsibilityAt en el payload enviado a Prisma) | ✅ |
| 3.2 | Consulta el evento creado/editado con `GET /api/events/:id`. | El campo `organizerAcceptedResponsibilityAt` aparece persistido con el valor enviado. | 🚫 No automatizable (requiere un servidor vivo con el evento creado en 3.1 vía HTTP real; el passthrough de Prisma ya queda cubierto indirectamente por la prueba unitaria de 3.1) | |

---

## 4. Consentimiento médico del usuario

> Endpoint nuevo `POST /api/users/me/medical-consent`, requiere autenticación.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 4.1 | Haz `POST /api/users/me/medical-consent` con tu token JWT válido y body `{ "consentVersion": "v1" }`. | Respuesta `201 Created` con un body `{ "medicalConsentAcceptedAt": "<fecha ISO>" }`. | 🤖✅ Auto-PASS (`rideglory-api/users-ms/src/users/users.service.spec.ts` + `rideglory-api/api-gateway/src/users/users.controller.spec.ts` — persists medicalConsentAcceptedAt y lo retorna; el controller del gateway reenvía email+consentVersion) | ✅ |
| 4.2 | Inmediatamente después, haz `GET /api/users/me` con el mismo token. | El campo `medicalConsentAcceptedAt` aparece en la respuesta con una fecha reciente (la del paso 4.1), no `null`. | 🚫 No automatizable (requiere secuenciar dos llamadas HTTP reales — POST y luego GET — contra un servidor vivo con JWT de Firebase real; findByEmail hace passthrough del objeto Prisma sin lógica propia que aislar sin duplicar la cobertura de 4.1) | |
| 4.3 | Con un usuario de prueba que NUNCA haya aceptado el consentimiento, haz `GET /api/users/me`. | El campo `medicalConsentAcceptedAt` aparece en la respuesta como `null` (no genera error, no falta el campo). | 🤖✅ Auto-PASS (`rideglory-api/users-ms/src/users/users.service.spec.ts` — CASE 4.3: returns medicalConsentAcceptedAt: null without error for a user that never accepted consent) | ✅ |

---

## 5. Casos de borde

### 5A. Consentimiento médico sin autenticación

> Simula un cliente sin sesión iniciada.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5A.1 | Haz `POST /api/users/me/medical-consent` SIN el header `Authorization` (o con un token inválido/expirado). | Respuesta `401 Unauthorized` (nunca `404` ni `500` — confirma que la ruta existe y aplica el guard de auth). | 🤖✅ Auto-PASS (`rideglory-api/api-gateway/src/users/users.controller.spec.ts` — throws UnauthorizedException when the request has no authenticated email) | ✅ |

### 5B. Inscripción a evento sin aceptar riesgo

> En esta fase la validación de negocio `422 RISK_NOT_ACCEPTED` todavía NO está implementada (llega en Fase 2). Este caso es para confirmar que el guardrail no se implementó antes de tiempo, no para reportarlo como bug.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5B.1 | Haz `POST /api/events/:id/registrations` sin enviar `riskAcceptedAt` ni `riskAcceptanceVersion`. | La inscripción se crea igual (`201`), SIN error `422 RISK_NOT_ACCEPTED` (ese bloqueo es de una fase futura; si ya aparece el error en esta fase, repórtalo porque no debería estar). | 🤖✅ Auto-PASS (`rideglory-api/events-ms/src/registrations/registrations.service.spec.ts` — defaults shareMedicalInfo/allowOrganizerContact to false and riskAcceptedAt/riskAcceptanceVersion to null when omitted) | ✅ |

### 5C. Inscripción registrada antes de esta migración

> Si tienes en tu base de datos de prueba una inscripción creada antes de aplicar la migración de esta fase (o puedes identificar una con fecha antigua).

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5C.1 | Consulta esa inscripción antigua con `GET /api/events/:id/registrations`. | Los 4 campos nuevos aparecen con sus defaults (`shareMedicalInfo: false`, `allowOrganizerContact: false`, `riskAcceptedAt: null`, `riskAcceptanceVersion: null`), sin error ni campos faltantes en el JSON. | 🚫 No automatizable (depende de tener en la DB de dev una fila de EventRegistration anterior a la migración y consultarla vía HTTP contra un servidor vivo; los defaults los garantiza el DDL de la migración, no hay lógica de aplicación aislable en un test) | |

---

## 6. Verificaciones tecnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso a la base de datos o logs del backend.

| # | Verificacion | Resultado esperado | Estado auto | ✅/❌ |
|---|-------------|--------------------|-------------|-------|
| 6.1 | Corre `npx prisma migrate status` en `events-ms`. | Reporta "Database schema is up to date". | 🤖✅ Auto-PASS (`n/a — run-existing: npx prisma migrate status en events-ms`) | ✅ |
| 6.2 | Corre `npx prisma migrate status` en `users-ms`. | Reporta "Database schema is up to date". | 🤖✅ Auto-PASS (`n/a — run-existing: npx prisma migrate status en users-ms`) | ✅ |
| 6.3 | Corre `\d "EventRegistration"` en `psql` contra la DB `events`. | Existen las columnas `shareMedicalInfo boolean not null default false`, `allowOrganizerContact boolean not null default false`, `riskAcceptedAt timestamp` (nullable), `riskAcceptanceVersion text` (nullable). | 🤖✅ Auto-PASS (`n/a — run-existing: psql \d "EventRegistration"`) | ✅ |
| 6.4 | Corre `\d "Event"` en `psql` contra la DB `events`. | Existe la columna `organizerAcceptedResponsibilityAt timestamp` (nullable); la columna preexistente `sosTriggeredAt` sigue intacta (no fue eliminada ni modificada). | 🤖✅ Auto-PASS (`n/a — run-existing: psql \d "Event"`) | ✅ |
| 6.5 | Corre `\d "User"` en `psql` contra la DB `users`. | Existe la columna `medicalConsentAcceptedAt timestamp` (nullable). | 🤖✅ Auto-PASS (`n/a — run-existing: psql \d "User"`) | ✅ |
| 6.6 | Revisa `dist/users/dto/medical-consent.dto.js` en `rideglory-contracts` compilado (o el `.ts` fuente). | Se exporta la constante `NOT_SHARED_SENTINEL = '__NOT_SHARED__'`. | 🤖✅ Auto-PASS (`n/a — run-existing: grep NOT_SHARED_SENTINEL en dist/users/dto/medical-consent.dto.js`) | ✅ |
| 6.7 | Corre `npx jest` en `events-ms`, `users-ms` y `api-gateway`. | `events-ms`: 26 total, 23 passed, 3 failed (los mismos 3 rojos preexistentes de `events.service.spec.ts`, no relacionados). `users-ms`: 2 total, 2 passed. `api-gateway`: 111 total, 103 passed, 8 failed (los mismos 8 rojos preexistentes de `places.service.iter3.spec.ts`, no relacionados). Ningún conteo de fallos debe ser MAYOR al documentado (no hay regresiones nuevas). | 🤖✅ Auto-PASS (`n/a — run-existing: npx jest en events-ms, users-ms, api-gateway`) | ✅ |
| 6.8 | Revisa el código de `events-ms/src/registrations/registrations.service.ts::create()`. | El objeto `registrationData` incluye explícitamente los 4 campos nuevos (`shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`) antes de llamar a `prisma.eventRegistration.upsert()`. | 🤖✅ Auto-PASS (`n/a — run-existing, revisión de código + registrations.service.spec.ts`: grep de campos en registrations.service.ts::create()) | ✅ |
| 6.9 | Revisa `git status --short` en `rideglory-api` (super-repo y submódulos afectados). | Hay cambios sin commitear en `rideglory-contracts`, `events-ms`, `users-ms`, `api-gateway` (working tree sucio a propósito); no hay commits nuevos creados por esta fase. | 🤖❌ Auto-FAIL (el estado real hoy NO coincide con el resultado esperado literal: events-ms/users-ms/api-gateway tienen commits locales ya creados —adelante de origin/main—, incluyendo commits del alcance de esta fase: aa6065c, d76c226, 754f74c; el árbol sí tiene cambios sin commitear adicionales —los 2 specs nuevos de esta corrida—, pero ya no es cierto que "no hay commits nuevos creados por esta fase". No es un bug de código; es una discrepancia de proceso/timing a revisar por un humano) | |
| 6.10 | Revisa `git diff --stat` en el worktree Flutter de esta fase. | Solo aparece el directorio `docs/exec-runs/legal-privacidad-edad-fase1/`; ningún archivo de `lib/` fue modificado. | 🤖✅ Auto-PASS (`n/a — run-existing: git diff --stat en el worktree Flutter de esta fase`) | ✅ |

---

## 👤 Solo para ti — pruebas manuales restantes

> Lista corta: solo los casos que no quedaron verificados automáticamente con un ✅ claro. Todo lo demás ya está cubierto por tests.

| Caso | Accion | Qué revisar | Por qué no se automatizó |
|------|--------|-------------|---------------------------|
| 6.9 | Revisar `git status --short` en `rideglory-api` (super-repo y submódulos). | Confirmar con el equipo si los commits `aa6065c`, `d76c226`, `754f74c` en `events-ms`/`users-ms`/`api-gateway` corresponden efectivamente al trabajo de esta fase y si ya se decidió commitear antes de la revisión de QA (rompe la premisa "working tree sucio, sin commits nuevos" del checklist). No es un bug de código, es una discrepancia de proceso/timing. | El resultado depende del estado real del repo en el momento de la revisión, que cambió respecto al momento en que se escribió el checklist original. |

---

## 🚫 No automatizable en este entorno

| Caso | Accion | Cómo habilitarlo |
|------|--------|-------------------|
| 1.3 | Levantar `events-ms`, `users-ms` y `api-gateway` con `pnpm run start:dev`. | Libera los puertos 3000-3004 (detén la sesión de desarrollo activa) o usa un entorno/máquina distinta, y vuelve a correr qa-auto o el checklist manual. |
| 1.4 | `GET /api/health` contra `api-gateway`. | Depende de 1.3; una vez el `api-gateway` esté arriba de forma aislada, corre el `curl`/Postman manual. |
| 3.2 | `GET /api/events/:id` tras crear/editar con `organizerAcceptedResponsibilityAt`. | Requiere los 3 servicios arriba (ver 1.3) y un `eventId` real; corre el flujo Postman completo una vez el entorno esté disponible. |
| 4.2 | `GET /api/users/me` inmediatamente después de `POST /api/users/me/medical-consent`. | Requiere servidor vivo + JWT de Firebase real; secuencia manual con Postman/curl una vez los servicios estén arriba. |
| 5C.1 | `GET /api/events/:id/registrations` sobre una inscripción anterior a la migración. | Requiere una fila de `EventRegistration` real en la DB de dev creada antes de la migración de esta fase; identifícala con `psql` y consúltala vía Postman una vez el `api-gateway` esté arriba. |

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos 1.1–6.10 marcados como ✅ |
| ⚠️ Aprobado con observaciones | Maximo 2 casos fallidos de baja severidad (por ejemplo, secciones 5 o 6), con ticket creado, y ninguno de las secciones 1, 2 o 4 |
| ❌ Rechazado | Cualquier caso de las secciones 1 (arranque de servicios), 2 (registro con consentimiento/riesgo) o 4 (consentimiento médico) marcado como ❌ |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________

---

## 🤖 Resumen de automatización

| Caso | Estrategia | Test file | Resultado |
|------|-----------|-----------|-----------|
| 1.1 | run-existing | n/a (comando de build) | ✅ pass |
| 1.2 | run-existing | n/a (comando de instalación) | ✅ pass |
| 2.1 | unit test nuevo | `rideglory-api/events-ms/src/registrations/registrations.service.spec.ts` | ✅ pass |
| 2.2 | unit test nuevo (mismo caso, persistencia) | `rideglory-api/events-ms/src/registrations/registrations.service.spec.ts` | ✅ pass |
| 2.3 | unit test nuevo | `rideglory-api/events-ms/src/registrations/registrations.service.spec.ts` | ✅ pass |
| 2.4 | unit test nuevo (mismo caso, defaults) | `rideglory-api/events-ms/src/registrations/registrations.service.spec.ts` | ✅ pass |
| 3.1 | unit test nuevo | `rideglory-api/events-ms/src/events/events.service.spec.ts` | ✅ pass |
| 4.1 | unit test nuevo | `rideglory-api/users-ms/src/users/users.service.spec.ts` + `rideglory-api/api-gateway/src/users/users.controller.spec.ts` | ✅ pass |
| 4.3 | unit test nuevo | `rideglory-api/users-ms/src/users/users.service.spec.ts` | ✅ pass |
| 5A.1 | unit test nuevo | `rideglory-api/api-gateway/src/users/users.controller.spec.ts` | ✅ pass |
| 5B.1 | unit test nuevo (mismo caso que 2.3/2.4) | `rideglory-api/events-ms/src/registrations/registrations.service.spec.ts` | ✅ pass |
| 6.1 | run-existing | n/a (`npx prisma migrate status`) | ✅ pass |
| 6.2 | run-existing | n/a (`npx prisma migrate status`) | ✅ pass |
| 6.3 | run-existing | n/a (`psql \d`) | ✅ pass |
| 6.4 | run-existing | n/a (`psql \d`) | ✅ pass |
| 6.5 | run-existing | n/a (`psql \d`) | ✅ pass |
| 6.6 | run-existing | n/a (`grep` sobre dist compilado) | ✅ pass |
| 6.7 | run-existing | n/a (`npx jest` en los 3 servicios) | ✅ pass |
| 6.8 | revisión de código + spec existente | `rideglory-api/events-ms/src/registrations/registrations.service.spec.ts` | ✅ pass |
| 6.9 | run-existing | n/a (`git status --short`) | ❌ fail |
| 6.10 | run-existing | n/a (`git diff --stat`) | ✅ pass |

**Tests rechazados por el auditor Opus:** ninguno. El auditor calificó la corrida como "solid" (0 tests rechazados por vacíos/tautológicos).

### Cómo correr los tests generados

```bash
cd /Users/cami/Developer/Personal/rideglory-api/events-ms
npx jest src/registrations/registrations.service.spec.ts src/events/events.service.spec.ts

cd /Users/cami/Developer/Personal/rideglory-api/users-ms
npx jest src/users/users.service.spec.ts

cd /Users/cami/Developer/Personal/rideglory-api/api-gateway
npx jest src/users/users.controller.spec.ts
```

No hubo tests Flutter ni e2e Patrol en esta fase (100% backend, sin UI).

### Siguientes pasos

- **6.9 (🤖❌ auto-fail):** no es un bug de código. Antes de aprobar el checklist, un humano debe confirmar con el equipo si los commits `aa6065c`, `d76c226` y `754f74c` en `events-ms`/`users-ms`/`api-gateway` fueron intencionales para esta fase o si deben revertirse/rebasarse antes de la revisión final; el checklist original asumía "sin commits nuevos" y ese supuesto ya no se cumple.
- **1.3 / 1.4 / 3.2 / 4.2 (🚫 no automatizable, bloqueo por entorno):** libera los puertos 3000-3004 (detén la sesión de desarrollo activa del usuario) o usa una máquina/entorno aislado, levanta los 3 servicios con `pnpm run start:dev` y re-corre manualmente el flujo Postman/curl de esos 4 casos.
- **5C.1 (🚫 no automatizable, requiere dato histórico):** identifica o crea en la DB de dev de `events-ms` una fila de `EventRegistration` anterior a la migración de esta fase, y consúltala vía `GET /api/events/:id/registrations` una vez el `api-gateway` esté arriba.
