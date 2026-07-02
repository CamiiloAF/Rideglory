 # Checklist de QA — Validación de edad mínima y ofuscación de datos sensibles en inscripciones

**Feature:** Bloqueo de inscripción a menores de edad + ofuscación condicional de datos médicos/PII en la vista del organizador
**Fases cubiertas:** Fase 2 (backend `events-ms`, sin cambios en Flutter)
**Estado:** Rechazado — 2 fallas automatizadas en sección crítica 7 (revisión humana requerida)

<!-- qa-auto:annotated -->
> **Automatización qa-auto** (2026-07-01T05:24:53Z): 🤖✅ 23 verificados · 🤖❌ 2 fallando · 👤 0 manuales · 🚫 2 no automatizables (de 27 casos).
> Entorno: device=android-emulator, baseline=na. Auditor Opus: solid.

---

## Nota importante para quien ejecute este checklist

Esta fase **no toca la app Flutter ni ninguna pantalla**. Todo el cambio vive en el backend (`events-ms`, endpoint `GET /events/:eventId/registrations` y `POST /events/:eventId/registrations`). Por eso las pruebas de esta guía se hacen con **Postman, curl o herramienta HTTP equivalente** contra la API de desarrollo, no navegando la app. Si tenés acceso a la app y querés confirmar el efecto visible (rechazo al inscribirte), podés usarla para el caso 1; para todo lo demás necesitás hacer las llamadas HTTP directamente porque Flutter todavía no muestra la pantalla de organizador con estos datos (llega en fases posteriores).

---

## Pre-condiciones

Antes de empezar, asegurate de tener:

- [ ] Acceso a un entorno de `events-ms` corriendo (local o de pruebas) con base de datos accesible.
- [ ] Un token Firebase válido de un usuario **rider** de prueba, con `birthDate` que podás modificar libremente en la base de datos (o crear un usuario nuevo con la fecha de nacimiento exacta que necesites por caso).
- [ ] Un token Firebase válido de un usuario **organizador** de prueba, dueño de al menos un evento con inscripciones.
- [ ] Un evento de prueba (`eventId`) creado por el organizador, con al menos 2 riders inscritos, en el que puedas cambiar el `state` (`SCHEDULED` / `IN_PROGRESS`) y el campo `sosTriggeredAt` directamente en la base de datos para simular los distintos escenarios.
- [ ] Para cada rider inscrito de prueba, poder editar en base de datos (o al inscribirse) los campos `shareMedicalInfo`, `allowOrganizerContact`, `eps`, `medicalInsurance`, `bloodType`, `phone`, `identificationNumber`, `email`, `residenceCity`.
- [ ] Postman, Insomnia o `curl` configurado para llamar la API con el header `Authorization: Bearer <token>`.

---

## 1. Rechazo de inscripción a menores de edad

> Vas a intentar inscribir riders con distintas fechas de nacimiento a un evento abierto (`POST /events/:eventId/registrations`), usando un token de rider válido para cada caso.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 1.1 | Inscribí a un rider cuya fecha de nacimiento sea exactamente 17 años y 364 días antes de hoy (un día antes de cumplir 18) | La API responde con error `422` y el mensaje `UNDERAGE_RIDER`; el rider NO queda inscrito | 🤖✅ Auto-PASS (`events-ms/src/registrations/registrations.service.age-validation.spec.ts` :: rejects a rider who is 17 years and 364 days old) | ✅ |
| 1.2 | Inscribí a un rider cuya fecha de nacimiento sea exactamente 18 años antes de hoy (cumple años hoy) | La API responde con éxito (inscripción creada), sin ningún error de edad | 🤖✅ Auto-PASS (`events-ms/src/registrations/registrations.service.age-validation.spec.ts` :: accepts a rider whose 18th birthday is exactly today) | ✅ |
| 1.3 | Inscribí a un rider claramente adulto (por ejemplo, nacido en 1990) | La API responde con éxito, inscripción creada normalmente | 🤖✅ Auto-PASS (`events-ms/src/registrations/registrations.service.age-validation.spec.ts` :: comfortably over 18, fixture 1990-01-01) | ✅ |
| 1.4 | Inscribí a un rider claramente menor (por ejemplo, 15 años) | La API responde con error `422` y el mensaje `UNDERAGE_RIDER` | 🤖✅ Auto-PASS (`events-ms/src/registrations/registrations.service.age-validation.spec.ts` :: comfortably under 18, 15 years) | ✅ |
| 1.5 | Verificá en la base de datos que ningún rider menor de edad quedó registrado en `EventRegistration` tras los intentos fallidos (1.1 y 1.4) | No existe ningún registro de inscripción para esos riders en ese evento | 🚫 No automatizable (requiere entorno `events-ms` con BD real; los specs solo mockean Prisma/ClientProxy y verifican que `upsert` nunca se llama, evidencia indirecta) | |

---

## 2. Ofuscación de datos médicos según estado del evento

> Vas a consultar `GET /events/:eventId/registrations` con el token del organizador, cambiando el `state` del evento y el `shareMedicalInfo` de la inscripción entre cada consulta.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 2.1 | Con el evento en estado `SCHEDULED` (aún no arranca) y la inscripción con `shareMedicalInfo = true`, consultá la lista de inscripciones del organizador | Los campos `eps`, `medicalInsurance`, `bloodType` llegan con el valor `"__NOT_SHARED__"` (no los datos reales), a pesar de que el rider dio consentimiento | 🤖✅ Auto-PASS (`events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` :: masks medical fields with __NOT_SHARED__ when event is SCHEDULED, regardless of shareMedicalInfo) | ✅ |
| 2.2 | Cambiá el evento a estado `IN_PROGRESS` y dejá `shareMedicalInfo = true` en la inscripción, y volvé a consultar | Los campos `eps`, `medicalInsurance`, `bloodType` llegan con los valores **reales** del rider | 🤖✅ Auto-PASS (`events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` :: reveals medical fields when event is IN_PROGRESS and shareMedicalInfo is true) | ✅ |
| 2.3 | Con el evento en `IN_PROGRESS` pero `shareMedicalInfo = false` en la inscripción, consultá de nuevo | Los campos `eps`, `medicalInsurance`, `bloodType` vuelven a llegar como `"__NOT_SHARED__"` | 🤖✅ Auto-PASS (`events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` :: masks medical fields when event is IN_PROGRESS but shareMedicalInfo is false) | ✅ |
| 2.4 | Revisá específicamente el campo `medicalInsurance` en el caso 2.1 o 2.3 | El valor es el texto `"__NOT_SHARED__"`, nunca `null` ni un campo ausente | 🤖✅ Auto-PASS (`events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` :: cases 1 y 3, medicalInsurance == '__NOT_SHARED__') | ✅ |

---

## 3. Ofuscación del contacto telefónico

> Vas a consultar la misma lista de inscripciones del organizador, cambiando el consentimiento de contacto de cada rider.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3.1 | Con un rider que tiene `allowOrganizerContact = false`, consultá `GET /events/:eventId/registrations` | El campo `phone` de ese rider llega como `"••••"` | 🤖✅ Auto-PASS (`events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` :: masks phone with •••• when allowOrganizerContact is false, and reveals it when true) | ✅ |
| 3.2 | Con un rider que tiene `allowOrganizerContact = true`, consultá la misma lista | El campo `phone` de ese rider llega con el número real | 🤖✅ Auto-PASS (`events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` :: masks phone with •••• when allowOrganizerContact is false, and reveals it when true) | ✅ |
| 3.3 | Consultá una lista con ambos riders (uno con cada valor de `allowOrganizerContact`) en la misma respuesta | Cada rider muestra el `phone` según su propio consentimiento, no se mezclan ni se aplica el mismo criterio a todos | 🤖✅ Auto-PASS (`events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` :: masks phone with •••• when allowOrganizerContact is false, and reveals it when true) | ✅ |

---

## 4. Ofuscación de identificación y datos de contacto según SOS

> Vas a activar y desactivar el SOS del evento (campo `sosTriggeredAt`) y comparar la respuesta del organizador.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 4.1 | Con `sosTriggeredAt` en `null` (SOS no activado), consultá `GET /events/:eventId/registrations` | Los campos `identificationNumber`, `email`, `residenceCity` llegan como `"••••"` | 🤖✅ Auto-PASS (`events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` :: masks identificationNumber, email and residenceCity when sosTriggeredAt is null, reveals when set) | ✅ |
| 4.2 | Poné una fecha/hora en `sosTriggeredAt` (simulá que se activó el SOS) y volvé a consultar el mismo evento | Los campos `identificationNumber`, `email`, `residenceCity` llegan con los valores **reales** del rider | 🤖✅ Auto-PASS (`events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` :: masks identificationNumber, email and residenceCity when sosTriggeredAt is null, reveals when set) | ✅ |
| 4.3 | Volvé a poner `sosTriggeredAt` en `null` y consultá otra vez | Los campos vuelven a mostrarse como `"••••"` (la ofuscación reacciona al estado actual, no queda "pegada" en real) | 🤖✅ Auto-PASS (`events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` :: masks identificationNumber, email and residenceCity when sosTriggeredAt is null, reveals when set) | ✅ |

---

## 5. Vista propia del rider (sin ofuscación)

> Con el token del propio rider (no el organizador), consultá su inscripción individual.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5.1 | Consultá `GET /events/:eventId/registrations/me` con el token del rider, sobre un evento en `SCHEDULED` y con `shareMedicalInfo = false` | Todos los campos (`eps`, `medicalInsurance`, `bloodType`, `phone`, `identificationNumber`, `email`, `residenceCity`) llegan con los valores **reales**, sin ningún `"__NOT_SHARED__"` ni `"••••"` | 🤖✅ Auto-PASS (`events-ms/src/registrations/registrations.service.unmasked-and-combinations.spec.ts` :: findMyRegistrationForEvent() returns all real values for a SCHEDULED event with shareMedicalInfo=false, QA 5.1) | ✅ |
| 5.2 | Consultá `GET /events/:eventId/registrations` (mis inscripciones en general) con el token del rider | Igual que el caso anterior: todos los datos propios llegan reales, sin ofuscación | 🤖✅ Auto-PASS (`events-ms/src/registrations/registrations.service.unmasked-and-combinations.spec.ts` :: findMyRegistrations() returns all real values for the caller own registrations, QA 5.2) | ✅ |

---

## 6. Casos de borde

### 6A. Combinación de todas las condiciones desfavorables

> Configurá un rider con el peor escenario posible de privacidad: evento `SCHEDULED`, `shareMedicalInfo = false`, `allowOrganizerContact = false`, `sosTriggeredAt = null`.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 6A.1 | Consultá `GET /events/:eventId/registrations` como organizador en ese escenario | `eps`/`medicalInsurance`/`bloodType` = `"__NOT_SHARED__"`, `phone` = `"••••"`, `identificationNumber`/`email`/`residenceCity` = `"••••"`; ningún dato real se filtra | 🤖✅ Auto-PASS (`events-ms/src/registrations/registrations.service.unmasked-and-combinations.spec.ts` :: masks every sensitive field when all 4 conditions are unfavorable at once, QA 6A.1) | ✅ |

### 6B. Combinación de todas las condiciones favorables

> Configurá un rider con el mejor escenario: evento `IN_PROGRESS`, `shareMedicalInfo = true`, `allowOrganizerContact = true`, `sosTriggeredAt` con fecha.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 6B.1 | Consultá `GET /events/:eventId/registrations` como organizador en ese escenario | Todos los campos llegan con sus valores reales | 🤖✅ Auto-PASS (`events-ms/src/registrations/registrations.service.unmasked-and-combinations.spec.ts` :: reveals every sensitive field when all 4 conditions are favorable at once, QA 6B.1) | ✅ |

### 6C. Se mantiene el resumen del vehículo tras la ofuscación

> Verificá que enmascarar los datos sensibles no borre otra información de la respuesta.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 6C.1 | En cualquiera de las consultas anteriores del organizador, revisá el campo `vehicleSummary` de cada inscripción | `vehicleSummary` sigue presente con los datos del vehículo del rider, sin importar si los demás campos están ofuscados o no | 🤖✅ Auto-PASS (`events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` :: masks medical fields with __NOT_SHARED__ when event is SCHEDULED, regardless of shareMedicalInfo) | ✅ |

### 6D. Intento de inscripción justo antes de cumplir años

> Repetición del caso 1.1 pero verificando el mensaje exacto de error.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 6D.1 | Inscribí un rider con 17 años y 364 días y revisá el cuerpo completo de la respuesta de error | El código de estado HTTP es `422` y el campo `message` (no `code`) contiene el texto exacto `UNDERAGE_RIDER` | 🤖✅ Auto-PASS (`events-ms/src/registrations/registrations.service.age-validation.spec.ts` :: rejects a rider who is 17 years and 364 days old) | ✅ |

---

## 7. Verificaciones tecnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso al código, la terminal del backend o la base de datos.

| # | Verificacion | Resultado esperado | Estado auto | ✅/❌ |
|---|-------------|--------------------|-------------|-------|
| 7.1 | Correr `npx tsc --noEmit` dentro de `events-ms` | 0 errores de tipado | 🤖✅ Auto-PASS (n/a, comando re-ejecutado :: npx tsc --noEmit in events-ms) | ✅ |
| 7.2 | Correr `npx jest registrations.service.age-validation registrations.service.privacy-mask` dentro de `events-ms` | 2 test suites, 9 tests, 0 failures | 🤖✅ Auto-PASS (`events-ms/src/registrations/registrations.service.age-validation.spec.ts`, `events-ms/src/registrations/registrations.service.privacy-mask.spec.ts`) | ✅ |
| 7.3 | Correr la suite completa `npx jest` dentro de `events-ms` | 5 test suites, 42 tests, 0 failures (sin regresiones en specs preexistentes) | 🤖❌ Auto-FAIL (los números documentados ya no coinciden con el working tree actual — ver sección de pruebas manuales restantes) | |
| 7.4 | Revisar en base de datos que ningún registro de `EventRegistration` fue creado para los intentos de inscripción menores de edad (casos 1.1 y 1.4) | No hay filas nuevas en `EventRegistration` correspondientes a esos intentos | 🚫 No automatizable (requiere acceso a BD real de un entorno `events-ms` corriendo; duplica 1.5 y no es verificable solo con specs mockeados) | |
| 7.5 | Revisar en el código (`registrations.service.ts`) que `findMyRegistrationForEvent` y `findMyRegistrations` no invocan `applyPrivacyMask` | Confirmado por lectura de código / grep, cero coincidencias de `applyPrivacyMask` en esos dos métodos | 🤖✅ Auto-PASS (n/a, grep re-ejecutado :: grep applyPrivacyMask in registrations.service.ts) | ✅ |
| 7.6 | Confirmar que no hay diff en `rideglory-contracts` ni en `schema.prisma`/`prisma/migrations/` para esta fase | `git diff --stat` en `rideglory-api` solo muestra archivos dentro de `events-ms/src/registrations/` | 🤖❌ Auto-FAIL (`git diff --stat` en la raíz de `rideglory-api` muestra dirty state no relacionado con esta fase — ver sección de pruebas manuales restantes) | |

---

## 👤 Solo para ti — pruebas manuales restantes

Casos que la automatización no pudo cerrar en verde: revisá estos dos antes de aprobar la fase.

| id | Acción | Qué revisar | Por qué no se automatizó |
|----|--------|-------------|---------------------------|
| 7.3 | Correr la suite completa `npx jest` dentro de `events-ms` | Confirmar cuántos test suites/tests hay realmente hoy y si los 44 (antes de mi spec nuevo) o 48 (después) son esperados. Investigar el archivo `events-ms/src/events/events.service.spec.ts`, que ya tenía 2 tests adicionales sin commitear etiquetados en código como "QA case 3.1" (de otra fase/caso, no de este checklist) y que los handoffs de esta fase no contemplaban. Con mi spec nuevo (`registrations.service.unmasked-and-combinations.spec.ts`, 4 tests) la suite pasó de 5/42 (documentado) a 6/48 (real), sin fallas nuevas, pero el número exacto documentado en `handoffs/backend.md` y `handoffs/qa.md` ya no coincide con el working tree | El desajuste es de conteo/documentación, no un defecto funcional en la lógica de edad/ofuscación; requiere que un humano decida si el archivo dirty de `events.service.spec.ts` pertenece a esta fase o a otra y actualice los handoffs en consecuencia |
| 7.6 | Confirmar que no hay diff en `rideglory-contracts` ni en `schema.prisma`/`prisma/migrations/` para esta fase | `git diff --stat` en la raíz de `rideglory-api` (super-repo) muestra: bumps de punteros de submódulo (api-gateway, events-ms, notifications-ms, rideglory-contracts, users-ms), `package-lock.json` y `.DS_Store` modificados. Dentro de `events-ms`, el único diff fuera de lo esperado es `src/events/events.service.spec.ts` (no pertenece a `registrations/`). Dentro del submódulo `rideglory-contracts`, `src/events/dto/event-filter.dto.ts` también está modificado, sin relación aparente con esta fase | Ninguno de estos archivos fue tocado ni revertido por mí (regla de no editar código de producción y de no ejecutar operaciones git destructivas); un humano debe decidir si ese estado dirty es intencional de otra fase en curso o accidental antes de aprobar |

---

## 🚫 No automatizable en este entorno

| id | Caso | Cómo habilitarlo |
|----|------|-------------------|
| 1.5 | Verificar en BD que ningún menor quedó registrado en `EventRegistration` tras 1.1 y 1.4 | Levantar un `events-ms` local o de pruebas con base de datos accesible (Postgres + `prisma migrate deploy`), correr los intentos de inscripción 1.1/1.4 vía HTTP real, e inspeccionar la tabla `EventRegistration` directamente o con `prisma studio` |
| 7.4 | Revisar en BD que ningún `EventRegistration` fue creado para los intentos de inscripción menores (1.1 y 1.4) | Mismo entorno que 1.5 (duplica el caso); una vez arriba, el mismo query de BD cubre ambos ids |

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos de las secciones 1 a 5 y 7 marcados como ✅ |
| ⚠️ Aprobado con observaciones | Maximo 2 casos fallidos de baja severidad en la sección 6 (casos de borde), con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones 1, 2, 3, 4, 5 o 7 marcado como ❌ |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________

---

## 🤖 Resumen de automatización

| id | Estrategia | Test file | Resultado |
|----|-----------|-----------|-----------|
| 1.1 | Unit test con fixture de fecha de nacimiento (17a 364d) | `events-ms/src/registrations/registrations.service.age-validation.spec.ts` | ✅ pass |
| 1.2 | Unit test con fixture de fecha de nacimiento (cumple 18 hoy) | `events-ms/src/registrations/registrations.service.age-validation.spec.ts` | ✅ pass |
| 1.3 | Unit test con fixture de rider adulto (1990) | `events-ms/src/registrations/registrations.service.age-validation.spec.ts` | ✅ pass |
| 1.4 | Unit test con fixture de rider menor (15 años) | `events-ms/src/registrations/registrations.service.age-validation.spec.ts` | ✅ pass |
| 2.1 | Unit test evento SCHEDULED + shareMedicalInfo=true | `events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` | ✅ pass |
| 2.2 | Unit test evento IN_PROGRESS + shareMedicalInfo=true | `events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` | ✅ pass |
| 2.3 | Unit test evento IN_PROGRESS + shareMedicalInfo=false | `events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` | ✅ pass |
| 2.4 | Assert de valor exacto `"__NOT_SHARED__"` (cubierto por specs de 2.1/2.3) | `events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` | ✅ pass |
| 3.1 | Unit test phone ofuscado con allowOrganizerContact=false | `events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` | ✅ pass |
| 3.2 | Unit test phone real con allowOrganizerContact=true | `events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` | ✅ pass |
| 3.3 | Unit test lista mixta (ambos riders en la misma respuesta) | `events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` | ✅ pass |
| 4.1 | Unit test sosTriggeredAt=null → PII ofuscada | `events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` | ✅ pass |
| 4.2 | Unit test sosTriggeredAt con fecha → PII real | `events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` | ✅ pass |
| 4.3 | Unit test sosTriggeredAt vuelve a null → PII vuelve a ofuscarse | `events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` | ✅ pass |
| 5.1 | Unit test `findMyRegistrationForEvent()` sin ofuscación | `events-ms/src/registrations/registrations.service.unmasked-and-combinations.spec.ts` | ✅ pass |
| 5.2 | Unit test `findMyRegistrations()` sin ofuscación | `events-ms/src/registrations/registrations.service.unmasked-and-combinations.spec.ts` | ✅ pass |
| 6A.1 | Unit test combinación de las 4 condiciones desfavorables | `events-ms/src/registrations/registrations.service.unmasked-and-combinations.spec.ts` | ✅ pass |
| 6B.1 | Unit test combinación de las 4 condiciones favorables | `events-ms/src/registrations/registrations.service.unmasked-and-combinations.spec.ts` | ✅ pass |
| 6C.1 | Assert de `vehicleSummary` presente (cubierto por spec de 2.1) | `events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` | ✅ pass |
| 6D.1 | Repetición de 1.1 con assert del cuerpo exacto del error | `events-ms/src/registrations/registrations.service.age-validation.spec.ts` | ✅ pass |
| 7.1 | Re-ejecución de comando (`npx tsc --noEmit`) | n/a (comando) | ✅ pass |
| 7.2 | Re-ejecución de comando (`npx jest registrations.service.age-validation registrations.service.privacy-mask`) | n/a (comando) | ✅ pass |
| 7.3 | Re-ejecución de comando (`npx jest` completo en events-ms) | n/a (comando) | ❌ fail — conteo desactualizado, ver "pruebas manuales restantes" |
| 7.5 | Re-ejecución de `grep applyPrivacyMask` en `registrations.service.ts` | n/a (grep) | ✅ pass |
| 7.6 | Re-ejecución de `git diff --stat` en `rideglory-api` | n/a (git diff) | ❌ fail — dirty state fuera de scope, ver "pruebas manuales restantes" |

**Tests rechazados por el auditor Opus:** ninguno (0 tests rechazados por vacíos; auditor calificado "solid").

### Cómo correr los tests generados

```bash
cd /Users/cami/Developer/Personal/rideglory-api/events-ms
npx jest registrations.service.age-validation
npx jest registrations.service.privacy-mask
npx jest registrations.service.unmasked-and-combinations
# o la suite completa del microservicio:
npx jest
```

No hubo tests Flutter ni e2e Patrol en esta fase (el cambio es 100% backend `events-ms`, sin superficie en la app).

### Siguientes pasos

- **7.3 (auto-fail):** Investigar si `events-ms/src/events/events.service.spec.ts` (2 tests etiquetados "QA case 3.1" en el código, sin commitear) pertenece a otra fase en curso o es un remanente accidental; actualizar `handoffs/backend.md` y `handoffs/qa.md` con el conteo real de test suites/tests una vez aclarado, y volver a correr `npx jest` para confirmar 0 failures con el conteo correcto.
- **7.6 (auto-fail):** Revisar con el equipo si los bumps de punteros de submódulo (api-gateway, events-ms, notifications-ms, rideglory-contracts, users-ms), `package-lock.json`, `.DS_Store` y el cambio en `rideglory-contracts/src/events/dto/event-filter.dto.ts` son de otra fase/rama en curso; si son accidentales, un humano debe decidir si descartarlos (no lo hice yo por la regla de no ejecutar operaciones git destructivas).
- **🚫 no automatizable (1.5, 7.4):** para cerrarlos, levantar un entorno `events-ms` con base de datos real (Postgres + `prisma migrate deploy`), ejecutar los intentos de inscripción de menores vía HTTP y verificar directamente la tabla `EventRegistration`.
