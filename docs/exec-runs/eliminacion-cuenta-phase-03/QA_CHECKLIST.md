# Checklist de QA — Bloqueo de organizadores con eventos activos y anonimización de historial al eliminar cuenta

**Feature:** Eliminación de cuenta — bloqueo de organizador con eventos activos + anonimización de inscripciones (`EventRegistration`)
**Fases cubiertas:** Fase 1-2 (eliminación de cuenta, ya entregadas) + Fase 3 (bloqueo de organizador y anonimización de historial)
**Estado:** Pendiente de aprobacion PO

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

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 1.1 | Toca "Eliminar cuenta" en el perfil | La app navega directo a la pantalla de confirmación de eliminación de cuenta, sin ninguna pantalla intermedia ni demora perceptible |
| 1.2 | Observa la pantalla de confirmación | Ves el switch "entiendo lo que se borra" y el botón final de confirmar, como en el flujo normal de fases anteriores |

---

## 2. Bloqueo de organizador con eventos activos

> Inicia sesión con `qa2@gmail.com`. Antes de empezar, mueve "Mi Evento" (u otro evento propio) a estado **Borrador**. Ve a Perfil.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 2.1 | Toca "Eliminar cuenta" con el evento en estado **Borrador** | Aparece un bottom sheet de bloqueo (no la pantalla de confirmación de borrado); **nunca** ves el switch ni el botón final de confirmar |
| 2.2 | Verifica el contenido del bottom sheet | Muestra el nombre del evento bloqueante y un botón/CTA para ver tus eventos |
| 2.3 | Toca el CTA del bottom sheet | Navegas a la pantalla "Mis eventos" |
| 2.4 | Vuelve a Perfil, cambia el evento a estado **Programado** y repite el tap en "Eliminar cuenta" | El bottom sheet de bloqueo vuelve a aparecer, mostrando el evento en estado Programado |
| 2.5 | Cambia el evento a estado **En curso** y repite el tap en "Eliminar cuenta" | El bottom sheet de bloqueo vuelve a aparecer |

---

## 3. La precondición se re-evalúa siempre (no se cachea)

> Continúa con `qa2@gmail.com` desde la sección 2, con el evento aún en un estado activo.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 3.1 | Con el evento en estado activo, toca "Eliminar cuenta" | Ves el bottom sheet de bloqueo |
| 3.2 | Sal del bottom sheet, ve a "Mis eventos" y cambia ese evento a **Cancelado** o **Finalizado** | El evento cambia de estado correctamente en la lista |
| 3.3 | Vuelve a Perfil y toca "Eliminar cuenta" de nuevo (sin cerrar ni reabrir la app) | Esta vez navega directo a la pantalla de confirmación de eliminación de cuenta (ya no ves el bloqueo) |

---

## 4. Anonimización visible en la vista del organizador (cuenta de rider eliminada)

> Requiere que primero se haya eliminado la cuenta del rider de prueba con su inscripción activa (puedes coordinar con el equipo técnico para preparar este estado si no quieres borrar una cuenta real durante la prueba — ver sección 7 de verificaciones técnicas como alternativa). Luego inicia sesión como el organizador dueño del evento al que ese rider estaba inscrito.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 4.1 | Abre la lista de asistentes ("Attendees") del evento | El inscrito con cuenta eliminada aparece con el nombre "Usuario eliminado", sin errores ni pantalla en blanco |
| 4.2 | Toca ese inscrito para abrir el detalle de la inscripción (`RegistrationDetailPage`) | La pantalla abre sin crash |
| 4.3 | Revisa el campo de número de documento | Muestra "Cuenta eliminada" (no vacío, no "N/A", no `null` literal) |
| 4.4 | Revisa el campo de fecha de nacimiento | Muestra "Cuenta eliminada" |
| 4.5 | Revisa el campo de teléfono | Muestra "Cuenta eliminada" |
| 4.6 | Revisa el campo de email | Muestra "Cuenta eliminada" |
| 4.7 | Revisa el campo de ciudad de residencia | Muestra "Cuenta eliminada" |
| 4.8 | Revisa el campo de EPS | Muestra "Cuenta eliminada" |
| 4.9 | Revisa el campo de contacto de emergencia (nombre y teléfono) | Ambos muestran "Cuenta eliminada" |
| 4.10 | Revisa el campo de tipo de sangre | Sigue mostrando el tipo de sangre original (no se anonimiza) |
| 4.11 | Si el registro tiene `shareMedicalInfo` en falso, revisa los campos médicos enmascarados | Se ven como `••••` (el enmascarado normal de privacidad), sin mezclarse ni confundirse con el texto "Cuenta eliminada" |

---

## 5. Botón de contacto con inscrito de cuenta eliminada

> Continúa en `RegistrationDetailPage` del inscrito de cuenta eliminada de la sección 4.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 5.1 | Busca el botón de "Llamar" o "Contactar" para ese inscrito | El botón no aparece, o si aparece, tocarlo no produce crash ni intenta abrir una URL/llamada inválida |

---

## 6. Casos de borde

### 6A. Condición de carrera — evento creado justo después de pasar el bloqueo

> Con `qa2@gmail.com` sin eventos activos, toca "Eliminar cuenta" para llegar a la pantalla de confirmación. Sin salir de esa pantalla, en otro dispositivo/sesión crea un evento nuevo para ese mismo organizador.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 6A.1 | Con el evento nuevo ya creado, confirma la eliminación de cuenta en la pantalla de confirmación | El sistema responde con un error/mensaje indicando que no se puede eliminar por tener eventos activos como organizador (banner de error existente), en vez de eliminar la cuenta igual |

### 6B. Falla de red al tocar "Eliminar cuenta"

> Con cualquier organizador, desactiva la conexión de red (modo avión) antes de tocar "Eliminar cuenta".

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 6B.1 | Toca "Eliminar cuenta" sin conexión | Aparece un mensaje de error (SnackBar) indicando que no se pudo verificar; la app NO navega ni al bloqueo ni a la confirmación de borrado |

### 6C. Rider sin inscripciones elimina su cuenta

> Con un rider sin ninguna `EventRegistration`, elimina la cuenta siguiendo el flujo normal.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 6C.1 | Completa el flujo de eliminación de cuenta | La cuenta se elimina exitosamente sin errores, aunque no haya inscripciones que anonimizar |

---

## 7. Verificaciones tecnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso a la base de datos o logs del backend.

| # | Verificacion | Resultado esperado | ✅/❌ |
|---|-------------|--------------------|-------|
| 7.1 | Con un organizador con evento activo, llama `DELETE /users/me` directamente (Postman/curl) | Responde `409` con `error: "ACTIVE_EVENTS_AS_ORGANIZER"` y `activeEvents` no vacío |
| 7.2 | Tras el 409 anterior, consulta en BD `vehicles-ms`, `events-ms` (`EventRegistration`) y `users-ms` para ese usuario | Ningún dato cambió: ni vehículos, ni inscripciones, ni el registro del usuario |
| 7.3 | Antes de eliminar la cuenta de un rider con inscripciones, toma una foto/snapshot en BD de `riskAcceptedAt`, `riskAcceptanceVersion`, `medicalConsentAcceptedAt`, `medicalConsentVersion` de cada `EventRegistration` de ese rider | Anota los valores para comparar después |
| 7.4 | Elimina la cuenta de ese rider (flujo completo exitoso) y consulta de nuevo la tabla `EventRegistration` en `events-ms` | `fullName = 'Usuario eliminado'`; `identificationNumber`, `birthDate`, `phone`, `email`, `residenceCity`, `eps`, `emergencyContactName`, `emergencyContactPhone` están en `null`; `shareMedicalInfo = false`; `allowOrganizerContact = false` |
| 7.5 | Compara los 4 campos de evidencia legal (`riskAcceptedAt`, `riskAcceptanceVersion`, `medicalConsentAcceptedAt`, `medicalConsentVersion`) contra el snapshot del paso 7.3 | Son idénticos a los valores antes del borrado (no se tocaron) |
| 7.6 | Verifica que `bloodType`, `vehicleId`, `status`, `eventId`, `userId`, `id` de la inscripción anonimizada | No cambiaron respecto al valor original |
| 7.7 | Invoca el `MessagePattern` `anonymizeRegistrationsByUserId` dos veces seguidas para el mismo `userId` (vía TCP directo a `events-ms`, sin pasar por `DELETE /users/me`) | Ninguna llamada lanza error; el `count` devuelto es el mismo en ambas; el estado de las filas tras la segunda llamada es idéntico al de la primera |
| 7.8 | Con un proxy/logs de red activo, toca "Eliminar cuenta" en la app con un usuario sin eventos activos | La única llamada HTTP nueva disparada es la misma petición `GET` de eventos propios que ya usa la pantalla "Mis eventos"; no aparece ningún endpoint de "chequeo" nuevo |
| 7.9 | En la BD de `events-ms`, ejecuta `\d "EventRegistration"` (o equivalente) contra el entorno donde se vaya a desplegar | Las 8 columnas PII aparecen como `Nullable`; `bloodType` y `fullName` siguen `NOT NULL` |
| 7.10 | Antes de aplicar la migración en el entorno compartido/producción, cuenta filas totales y filas con alguna de las 8 columnas PII en `NULL` antes de aplicar | Tras aplicar la migración, el conteo de filas totales no cambia y el conteo de `NULL` en filas preexistentes sigue siendo 0 (la migración es aditiva, no borra datos existentes) |
| 7.11 | Corre `dart analyze` sobre el proyecto Flutter completo | 0 errores; solo los `info`/`warning` preexistentes ya conocidos, ninguno nuevo relacionado a esta fase |

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
