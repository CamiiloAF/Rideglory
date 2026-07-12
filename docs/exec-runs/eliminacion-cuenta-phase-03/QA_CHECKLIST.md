# Checklist de QA — Bloqueo de organizadores con eventos activos y anonimización de historial al eliminar cuenta

**Feature:** Eliminación de cuenta — bloqueo de organizador con eventos activos + anonimización de inscripciones (`EventRegistration`)
**Fases cubiertas:** Fase 1-2 (eliminación de cuenta, ya entregadas) + Fase 3 (bloqueo de organizador y anonimización de historial)
**Estado:** ⚠️ Aprobado con observaciones — automatización qa-auto sin fallas (26/26 auto-pass); quedan 9 casos manuales y 1 no automatizable pendientes de verificación humana antes de cerrar (ver secciones abajo)

<!-- qa-auto:annotated -->
> **Automatización qa-auto** (2026-07-11T15:09:12Z): 🤖✅ 26 verificados · 🤖❌ 0 fallando · 👤 9 manuales · 🚫 1 no automatizables (de 36 casos).
> Entorno: device=android-emulator, baseline=green. Auditor Opus: solid.

---

## Pre-condiciones

Antes de empezar, asegurate de tener en la cuenta de prueba:

- [ ] Un usuario organizador (`qa2@gmail.com` / `Test123.`) con al menos un evento propio ("Mi Evento") que puedas mover entre estados `Borrador`/`Programado`/`En curso` y `Cancelado`/`Finalizado` desde el panel de organizador.
- [ ] Un segundo usuario organizador de prueba SIN ningún evento activo (o con eventos solo en `Cancelado`/`Finalizado`), para probar el camino feliz de borrado.
- [ ] Un usuario rider (`qa1@gmail.com` / `Test123.`) con al menos una inscripción (`EventRegistration`) a un evento de otro organizador, con datos de contacto/emergencia diligenciados (teléfono, email, ciudad de residencia, EPS, contacto de emergencia, fecha de nacimiento).
- [ ] Acceso a la app corriendo en simulador/dispositivo con el build de esta fase instalado.
- [ ] Acceso (para las verificaciones técnicas) a la base de datos de `events-ms` (Postgres, tabla `EventRegistration`) o a quien pueda consultarla por ti.
- [ ] Idealmente, acceso a un proxy/inspector de tráfico HTTP (Charles, Proxyman, o los logs de red del backend) para el caso 12.

---

## 1. Eliminar cuenta sin eventos activos como organizador (camino feliz)

> Inicia sesión con el organizador de prueba SIN eventos activos (o solo `Cancelado`/`Finalizado`). Ve a Perfil.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 1.1 | Toca "Eliminar cuenta" en el perfil | La app navega directo a la pantalla de confirmación de eliminación de cuenta, sin ninguna pantalla intermedia ni demora perceptible | 🤖✅ Auto-PASS (`test/features/profile/presentation/widgets/profile_actions_list_delete_account_precondition_test.dart :: sin eventos activos como organizador navega directo a deleteAccount`) | ✅ |
| 1.2 | Observa la pantalla de confirmación | Ves el switch "entiendo lo que se borra" y el botón final de confirmar, como en el flujo normal de fases anteriores | 🤖✅ Auto-PASS (`test/features/profile/presentation/delete_account_confirmation_page_test.dart :: el botón de confirmación empieza deshabilitado y se habilita al activar el switch`) | ✅ |

---

## 2. Bloqueo de organizador con eventos activos

> Inicia sesión con `qa2@gmail.com`. Antes de empezar, mueve "Mi Evento" (u otro evento propio) a estado **Borrador**. Ve a Perfil.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 2.1 | Toca "Eliminar cuenta" con el evento en estado **Borrador** | Aparece un bottom sheet de bloqueo (no la pantalla de confirmación de borrado); **nunca** ves el switch ni el botón final de confirmar | 🤖✅ Auto-PASS (`test/features/profile/presentation/widgets/profile_actions_list_delete_account_precondition_test.dart :: con un evento activo como organizador bloquea y muestra el sheet con su nombre`) | ✅ |
| 2.2 | Verifica el contenido del bottom sheet | Muestra el nombre del evento bloqueante y un botón/CTA para ver tus eventos | 🤖✅ Auto-PASS (`test/features/profile/presentation/widgets/active_events_block_sheet_test.dart :: muestra el nombre del primer evento bloqueante`) | ✅ |
| 2.3 | Toca el CTA del bottom sheet | Navegas a la pantalla "Mis eventos" | 🤖✅ Auto-PASS (`test/features/profile/presentation/widgets/active_events_block_sheet_test.dart :: el CTA navega a AppRoutes.myEvents`) | ✅ |
| 2.4 | Vuelve a Perfil, cambia el evento a estado **Programado** y repite el tap en "Eliminar cuenta" | El bottom sheet de bloqueo vuelve a aparecer, mostrando el evento en estado Programado | 🤖✅ Auto-PASS (`test/features/profile/presentation/widgets/profile_actions_list_delete_account_precondition_test.dart :: con un evento activo como organizador bloquea y muestra el sheet con su nombre`) | ✅ |
| 2.5 | Cambia el evento a estado **En curso** y repite el tap en "Eliminar cuenta" | El bottom sheet de bloqueo vuelve a aparecer | 🤖✅ Auto-PASS (`test/features/profile/presentation/widgets/profile_actions_list_delete_account_precondition_test.dart :: se re-evalúa en cada tap: bloqueado primero, permitido después (AC4)`) | ✅ |

---

## 3. La precondición se re-evalúa siempre (no se cachea)

> Continúa con `qa2@gmail.com` desde la sección 2, con el evento aún en un estado activo.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3.1 | Con el evento en estado activo, toca "Eliminar cuenta" | Ves el bottom sheet de bloqueo | 🤖✅ Auto-PASS (`test/features/profile/presentation/widgets/profile_actions_list_delete_account_precondition_test.dart :: con un evento activo como organizador bloquea y muestra el sheet con su nombre`) | ✅ |
| 3.2 | Sal del bottom sheet, ve a "Mis eventos" y cambia ese evento a **Cancelado** o **Finalizado** | El evento cambia de estado correctamente en la lista | 👤 Manual (navegación real a "Mis eventos" y edición de estado de evento contra backend real; funcionalidad preexistente ajena a esta fase, requiere dispositivo/simulador real) | |
| 3.3 | Vuelve a Perfil y toca "Eliminar cuenta" de nuevo (sin cerrar ni reabrir la app) | Esta vez navega directo a la pantalla de confirmación de eliminación de cuenta (ya no ves el bloqueo) | 🤖✅ Auto-PASS (`test/features/profile/presentation/widgets/profile_actions_list_delete_account_precondition_test.dart :: se re-evalúa en cada tap: bloqueado primero, permitido después (AC4)`) | ✅ |

---

## 4. Anonimización visible en la vista del organizador (cuenta de rider eliminada)

> Requiere que primero se haya eliminado la cuenta del rider de prueba con su inscripción activa (puedes coordinar con el equipo técnico para preparar este estado si no quieres borrar una cuenta real durante la prueba — ver sección 7 de verificaciones técnicas como alternativa). Luego inicia sesión como el organizador dueño del evento al que ese rider estaba inscrito.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 4.1 | Abre la lista de asistentes ("Attendees") del evento | El inscrito con cuenta eliminada aparece con el nombre "Usuario eliminado", sin errores ni pantalla en blanco | 🤖✅ Auto-PASS (`test/features/events/presentation/attendees/widgets/attendees_list_navigation_test.dart :: AC9: renders a registration with fullName="Usuario eliminado" without crashing`) | ✅ |
| 4.2 | Toca ese inscrito para abrir el detalle de la inscripción (`RegistrationDetailPage`) | La pantalla abre sin crash | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_detail_page_test.dart :: muestra el placeholder dedicado en los 7 campos de texto + fecha de nacimiento`) | ✅ |
| 4.3 | Revisa el campo de número de documento | Muestra "Cuenta eliminada" (no vacío, no "N/A", no `null` literal) | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_detail_page_test.dart :: muestra el placeholder dedicado en los 7 campos de texto + fecha de nacimiento`) | ✅ |
| 4.4 | Revisa el campo de fecha de nacimiento | Muestra "Cuenta eliminada" | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_detail_page_test.dart :: muestra el placeholder dedicado en los 7 campos de texto + fecha de nacimiento`) | ✅ |
| 4.5 | Revisa el campo de teléfono | Muestra "Cuenta eliminada" | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_detail_page_test.dart :: muestra el placeholder dedicado en los 7 campos de texto + fecha de nacimiento`) | ✅ |
| 4.6 | Revisa el campo de email | Muestra "Cuenta eliminada" | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_detail_page_test.dart :: muestra el placeholder dedicado en los 7 campos de texto + fecha de nacimiento`) | ✅ |
| 4.7 | Revisa el campo de ciudad de residencia | Muestra "Cuenta eliminada" | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_detail_page_test.dart :: muestra el placeholder dedicado en los 7 campos de texto + fecha de nacimiento`) | ✅ |
| 4.8 | Revisa el campo de EPS | Muestra "Cuenta eliminada" | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_detail_page_test.dart :: muestra el placeholder dedicado en los 7 campos de texto + fecha de nacimiento`) | ✅ |
| 4.9 | Revisa el campo de contacto de emergencia (nombre y teléfono) | Ambos muestran "Cuenta eliminada" | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_detail_page_test.dart :: muestra el placeholder dedicado en los 7 campos de texto + fecha de nacimiento`) | ✅ |
| 4.10 | Revisa el campo de tipo de sangre | Sigue mostrando el tipo de sangre original (no se anonimiza) | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_detail_page_test.dart :: 1.1: registration with bloodType=A+ renders "A+" in the blood type row`) | ✅ |
| 4.11 | Si el registro tiene `shareMedicalInfo` en falso, revisa los campos médicos enmascarados | Se ven como `••••` (el enmascarado normal de privacidad), sin mezclarse ni confundirse con el texto "Cuenta eliminada" | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_detail_page_test.dart :: shareMedicalInfo=false con campos enmascarados ("••••") no muestra el placeholder de cuenta eliminada`) | ✅ |

---

## 5. Botón de contacto con inscrito de cuenta eliminada

> Continúa en `RegistrationDetailPage` del inscrito de cuenta eliminada de la sección 4.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5.1 | Busca el botón de "Llamar" o "Contactar" para ese inscrito | El botón no aparece, o si aparece, tocarlo no produce crash ni intenta abrir una URL/llamada inválida | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_contact_trigger_test.dart :: phone=null (cuenta anonimizada) con Llamar no lanza excepción ni URL (eliminacion-cuenta-phase-03)`) | ✅ |

---

## 6. Casos de borde

### 6A. Condición de carrera — evento creado justo después de pasar el bloqueo

> Con `qa2@gmail.com` sin eventos activos, toca "Eliminar cuenta" para llegar a la pantalla de confirmación. Sin salir de esa pantalla, en otro dispositivo/sesión crea un evento nuevo para ese mismo organizador.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 6A.1 | Con el evento nuevo ya creado, confirma la eliminación de cuenta en la pantalla de confirmación | El sistema responde con un error/mensaje indicando que no se puede eliminar por tener eventos activos como organizador (banner de error existente), en vez de eliminar la cuenta igual | 👤 Manual (requiere dos sesiones/dispositivos concurrentes contra backend real para disparar la condición de carrera real; no es simulable de forma determinista en un test unitario/widget aislado — el render genérico del banner de error ya está cubierto por `delete_account_confirmation_page_test.dart`, pero el disparo de la carrera en sí no) | |

### 6B. Falla de red al tocar "Eliminar cuenta"

> Con cualquier organizador, desactiva la conexión de red (modo avión) antes de tocar "Eliminar cuenta".

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 6B.1 | Toca "Eliminar cuenta" sin conexión | Aparece un mensaje de error (SnackBar) indicando que no se pudo verificar; la app NO navega ni al bloqueo ni a la confirmación de borrado | 🤖✅ Auto-PASS (`test/features/profile/presentation/widgets/profile_actions_list_delete_account_precondition_test.dart :: si falla la verificación no navega ni bloquea silenciosamente`) | ✅ |

### 6C. Rider sin inscripciones elimina su cuenta

> Con un rider sin ninguna `EventRegistration`, elimina la cuenta siguiendo el flujo normal.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 6C.1 | Completa el flujo de eliminación de cuenta | La cuenta se elimina exitosamente sin errores, aunque no haya inscripciones que anonimizar | 🤖✅ Auto-PASS (`rideglory-api/events-ms/src/registrations/registrations.service.anonymization.spec.ts :: count: 0 sin excepción cuando no hay registros`) | ✅ |

---

## 7. Verificaciones tecnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso a la base de datos o logs del backend.

| # | Verificacion | Resultado esperado | Estado auto | ✅/❌ |
|---|-------------|--------------------|-------------|-------|
| 7.1 | Con un organizador con evento activo, llama `DELETE /users/me` directamente (Postman/curl) | Responde `409` con `error: "ACTIVE_EVENTS_AS_ORGANIZER"` y `activeEvents` no vacío | 🤖✅ Auto-PASS (`rideglory-api/api-gateway/src/users/account-deletion.service.spec.ts :: responde 409 ACTIVE_EVENTS_AS_ORGANIZER con activeEvents no vacío`) | ✅ |
| 7.2 | Tras el 409 anterior, consulta en BD `vehicles-ms`, `events-ms` (`EventRegistration`) y `users-ms` para ese usuario | Ningún dato cambió: ni vehículos, ni inscripciones, ni el registro del usuario | 🚫 No automatizable (requiere BD Postgres real compartida de vehicles-ms/events-ms/users-ms, no disponible en este entorno; el spec de `account-deletion.service.spec.ts` verifica vía mocks que cero llamadas de borrado ocurren tras el 409 como respaldo indirecto, pero no es la verificación de BD real que pide el caso — ver `QA_AUTOMATION_RESULTS.md`) | |
| 7.3 | Antes de eliminar la cuenta de un rider con inscripciones, toma una foto/snapshot en BD de `riskAcceptedAt`, `riskAcceptanceVersion`, `medicalConsentAcceptedAt`, `medicalConsentVersion` de cada `EventRegistration` de ese rider | Anota los valores para comparar después | 👤 Manual (paso preparatorio de captura de datos sobre BD real; no hay lógica que verificar por sí solo, requiere acceso humano a la BD) | |
| 7.4 | Elimina la cuenta de ese rider (flujo completo exitoso) y consulta de nuevo la tabla `EventRegistration` en `events-ms` | `fullName = 'Usuario eliminado'`; `identificationNumber`, `birthDate`, `phone`, `email`, `residenceCity`, `eps`, `emergencyContactName`, `emergencyContactPhone` están en `null`; `shareMedicalInfo = false`; `allowOrganizerContact = false` | 👤 Manual (requiere ejecutar `DELETE /users/me` contra BD Postgres real y consultarla directamente; `registrations.service.anonymization.spec.ts` cubre el mismo efecto vía mocks de Prisma, pero la verificación contra BD real es un gap documentado en `handoffs/qa.md`) | |
| 7.5 | Compara los 4 campos de evidencia legal (`riskAcceptedAt`, `riskAcceptanceVersion`, `medicalConsentAcceptedAt`, `medicalConsentVersion`) contra el snapshot del paso 7.3 | Son idénticos a los valores antes del borrado (no se tocaron) | 👤 Manual (depende del snapshot real tomado en 7.4 sobre BD real; la no-modificación de estos campos ya está unit-testeada en `registrations.service.anonymization.spec.ts` pero la comparación contra datos reales requiere BD real) | |
| 7.6 | Verifica que `bloodType`, `vehicleId`, `status`, `eventId`, `userId`, `id` de la inscripción anonimizada | No cambiaron respecto al valor original | 👤 Manual (mismo flujo de verificación en BD real que 7.4/7.5; ya cubierto a nivel de payload mockeado por `registrations.service.anonymization.spec.ts` pero requiere confirmación contra datos reales) | |
| 7.7 | Invoca el `MessagePattern` `anonymizeRegistrationsByUserId` dos veces seguidas para el mismo `userId` (vía TCP directo a `events-ms`, sin pasar por `DELETE /users/me`) | Ninguna llamada lanza error; el `count` devuelto es el mismo en ambas; el estado de las filas tras la segunda llamada es idéntico al de la primera | 🤖✅ Auto-PASS (`rideglory-api/events-ms/src/registrations/registrations.service.anonymization.spec.ts :: is idempotent: a second call for the same userId does not throw and yields the same effect`) | ✅ |
| 7.8 | Con un proxy/logs de red activo, toca "Eliminar cuenta" en la app con un usuario sin eventos activos | La única llamada HTTP nueva disparada es la misma petición `GET` de eventos propios que ya usa la pantalla "Mis eventos"; no aparece ningún endpoint de "chequeo" nuevo | 👤 Manual (requiere inspección de tráfico HTTP real con Charles/Proxyman con app+backend corriendo; el handoff de QA confirma a nivel de código que se reusa `GetMyEventsUseCase`, pero la verificación de caja negra con proxy queda como gap manual explícito) | |
| 7.9 | En la BD de `events-ms`, ejecuta `\d "EventRegistration"` (o equivalente) contra el entorno donde se vaya a desplegar | Las 8 columnas PII aparecen como `Nullable`; `bloodType` y `fullName` siguen `NOT NULL` | 👤 Manual (requiere acceso directo a la BD del entorno de despliegue objetivo, no el Postgres local del agente Backend; ya verificado localmente por Backend en su handoff pero pendiente en el entorno real) | |
| 7.10 | Antes de aplicar la migración en el entorno compartido/producción, cuenta filas totales y filas con alguna de las 8 columnas PII en `NULL` antes de aplicar | Tras aplicar la migración, el conteo de filas totales no cambia y el conteo de `NULL` en filas preexistentes sigue siendo 0 (la migración es aditiva, no borra datos existentes) | 👤 Manual (verificación de despliegue de migración contra BD compartida/producción real, explícitamente marcada como pendiente y de alto riesgo — requiere verificación humana antes de desplegar, según `handoffs/backend.md`) | |
| 7.11 | Corre `dart analyze` sobre el proyecto Flutter completo | 0 errores; solo los `info`/`warning` preexistentes ya conocidos, ninguno nuevo relacionado a esta fase | 🤖✅ Auto-PASS (comando `dart analyze` sobre el proyecto Flutter completo) | ✅ |

---

## 👤 Solo para ti — pruebas manuales restantes

Lista corta de lo que queda por ejecutar a mano tras la automatización de qa-auto.

| # | Accion | Qué revisar | Por qué no se automatizó |
|---|--------|--------------|---------------------------|
| 3.2 | Sal del bottom sheet, ve a "Mis eventos" y cambia el evento a **Cancelado** o **Finalizado** | Que el evento cambie de estado correctamente en la lista | Navegación real a "Mis eventos" y edición de estado de evento en la app contra backend real; funcionalidad preexistente ajena a esta fase, requiere dispositivo/simulador real |
| 6A.1 | Con el evento nuevo ya creado (condición de carrera), confirma la eliminación de cuenta | Que responda con error/mensaje de eventos activos como organizador en vez de eliminar la cuenta | Requiere dos sesiones/dispositivos concurrentes contra backend real; no es simulable de forma determinista en un test unitario/widget aislado |
| 7.3 | Toma snapshot en BD de los 4 campos de evidencia legal antes de eliminar la cuenta del rider | Anotar los valores para comparar después | Paso preparatorio de captura de datos sobre BD real, sin lógica propia que verificar |
| 7.4 | Elimina la cuenta del rider y consulta `EventRegistration` en BD real | `fullName='Usuario eliminado'`; 8 campos PII en `null`; `shareMedicalInfo=false`; `allowOrganizerContact=false` | Requiere flujo completo contra Postgres real y consulta directa; el spec mockeado ya cubre el mismo efecto pero no reemplaza la verificación contra datos reales |
| 7.5 | Compara evidencia legal contra snapshot del paso 7.3 | Que sean idénticos a los valores antes del borrado | Depende del snapshot real tomado en 7.4 sobre BD real |
| 7.6 | Verifica `bloodType`/`vehicleId`/`status`/`eventId`/`userId`/`id` sin cambios | Que no cambiaron respecto al valor original | Mismo flujo de verificación en BD real que 7.4/7.5 |
| 7.8 | Con proxy/logs de red activo, toca "Eliminar cuenta" sin eventos activos | Que la única llamada nueva sea el mismo `GET` de eventos propios que usa "Mis eventos" | Requiere inspección de tráfico HTTP real (Charles/Proxyman) con app+backend corriendo |
| 7.9 | `\d "EventRegistration"` contra el entorno de despliegue | Que las 8 columnas PII sean `Nullable`; `bloodType`/`fullName` sigan `NOT NULL` | Requiere acceso directo a la BD del entorno de despliegue objetivo |
| 7.10 | Conteo de filas totales y NULL en las 8 columnas antes/después de aplicar la migración en entorno compartido/producción | Que el conteo de filas totales no cambie y el conteo de NULL en filas preexistentes siga en 0 | Verificación de despliegue de migración contra BD compartida/producción real, alto riesgo, requiere verificación humana antes de desplegar |

## 🚫 No automatizable en este entorno

| # | Accion | Cómo habilitarlo |
|---|--------|-------------------|
| 7.2 | Tras el 409 de `DELETE /users/me`, consultar BD de `vehicles-ms`/`events-ms`/`users-ms` para confirmar que nada cambió | Requiere acceso a una BD Postgres compartida real (no disponible para este agente QA). Para habilitarlo: correr el flujo contra un entorno con acceso a las 3 bases y ejecutar las consultas directamente, o dar acceso de solo-lectura al agente QA en una corrida futura |

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos 1.1–6C.1 marcados como ✅, y los casos técnicos 7.1–7.11 marcados como ✅ o verificados por el equipo de desarrollo |
| ⚠️ Aprobado con observaciones | Maximo 2 casos fallidos de baja severidad (por ejemplo, copy o detalle visual menor en la sección 6), con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones 1, 2, 3, 4 o 7 marcado como ❌ (bloqueo temprano de organizador, anonimización de PII, o integridad de evidencia legal comprometida) |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________

---

## 🤖 Resumen de automatización

| # | Estrategia | Test file | Resultado |
|---|-----------|-----------|-----------|
| 1.1 | Widget test (precondición) | `test/features/profile/presentation/widgets/profile_actions_list_delete_account_precondition_test.dart` | ✅ pass |
| 1.2 | Widget test | `test/features/profile/presentation/delete_account_confirmation_page_test.dart` | ✅ pass |
| 2.1 | Widget test (precondición) | `test/features/profile/presentation/widgets/profile_actions_list_delete_account_precondition_test.dart` | ✅ pass |
| 2.2 | Widget test | `test/features/profile/presentation/widgets/active_events_block_sheet_test.dart` | ✅ pass |
| 2.3 | Widget test | `test/features/profile/presentation/widgets/active_events_block_sheet_test.dart` | ✅ pass |
| 2.4 | Widget test (precondición) | `test/features/profile/presentation/widgets/profile_actions_list_delete_account_precondition_test.dart` | ✅ pass |
| 2.5 | Widget test (precondición) | `test/features/profile/presentation/widgets/profile_actions_list_delete_account_precondition_test.dart` | ✅ pass |
| 3.1 | Widget test (precondición) | `test/features/profile/presentation/widgets/profile_actions_list_delete_account_precondition_test.dart` | ✅ pass |
| 3.3 | Widget test (precondición, re-evaluación) | `test/features/profile/presentation/widgets/profile_actions_list_delete_account_precondition_test.dart` | ✅ pass |
| 4.1 | Widget test | `test/features/events/presentation/attendees/widgets/attendees_list_navigation_test.dart` | ✅ pass |
| 4.2–4.9 | Widget test (placeholder de anonimización) | `test/features/event_registration/presentation/registration_detail_page_test.dart` | ✅ pass |
| 4.10 | Widget test (bloodType no anonimizado) | `test/features/event_registration/presentation/registration_detail_page_test.dart` | ✅ pass |
| 4.11 | Widget test (enmascarado vs. placeholder) | `test/features/event_registration/presentation/registration_detail_page_test.dart` | ✅ pass |
| 5.1 | Widget test | `test/features/event_registration/presentation/widgets/registration_contact_trigger_test.dart` | ✅ pass |
| 6B.1 | Widget test (falla de red) | `test/features/profile/presentation/widgets/profile_actions_list_delete_account_precondition_test.dart` | ✅ pass |
| 6C.1 | Unit spec (NestJS) | `rideglory-api/events-ms/src/registrations/registrations.service.anonymization.spec.ts` | ✅ pass |
| 7.1 | Unit spec (NestJS) | `rideglory-api/api-gateway/src/users/account-deletion.service.spec.ts` | ✅ pass |
| 7.7 | Unit spec (NestJS, idempotencia) | `rideglory-api/events-ms/src/registrations/registrations.service.anonymization.spec.ts` | ✅ pass |
| 7.11 | Comando técnico | (comando) `dart analyze` | ✅ pass |

**Tests rechazados por el auditor Opus:** ninguno (auditoría "solid", 0 tests rechazados por vacíos).

### Cómo correr los tests generados

```bash
cd .
flutter test \
  test/features/profile/presentation/widgets/profile_actions_list_delete_account_precondition_test.dart \
  test/features/profile/presentation/delete_account_confirmation_page_test.dart \
  test/features/profile/presentation/widgets/active_events_block_sheet_test.dart \
  test/features/events/presentation/attendees/widgets/attendees_list_navigation_test.dart \
  test/features/event_registration/presentation/registration_detail_page_test.dart \
  test/features/event_registration/presentation/widgets/registration_contact_trigger_test.dart

dart analyze
```

Backend (desde `rideglory-api`, en los submódulos `api-gateway` y `events-ms` respectivamente):

```bash
npx jest src/users/account-deletion.service.spec.ts
npx jest src/registrations/registrations.service.anonymization.spec.ts
```

### Regresión e2e de inscripción (Patrol)

**Estado:** `fail` (regresión permanente, corre en cada corrida de qa-auto cuando hay device, independiente de los casos de este checklist).

`integration_test/registration_patrol_test.dart` existía y se corrió 3 veces en `emulator-5554` (dos intentos previos fallaron por inestabilidad del emulador: instrumentation process crashed / colgado en `isPermissionDialogVisible`, ruido de Play Store/Finsky en el AVD, no del app). Al 3er intento el wizard de inscripción completó TODOS sus pasos con éxito (contacto de emergencia → siguiente, selección de vehículo, confirmar inscripción, aceptar consentimiento médico/riesgo "Entiendo, inscribirme", y aparece "Tu solicitud está siendo revisada por el organizador."). Inmediatamente después, Gradle/UTP marcó el test global como FAILED por una `PlatformException` NO relacionada con el flujo bajo prueba: "Source 'rg-route-source' is not in style" lanzada por Mapbox (`StyleManager.setStyleSourceProperties`) tras la navegación, aparentemente un widget de mapa intentando actualizar una fuente de ruta en un estilo ya no cargado. No parece relacionado con eliminacion-cuenta-phase-03 (bloqueo de organizador/anonimización); es un bug separado de timing en el ciclo de vida del mapa Mapbox que hace fallar el test aunque el flujo de negocio (inscripción + consentimientos) sí se ejecutó y persistió bien. Reporte completo en `docs/exec-runs/eliminacion-cuenta-phase-03/REGRESSION_registration_patrol_20260711.md`. Se hizo pre-limpieza (DELETE, 0 filas) y limpieza final (DELETE, 1 fila borrada) de la inscripción PENDING de `qa1@gmail.com` en "Mi Evento"; BD queda idempotente. No se tocó código de producción, no se generaron tests nuevos, working tree queda sucio solo con el artefacto de reporte (`docs/exec-runs/eliminacion-cuenta-phase-03/REGRESSION_registration_patrol_20260711.md`) más un archivo preexistente no relacionado (`docs/exec-runs/eliminacion-cuenta-phase-02/PREFLIGHT.md`).

Comando:
```bash
patrol test -t integration_test/registration_patrol_test.dart -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json --dart-define=TEST_EMAIL=qa1@gmail.com --dart-define=TEST_PASSWORD=Test123.
```

**Verificación de BD post-e2e:** `pass`. `SELECT medicalConsentVersion, riskAcceptanceVersion, status FROM EventRegistration JOIN Event WHERE e.name='Mi Evento' AND er.email='qa1@gmail.com'` → `medicalConsentVersion=v0.1-2026-06`, `riskAcceptanceVersion=v0.1-2026-06`, `status=PENDING`. Ambas columnas de consentimiento NO nulas: la inscripción y sus consentimientos SÍ persistieron en el backend, aunque Patrol reportó FAILED por una excepción de Mapbox no relacionada (ver arriba). Verificación hecha excepcionalmente pese al `result='fail'` para diagnosticar si la persistencia real fue afectada; no lo fue — confirma que la inscripción persistió `medicalConsentVersion` + `riskAcceptanceVersion`, no solo que la UI mostró "pendiente". Cleanup final ejecutado (DELETE 1 fila) dejando la BD sin la inscripción de prueba.

### Siguientes pasos

- No hay 🤖❌ auto-fail en esta corrida, así que no hay bugs nuevos que investigar de este checklist.
- El fallo de Patrol (Mapbox `StyleManager.setStyleSourceProperties` / "Source 'rg-route-source' is not in style") es un bug preexistente ajeno a esta fase; queda registrado en `REGRESSION_registration_patrol_20260711.md` para que el equipo lo triage por separado.
- Para habilitar los 9 casos manuales y el 1 no automatizable: ejecutarlos con acceso a dispositivo/simulador real, backend real y BD Postgres compartida (ver secciones "👤 Solo para ti" y "🚫 No automatizable" arriba).
