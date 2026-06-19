# 02 — PO Proposal

**Slug:** `legal-privacidad-edad`
**Timestamp:** 2026-06-19T19:19:36Z
**Issue:** #46

---

## Fases propuestas

| # | Título | Goal (valor para el usuario) | Resumen |
|---|--------|------------------------------|---------|
| 1 | Contratos y schema de backend | El backend acepta y persiste los nuevos campos legales | Migración de Prisma: 4 campos en `EventRegistration` (`shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`) y 1 en `Event` (`organizerAcceptedResponsibilityAt`). Actualización de `rideglory-contracts` (`CreateRegistrationDto`, `UpdateRegistrationDto`, `EventRegistrationDto`, `EventDto`). Sin lógica de negocio aún — solo persistencia y contratos. |
| 2 | Validación de edad y ofuscación condicional | Un menor no puede inscribirse; el organizador solo ve datos médicos cuando corresponde | Validación de edad ≥ 18 en `POST /events/:id/registrations` (hardcoded). Lógica de ofuscación condicional en el endpoint de detalle de inscripción: datos médicos → solo si evento en curso + `shareMedicalInfo = true`; contacto emergencia → solo si evento en curso; teléfono → solo si `allowOrganizerContact = true`; cédula/correo/ciudad → solo durante SOS activo. Requiere exponer `EventState` y `sosTriggeredAt` al response. |
| 3 | Modelos y DTOs Flutter | La app puede serializar y enviar los campos legales al backend | Extensión de `EventRegistrationModel` y `EventRegistrationDto` con los 4 campos nuevos. Extensión de `EventModel` con `organizerAcceptedResponsibilityAt`. Actualización de `RegistrationService.create()` y `update()` para incluir los nuevos campos en el body. `dart analyze` y `build_runner` sin errores. |
| 4 | Waiver del rider en el flujo de inscripción | Un rider no puede completar una inscripción sin aceptar los riesgos y elegir sus preferencias de privacidad | Pantalla de waiver contextual (§6.2) reemplaza el botón de submit en el wizard de inscripción: texto de riesgos con nombre del organizador, botón "Entiendo, inscribirme". Dos bloques `AppSwitchTile` en el paso médico: `shareMedicalInfo` y `allowOrganizerContact`. `RegistrationFormCubit` incluye `riskAcceptedAt` y `riskAcceptanceVersion` al construir el model. Validación local de edad antes de mostrar el formulario con mensajes l10n. |
| 5 | Aceptación de responsabilidad del organizador | Un organizador no puede publicar un evento sin aceptar su responsabilidad legal | Pantalla de responsabilidad del organizador (§6.3) se interpone entre el botón "Publicar" y el guardado del evento. `organizerAcceptedResponsibilityAt` se envía en el payload de creación/publicación. La pantalla no aparece al guardar borrador. |
| 6 | Autorización Ley 1581 en perfil médico | El usuario da consentimiento expreso antes de que sus datos médicos sean tratados | Pantalla de autorización separada (no T&C generales) que aparece la primera vez que el usuario intenta completar o editar su perfil médico. Declara propósito, datos tratados y destinatarios. El usuario debe presionar "Autorizar" para continuar. Consentimiento se persiste localmente y en backend (campo por definir con Architect). |
| 7 | Vista del organizador con ofuscación y contacto | El organizador ve los datos de cada inscrito según las reglas de privacidad y puede contactarlo con un tap | `RegistrationDetailPage` renderiza todos los campos tal como llegan del backend (incluyendo valores ofuscados `••••` o "No compartido"). Se agregan botones de acción "Llamar" y "WhatsApp" condicionados a `allowOrganizerContact = true` usando `UrlLauncherHelper`. Todas las strings nuevas en `app_es.arb`. |

---

## Supuestos

1. **Texto del waiver con placeholder v0:** Se implementa el flujo completo con texto provisional (`riskAcceptanceVersion = "v0.1-2026-06"`). El texto definitivo lo proveerá un abogado posteriormente y se actualizará sin cambios de código via string en `app_es.arb` o URL estática.

2. **"Evento en curso" = `EventState.inProgress`:** El criterio de desofuscación de datos médicos se basa en el campo `state` del evento, ya existente en `EventModel` con valor `inProgress`. No se requiere campo nuevo.

3. **`sosTriggeredAt` ya existe en Prisma:** El campo existe en el schema de `events-ms` pero no está mapeado en Flutter. Se mapea en Fase 3 como parte de `EventModel` para que el backend pueda usarlo como condición de ofuscación de Capa B.

4. **Ofuscación 100% en backend:** La app Flutter no contiene lógica de ofuscación. Renderiza exactamente lo que el backend retorna. Si el backend retorna `"••••"`, la app lo muestra; si retorna el valor real, lo muestra.

5. **"No compartido" vs `••••`:** Para campos médicos cuando `shareMedicalInfo = false`, el backend retorna el string `"No compartido"` (no `null` ni `"••••"`), para distinguir semánticamente de campos que el rider sí compartió pero el evento no está en curso.

6. **Autorización Ley 1581 — una sola vez:** La pantalla de autorización de datos médicos se muestra una única vez cuando el usuario intenta completar su perfil médico por primera vez. Se persiste el timestamp de autorización; en eventos posteriores no se repite (el consentimiento ya fue otorgado).

7. **Desarrollo paralelo con contratos acordados:** Backend y Flutter se desarrollan con los contratos del Fase 1 como base común. No es necesario que el backend esté desplegado para avanzar en Flutter.

8. **Botones de contacto solo para el organizador:** Los botones "Llamar" y "WhatsApp" en `RegistrationDetailPage` solo se renderizan en la vista del organizador, no en la vista del rider sobre su propia inscripción.

---

## Riesgos

1. **Texto legal no disponible a tiempo:** Si el abogado no entrega el texto del waiver y la Ley 1581 antes de que las fases de UI estén listas, el flow completo queda bloqueado en producción (aunque técnicamente funcional). Mitigación: usar placeholder `v0` con texto genérico mientras se obtiene asesoría.

2. **Definición de "SOS activo" puede cambiar:** La Capa B depende del estado `sosTriggeredAt` que existe en Prisma pero cuya lógica de "SOS activo" no está formalmente especificada en el scope de este plan. Si la integración con el servicio de tracking/SOS es compleja, la Capa B puede simplificarse o diferirse sin bloquear el resto del plan.

3. **Ofuscación retroactiva:** Las inscripciones existentes no tienen `shareMedicalInfo` ni `allowOrganizerContact`. El backend debe asumir un default seguro (`false`) para inscripciones pre-migración. Si el default se aplica incorrectamente, el organizador podría perder acceso a datos médicos de rodadas activas.

4. **`rideglory-contracts` es un submódulo:** Cambiar los contratos requiere PR en el repo de contratos + rebuild + `pnpm install` en cada microservicio. Si este proceso falla o tarda, bloquea la Fase 1 y todo el plan.

5. **`RegistrationDetailPage` no distingue rol:** La página actual no tiene mecanismo explícito para saber si quien la ve es el organizador o el rider. Los botones de contacto y la ofuscación solo tienen sentido en la vista del organizador. Se debe confirmar con el Architect si ya existe un mecanismo de rol o hay que agregarlo.

6. **Consentimiento Ley 1581 en backend:** El plan asume que el consentimiento médico se persiste localmente en `SharedPreferences`. Si el Architect determina que debe quedar en el backend (tabla de consentimientos), la Fase 6 se vuelve más pesada.

---

## Criterios de éxito globales

- Un usuario menor de 18 años que intenta inscribirse a un evento recibe un mensaje claro y no puede completar la inscripción, ni en la app ni a través del backend.
- Un rider puede inscribirse eligiendo explícitamente si comparte su información médica y si permite contacto del organizador; la elección queda persistida en el backend.
- El organizador ve los campos de inscripción con valores reales u ofuscados según las reglas del PRD: datos médicos solo en evento en curso, teléfono solo si el rider lo autorizó, cédula/correo/ciudad solo en SOS.
- Un organizador no puede publicar un evento sin aceptar la declaración de responsabilidad; el timestamp queda registrado.
- Un usuario no puede completar su perfil médico sin una autorización Ley 1581 explícita y separada de los T&C generales.
- `dart analyze` pasa sin errores en Flutter; `build_runner` genera sin conflictos; contratos compilados en todos los microservicios afectados.
- Todos los strings de UI están en `app_es.arb`; no hay strings hardcodeados en widgets.
