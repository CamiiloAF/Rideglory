# 00 — Intake

**Slug:** `legal-privacidad-edad`
**Timestamp:** 2026-06-19T19:15:45Z
**Issue:** #46

---

## Fuente

`docs/prds/prd-legal-privacidad-edad.md`

---

## Objetivo

Implementar validación de edad mínima (18 años hard cap) en el flujo de inscripción a eventos de motociclismo, un modelo de privacidad por capas para los datos de los inscritos (con ofuscación condicional en el backend según estado del evento y flags de consentimiento del rider), y mecanismos de exoneración de responsabilidad legal para el organizador y la plataforma.

---

## Alcance percibido

### Backend (`rideglory-api`)
- Validación de edad ≥ 18 años en `POST /events/:id/registrations` (hardcodeado, no configurable).
- Nuevos campos en el modelo de inscripción: `shareMedicalInfo: Bool`, `allowOrganizerContact: Bool`, `riskAcceptedAt: DateTime?`, `riskAcceptanceVersion: String?`.
- Nuevo campo en el modelo de evento: `organizerAcceptedResponsibilityAt: DateTime?`.
- Lógica de ofuscación condicional en el endpoint de detalle de inscripción (vista organizador): datos médicos solo legibles si evento está en curso + `shareMedicalInfo = true`; contacto de emergencia legible si evento en curso; teléfono legible si `allowOrganizerContact = true`; cédula/correo/ciudad solo durante SOS activo del rider.

### App Flutter
- **Flujo de inscripción a evento:**
  - Pantalla de aceptación de riesgos (waiver contextual §6.2) antes del submit — reemplaza el botón actual.
  - Bloque opt-in médico con `AppSwitchTile` (`shareMedicalInfo`).
  - Bloque opt-in de contacto con `AppSwitchTile` (`allowOrganizerContact`).
  - Validación local de edad antes de mostrar el formulario; mensaje l10n claro si no cumple o falta `birthDate`.
- **Flujo de creación de evento:**
  - Pantalla de aceptación de responsabilidad del organizador (§6.3) antes de publicar — sin campo de edad mínima.
- **Perfil médico del usuario:**
  - Pantalla de autorización de datos sensibles (§5.4 — Ley 1581) antes de completar el perfil médico; autorización separada de T&C.
- **`RegistrationDetailPage` (vista organizador):**
  - Siempre muestra todas las secciones; renderiza el valor tal como llega del backend (real u ofuscado `••••`).
  - Botones de acción WhatsApp (`wa.me`) y llamada (`tel://`) con `url_launcher` — solo activos cuando `allowOrganizerContact = true`.
- **Strings l10n:** todas las cadenas nuevas en `app_es.arb`.

### Fuera de scope
- No se modifica el proceso de registro inicial a la app.
- No se elimina ningún campo de `UserModel`.
- No se construye canal de mensajería interno (se usa WhatsApp/llamada).
- No se implementa la tarjeta de emergencia con QR público (nice-to-have futuro, §7).
- Redacción de texto definitivo de T&C y waiver (requiere abogado — se deja placeholder con versión provisional).

---

## Preguntas abiertas

1. **Texto del waiver y T&C:** El PRD deja explícito que el texto definitivo requiere abogado. ¿Se implementa con un placeholder de versión `v0` que luego se reemplaza por el texto aprobado, o se espera el texto legal antes de iniciar la fase de backend?

2. **`riskAcceptanceVersion` inicial:** ¿Cuál es el identificador de la versión inicial del waiver? (ej. `"v0.1-2026-06"`) — necesario para definir el schema de backend y el valor hardcodeado en el cliente.

3. **Estado "evento en curso":** El PRD lo equipara al criterio del tracking en vivo (evento iniciado por el organizador y aún no finalizado). ¿Hay un campo `status` o `startedAt`/`finishedAt` ya presente en el modelo de evento que se deba reusar, o hay que agregarlo? (relevante para el backend.)

4. **SOS activo:** La Capa B (cédula, correo, ciudad) se desbloquea durante "SOS activo del rider". ¿Este estado ya es accesible desde el endpoint de detalle de inscripción, o requiere integración adicional con el servicio de tracking/SOS?

5. **Pantalla de autorización Ley 1581 (§5.4):** ¿Se muestra una sola vez al completar el perfil médico por primera vez, o en cada evento donde se comparta la información? El PRD la sitúa en el flujo de perfil médico, pero el consentimiento expreso bajo Ley 1581 podría requerirse por evento.

6. **Ofuscación en backend vs. null:** Para campos médicos cuando `shareMedicalInfo = false`, el PRD indica mostrar "No compartido" (no `••••`). ¿El backend retorna un string literal `"No compartido"` o un flag/null que la app interpreta? (decisión de contrato de API.)

7. **Flavor de despliegue:** ¿Los cambios de backend se deben desplegar en staging antes de implementar la UI en Flutter, o se desarrollan en paralelo con contratos de API acordados primero?
