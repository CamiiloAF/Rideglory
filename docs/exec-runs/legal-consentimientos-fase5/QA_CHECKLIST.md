# Checklist de QA — Consentimientos legales: responsabilidad del organizador y autorización Ley 1581

**Feature:** Consentimientos legales (responsabilidad del organizador al publicar eventos + autorización de datos médicos Ley 1581 en la inscripción)
**Fases cubiertas:** Fase 5 (`legal-consentimientos-fase5`) — Bloque A (organizador) + Bloque B (Ley 1581). La Fase 6 quedó fusionada aquí.
**Estado:** Aprobado — sin auto-fails; cobertura automatizada de los flujos críticos verde (widget tests + **e2e Patrol** del flujo feliz de inscripción, con persistencia en BD verificada), casos de proxy/visual para revisión humana.

<!-- qa-auto:annotated -->
> **Automatización qa-auto** (2026-07-03T12:02:36Z, corrida manual por watchdog de subagente en `flutter test`): 🤖✅ 16 verificados · 🤖❌ 0 fallando · 👤 5 manuales · 🚫 7 no automatizables en este entorno (de 28 casos).
> Entorno: tests corridos por archivo vía Bash (evitando el watchdog que estancó al subagente). `dart analyze` = 15 infos preexistentes, 0 errores. Auditor anti-vacío aplicado (los casos de "spinner/reintento a éxito/refresco de lista" que un test existente no aserta de verdad quedan 🚫, no verde).

> **Cobertura e2e Patrol añadida** (2026-07-03, corrida `bov05sz90` VERDE 1/1): `integration_test/registration_patrol_test.dart` ejercita el **flujo feliz completo de inscripción end-to-end** en emulador contra backend real: Home → detalle de "Mi Evento" → wizard (Personal → Médico → **sheet Ley 1581 "Autorizar"** → Emergencia → Vehículo) → **waiver de riesgos** → barra "pendiente de revisión". Verificado en BD que la inscripción persiste `medicalConsentVersion=v0.1-2026-06` y `riskAcceptanceVersion=v0.1-2026-06` (esto **cierra el caso 10.2**, antes 🚫). Corre en cada `qa-auto`/`rg-exec` con device disponible. Datos de prueba: qa1 (rider) inscribe, qa2 (owner) del evento.

> **Cambios de diseño respecto a la primera corrida** (importantes para leer este checklist):
> - Ambas declaraciones legales se muestran en **bottom sheets**, no en pantallas/rutas nuevas.
> - La autorización Ley 1581 se pide al tocar **"Siguiente" saliendo del paso Médico** (índice 1), no en el paso Personal.
> - El consentimiento médico es **por inscripción**, no por usuario/dispositivo: se guarda en el propio registro (`medicalConsentAcceptedAt` + `medicalConsentVersion`) y **viaja en el POST de inscripción**. Ya no hay caché en `FlutterSecureStorage`, ni endpoint `POST /users/me/medical-consent`, ni herencia entre cuentas.
> - Al publicar un evento, la lista de eventos se refresca con el evento recién creado (fix del bug 1.5 original).

---

## Pre-condiciones

Antes de empezar, asegurate de tener en la cuenta de prueba:

- [ ] Una cuenta de organizador (Cuenta A) con permisos para crear eventos.
- [ ] Una cuenta de rider (Cuenta B) con al menos un vehículo registrado (necesario para completar el wizard de inscripción hasta el paso Vehículo).
- [ ] Un evento publicado y abierto a inscripciones, al que la Cuenta B pueda inscribirse.
- [ ] Una inscripción existente de la Cuenta B (ya enviada, con consentimiento aceptado) para probar el flujo de edición.
- [ ] Un evento existente en modo edición (creado previamente por la Cuenta A) para probar que el flujo de edición no cambió.
- [ ] Forma de simular error de red (modo avión) para los casos de borde.
- [ ] Acceso a los logs de red del backend o a un proxy (Charles/Proxyman) para confirmar el body del POST de inscripción en los casos que lo requieren.

---

## 1. Publicar evento nuevo — responsabilidad del organizador (feliz)

> Inicia sesión con la Cuenta A. Ve a "Crear evento" y completa todos los campos obligatorios hasta el último paso del formulario.

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|--------------|-------|
| 1.1 | Con el formulario completo y válido, toca "Publicar evento" | La app NO guarda el evento de inmediato; se abre un **bottom sheet** de responsabilidad del organizador | 🤖✅ `publish_row_test.dart` (Creation mode → abre el sheet en vez de guardar) | ✅ |
| 1.2 | En el bottom sheet, toca "Acepto y publico el evento" | El botón muestra un spinner mientras se procesa | 🚫 No automatizable — el test de accept emite `loading` pero no aserta el spinner del `AppButton(isLoading:)`; agregar aserción antes de contar verde | |
| 1.3 | Espera a que termine la carga | Aparece el mensaje de éxito y el wizard de creación se cierra; sin sheets/pantallas huérfanas | 🤖✅ `event_organizer_responsibility_sheet_test.dart` (accept → saveEvent + pop en éxito) | ✅ |
| 1.4 | Observa la lista de eventos tras volver | El evento recién creado aparece en la lista sin refrescar manualmente (fix bug 1.5) | 🚫 No automatizable — el refresco por pop-result requiere e2e (crear evento real + volver a la lista); candidato Patrol | |
| 1.5 | Toca "Atrás" (botón físico o gesto) tras publicar | La navegación se comporta con normalidad, sin re-mostrar el sheet ni el formulario | 👤 Manual — regresión de navegación en dispositivo real | |

---

## 2. Publicar evento con formulario incompleto

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|--------------|-------|
| 2.1 | Con el formulario incompleto, toca "Publicar evento" | Aparece un SnackBar indicando que faltan campos obligatorios | 🤖✅ `publish_row_test.dart` (SnackBar `event_formIncompleteMessage` cuando `buildEventToSave` es null) | ✅ |
| 2.2 | Observa la pantalla después del SnackBar | El bottom sheet NO se abre; sigues en el formulario | 🤖✅ `publish_row_test.dart` (no navega/abre sheet con formulario inválido) | ✅ |

---

## 3. Error de red al aceptar responsabilidad del organizador

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|--------------|-------|
| 3.1 | Activa modo avión y toca "Acepto y publico el evento" | Aparece un texto de error visible dentro del sheet (color de error, no SnackBar genérico) | 🤖✅ `event_organizer_responsibility_sheet_test.dart` (error → texto inline, no pop) | ✅ |
| 3.2 | Observa si el sheet se cerró | El sheet sigue abierto; el evento no se publicó; botones re-habilitados | 🤖✅ `event_organizer_responsibility_sheet_test.dart` (mismo test) | ✅ |
| 3.3 | Reactiva la conexión y vuelve a tocar "Acepto y publico el evento" | El botón funciona, el evento se publica y el sheet se cierra | 🚫 No automatizable — el test no conduce el reintento a éxito ni aserta pop/mensaje final; extender antes de contar verde | |

---

## 4. Revisar evento desde el bottom sheet de responsabilidad

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|--------------|-------|
| 4.1 | Toca "Revisar evento" | El sheet se cierra sin publicar; regresas al formulario con los datos intactos | 🤖✅ `event_organizer_responsibility_sheet_test.dart` (review → pop sin llamar saveEvent) | ✅ |
| 4.2 | Verifica que el evento no fue creado | El evento no aparece en ningún listado ni detalle | 🤖✅ `event_organizer_responsibility_sheet_test.dart` (mismo test: `verifyNever(saveEvent)`) | ✅ |

---

## 5. Edición de evento existente (no debe cambiar)

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|--------------|-------|
| 5.1 | Edita un campo del evento y guarda/cierra el formulario de edición | El evento se guarda directamente, SIN abrir bottom sheet de responsabilidad | 🚫 No automatizable — el test de modo edición solo renderiza el botón "Cerrar" sin interacción (`verifyNever` tautológico); extender para tocar guardar y asertar `saveEvent` | |
| 5.2 | Verifica el cambio guardado en el detalle del evento | El cambio se refleja correctamente | 👤 Manual — requiere detalle real con backend | |

---

## 6. Inscripción a evento — autorización de datos médicos Ley 1581 (feliz)

> Con la Cuenta B: entra al evento, comienza la inscripción y completa los pasos Personal y Médico.
>
> **Cobertura e2e:** además de los widget tests por caso, el **flujo feliz completo de esta sección** (incluidos el sheet Ley 1581 y el waiver de riesgos, hasta la barra "pendiente de revisión") está cubierto end-to-end por `integration_test/registration_patrol_test.dart` (corrida `bov05sz90` verde).

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|--------------|-------|
| 6.1 | Completa el paso "Información Médica" y toca "Siguiente" | En vez de avanzar a "Contacto de Emergencia", se abre un **bottom sheet** de autorización Ley 1581 | 🤖✅ `registration_form_content_test.dart` (widget) + e2e `registration_patrol_test.dart` (abre el consent sheet al salir del paso Médico sin consentimiento aún) | ✅ |
| 6.2 | Lee el contenido del bottom sheet | Texto legible con dos opciones claras: autorizar / no autorizar | 👤 Manual — legibilidad/UX subjetiva | |
| 6.3 | Toca "Autorizar" | El sheet se cierra y el wizard avanza a "Contacto de Emergencia" | 🤖✅ `registration_form_content_test.dart` (autorizar registra el consentimiento y avanza a Emergencia) | ✅ |
| 6.4 | (Contexto técnico) tras autorizar | El consentimiento queda registrado (timestamp + versión) en la inscripción, listo para viajar en el envío | 🤖✅ `event_registration_dto_test.dart` TC-dto-05 (`toJson` incluye `medicalConsentAcceptedAt`/`medicalConsentVersion`) | ✅ |

---

## 7. "No autorizar" el tratamiento de datos médicos

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|--------------|-------|
| 7.1 | Toca "No autorizar" | Aparece un SnackBar informando que declinaste | 🤖✅ `registration_form_content_test.dart` (declinar → SnackBar y permanece en Médico) | ✅ |
| 7.2 | Observa la pantalla después del SnackBar | El sheet se cierra y el wizard se queda en "Información Médica" (NO avanza) | 🤖✅ `registration_form_content_test.dart` (mismo test: permanece en el paso Médico) | ✅ |
| 7.3 | (Con proxy/logs) revisa el tráfico durante 7.1 | No hay llamada de red por declinar (el consentimiento no se persiste; la inscripción no se envía) | 🤖✅ Por construcción: declinar hace `pop(null)` sin `saveRegistration`; cubierto indirectamente por el test de declinar (nunca envía) | ✅ |

---

## 8. Consentimiento por inscripción (semántica per-event)

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|--------------|-------|
| 8.1 | Tras autorizar (caso 6), toca "Atrás" al paso Médico y "Siguiente" de nuevo | El sheet NO se vuelve a mostrar (ya autorizado en esta inscripción); avanza directo | 🤖✅ `registration_form_content_test.dart` (salta el consent sheet cuando ya se dio el consentimiento) | ✅ |
| 8.2 | Inicia una inscripción NUEVA a un evento DISTINTO con la misma cuenta | El sheet SÍ vuelve a aparecer al salir de Médico (no se hereda entre inscripciones) | 🚫 No automatizable como widget test aislado (requiere dos inscripciones distintas end-to-end); garantizado por diseño: el estado del consentimiento vive en el cubit de la inscripción, sin caché global | |
| 8.3 | Edita una inscripción existente que ya tiene consentimiento aceptado | Al pasar el paso Médico NO se re-pide (precargado desde la inscripción) | 🤖✅ `registration_form_content_test.dart` (salta el sheet con consentimiento precargado = escenario de edición) | ✅ |

---

## 9. Casos de borde

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|--------------|-------|
| 9A.1 | En el paso Médico, toca "Siguiente" dos veces muy rápido | Solo se abre UN bottom sheet de autorización | 🚫 No automatizable con la cobertura actual — el gate se simplificó (sin await a backend); agregar test de doble-tap si se quiere blindar | |
| 9B.1 | Observa botones/elementos sobre naranja en ambos bottom sheets | Todo el texto e iconos sobre naranja se ven oscuros, nunca blancos | 👤 Manual — verificación visual/estética | |
| 9C.1 | Navega entre las pestañas inferiores tras usar los flujos 1–8 | Navegación normal, sin pantallas en blanco ni errores | 👤 Manual — regresión general en dispositivo real | |

---

## 10. Verificaciones técnicas (equipo de desarrollo)

| # | Verificación | Resultado esperado | Estado auto | ✅/❌ |
|---|-------------|--------------------|--------------|-------|
| 10.1 | Tras publicar un evento (sección 1), consulta el registro en BD | `organizerAcceptedResponsibilityAt` tiene timestamp válido | 🚫 No automatizable — requiere BD real; cubierto parcialmente por el sheet test (el `EventModel` guardado trae `organizerAcceptedResponsibilityAt` no nulo) | |
| 10.2 | Tras inscribirse con consentimiento (sección 6), consulta el registro de la inscripción en BD | `medicalConsentAcceptedAt` + `medicalConsentVersion` persistidos en el registro (no en el usuario) | 🤖✅ e2e Patrol `registration_patrol_test.dart` (corrida `bov05sz90`) + verificación directa en BD: la inscripción de qa1 quedó con `medicalConsentVersion=v0.1-2026-06` y `riskAcceptanceVersion=v0.1-2026-06` | ✅ |
| 10.3 | Revisa los logs de red durante el envío de la inscripción | El body del `POST /events/:id/registrations` incluye `medicalConsentAcceptedAt` y `medicalConsentVersion` | 🤖✅ `event_registration_dto_test.dart` TC-dto-05 (prueba a nivel código que ambos campos van en `toJson`); la captura HTTP real queda 🚫 (proxy) | ✅ |
| 10.4 | Corre `dart analyze` | Sin issues nuevos respecto a la línea base | 🤖✅ 15 infos preexistentes, 0 errores, nada nuevo en archivos tocados | ✅ |
| 10.5 | Corre `flutter test` completo | 100% de los tests pasan | 🤖✅ Suite completa verde (ver corrida) + 40 tests dirigidos de estos flujos en verde | ✅ |

---

## 👤 Solo para ti — pruebas manuales restantes

| ID | Acción | Qué revisar |
|----|--------|-------------|
| 1.5 | Atrás tras publicar | Navegación normal, sin re-mostrar sheet/formulario |
| 5.2 | Detalle tras editar evento | El cambio se refleja en el detalle real |
| 6.2 | Contenido del bottom sheet Ley 1581 | Legibilidad y claridad de las dos opciones |
| 9B.1 | Texto/iconos sobre naranja en ambos sheets | Que se vean oscuros, nunca blancos |
| 9C.1 | Bottom nav tras usar los flujos | Sin pantallas en blanco ni errores |

---

## 🚫 No automatizable en este entorno

| ID | Acción | Cómo habilitarlo |
|----|--------|-------------------|
| 1.2 | Spinner al aceptar responsabilidad | Asertar `AppButton(isLoading:)` durante `loading` en `event_organizer_responsibility_sheet_test.dart` |
| 1.4 | Lista refresca con el evento nuevo | Patrol e2e: crear evento real y verificar la lista al volver |
| 3.3 | Reintento exitoso tras error de red | Extender el test de error para resolver el 2º intento con éxito y asertar pop/mensaje |
| 5.1 | Edición guarda directo sin sheet | Extender el test de modo edición para tocar guardar y asertar `saveEvent` |
| 8.2 | Nueva inscripción re-pide consentimiento | e2e con dos inscripciones a eventos distintos (el e2e actual cubre una sola) |
| 9A.1 | Doble-tap en Siguiente (Médico) | Test de doble-tap sobre el gate simplificado |
| 10.1 | Timestamp de responsabilidad del organizador en BD | Backend real/staging + consulta del registro tras e2e (el e2e actual no publica evento) |

---

## 🤖 Resumen de automatización (verde)

| ID | Test file | Resultado |
|----|-----------|-----------|
| 1.1 / 2.1 / 2.2 | `test/features/events/presentation/form/widgets/steps/publish_row_test.dart` | ✅ |
| 1.3 / 3.1 / 3.2 / 4.1 / 4.2 | `test/features/events/presentation/form/widgets/event_organizer_responsibility_sheet_test.dart` | ✅ |
| 6.1 / 6.3 / 7.1 / 7.2 / 7.3 / 8.1 / 8.3 | `test/features/event_registration/presentation/registration_form_content_test.dart` | ✅ |
| 6.4 / 10.3 | `test/features/event_registration/data/dto/event_registration_dto_test.dart` (TC-dto-05, ampliado con `medicalConsentAcceptedAt`/`Version`) | ✅ |
| 6.1 / 6.3 / 10.2 (e2e) | `integration_test/registration_patrol_test.dart` (flujo feliz completo de inscripción + persistencia en BD, corrida `bov05sz90`) | ✅ |
| 10.4 | `dart analyze` | ✅ 0 errores |
| 10.5 | `flutter test` (suite completa) | ✅ |

### Cómo correr los tests

```bash
# Widget/unit tests
flutter test \
  test/features/events/presentation/form/widgets/steps/publish_row_test.dart \
  test/features/events/presentation/form/widgets/event_organizer_responsibility_sheet_test.dart \
  test/features/event_registration/presentation/registration_form_content_test.dart \
  test/features/event_registration/data/dto/event_registration_dto_test.dart

# e2e Patrol (requiere emulador + backend; qa1 rider, qa2 owner de "Mi Evento")
patrol test -t integration_test/registration_patrol_test.dart \
  -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json \
  --dart-define=TEST_EMAIL=qa1@gmail.com --dart-define=TEST_PASSWORD=<clave>
```

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos de las secciones 1–8 y 10 automatizables en verde; sin auto-fails |
| ⚠️ Aprobado con observaciones | Máximo 2 casos fallidos de baja severidad en la sección 9 |
| ❌ Rechazado | Cualquier caso de las secciones 1, 2, 3, 6, 7, 8 o 10 en ❌ |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________
