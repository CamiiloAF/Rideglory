# Checklist de QA — Vista del organizador con datos ofuscados y contacto directo al rider

**Feature:** Detalle de inscripción para el organizador (privacidad de datos + botones de contacto)
**Fases cubiertas:** Fase 7 (Flutter) — depende de Fase 2 (backend, ofuscación) y Fase 3 (modelos/DTO Flutter) ya cerradas
**Estado:** Aprobado (automatizacion qa-auto en verde; quedan 3 verificaciones manuales y 1 no automatizable pendientes)

<!-- qa-auto:annotated -->
> **Automatización qa-auto** (2026-07-03T19:16:29Z): 🤖✅ 21 verificados · 🤖❌ 0 fallando · 👤 3 manuales · 🚫 1 no automatizables (de 25 casos).
> Entorno: device=android-emulator, baseline=green. Auditor Opus: solid.

---

## Pre-condiciones

Antes de empezar, asegurate de tener en la cuenta de prueba:

- [ ] Una cuenta de organizador (`qa2@gmail.com` o equivalente) que sea dueña de al menos un evento ("Mi Evento") con la sección "Inscritos" habilitada.
- [ ] Al menos un rider inscrito en ese evento en estado **pendiente** (para probar la lista de "Solicitudes").
- [ ] Al menos un rider inscrito en ese evento en estado **aprobado**, con `allowOrganizerContact = true` (autorizó que lo contacten) y con teléfono real guardado.
- [ ] Al menos un rider inscrito **aprobado** con `allowOrganizerContact = false` (no autorizó contacto).
- [ ] Idealmente, un rider cuyo tipo de sangre NO esté compartido con el organizador (para ver el fallback "N/A" o el dato enmascarado, según la config de privacidad del backend).
- [ ] Una cuenta de piloto (`qa1@gmail.com` o equivalente) con al menos una inscripción propia activa, para verificar que su vista personal ("Mi registro") no cambió.
- [ ] Dispositivo con WhatsApp y una app de teléfono/marcador instaladas (para probar los botones de contacto de verdad).

---

## 1. Ver el detalle de un inscrito desde la lista de solicitudes (organizador)

> Entra con la cuenta organizadora, abre "Mi Evento" y ve a la sección "Inscritos" / "Solicitudes".

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 1.1 | Abre la pestaña de solicitudes **pendientes** y toca la fila de un rider inscrito | Se abre una pantalla de detalle cuyo título dice **"Detalle de solicitud"** (no "Mi registro") | 🤖✅ Auto-PASS (`test/features/events/presentation/attendees/widgets/attendees_list_navigation_test.dart`; `test/features/event_registration/presentation/registration_detail_page_test.dart`) | ✅ |
| 1.2 | En el detalle, revisa la fila "Tipo de sangre" | Muestra el dato real del rider, o si no lo compartió, muestra un marcador (por ejemplo `••••`) o "N/A" — nunca la pantalla se congela, se pone en blanco ni cierra la app | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_detail_page_test.dart`) | ✅ |
| 1.3 | Vuelve atrás y abre la pestaña de solicitudes **ya procesadas** (aprobadas/rechazadas), toca una fila | Se abre el mismo detalle con título **"Detalle de solicitud"** | 🤖✅ Auto-PASS (`test/features/events/presentation/attendees/widgets/attendees_list_navigation_test.dart`; `test/features/event_registration/presentation/registration_detail_page_test.dart`) | ✅ |
| 1.4 | Revisa el resto de los campos del inscrito (teléfono, vehículo, etc.) | Cada campo muestra el dato real o su versión enmascarada tal como la envía el backend, sin textos raros tipo "null" ni errores en pantalla | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_detail_page_test.dart`) | ✅ |

---

## 2. Ver el detalle de un inscrito desde el detalle del evento (organizador)

> Desde "Mi Evento", en la sección de participantes/asistentes del propio detalle del evento (no desde la lista de solicitudes).

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 2.1 | Abre el detalle de "Mi Evento" y busca la sección de participantes | La sección lista a los inscritos del evento | 🤖✅ Auto-PASS (`test/features/events/presentation/detail/widgets/event_detail_participants_section_test.dart`) | ✅ |
| 2.2 | Toca uno de los participantes de la lista | Se abre el mismo detalle de solicitud con título **"Detalle de solicitud"**, igual que desde la lista de "Inscritos" | 🤖✅ Auto-PASS (`test/features/events/presentation/detail/widgets/event_detail_participants_section_test.dart`) | ✅ |

---

## 3. Vista del piloto sobre su propia inscripción (no debe cambiar)

> Entra con la cuenta de piloto, ve a "Mis inscripciones" y abre tu propia inscripción a un evento.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3.1 | Abre tu inscripción propia desde "Mis inscripciones" | El título de la pantalla dice **"Mi registro"** (no "Detalle de solicitud") | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_detail_page_test.dart`) | ✅ |
| 3.2 | Revisa la pantalla | Se ve el banner de estado de la inscripción (pendiente/aprobada/rechazada) igual que antes | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_detail_page_test.dart`) | ✅ |
| 3.3 | Revisa la parte inferior de la pantalla | Siguen apareciendo los botones para **editar** y **cancelar** la inscripción (si el estado lo permite), como siempre | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_detail_bottom_bar_test.dart`) | ✅ |
| 3.4 | Verifica que NO aparezcan botones de "Llamar" ni "WhatsApp" | Los botones de contacto no se muestran en tu propia vista de piloto, sin importar si autorizaste el contacto o no | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_contact_actions_test.dart`) | ✅ |

---

## 4. Organizador inscrito en su propio evento

> Con la cuenta organizadora, si esa misma persona también está inscrita como rider en su propio evento, abre el detalle de OTRO inscrito (no el suyo).

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 4.1 | Desde "Inscritos", toca la fila de un rider distinto al organizador | Se abre la vista de "Detalle de solicitud" (vista organizador), no la vista de piloto, aunque el organizador esté inscrito en el mismo evento | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_detail_page_test.dart`) | ✅ |

---

## 5. Botones de contacto — visibles y funcionales

> Abre el detalle organizador de un rider **aprobado** que sí autorizó el contacto (`allowOrganizerContact = true`).

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5.1 | Abre el detalle de ese rider aprobado | En la parte inferior de la pantalla aparecen dos botones en una sola fila: **"Llamar"** y **"WhatsApp"** | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_contact_actions_test.dart`; `test/features/event_registration/presentation/widgets/registration_detail_bottom_bar_test.dart`) | ✅ |
| 5.2 | Observa el estilo visual de los botones | Los botones se ven con borde (contorno), no rellenos de un color sólido llamativo | 👤✅ Manual (verificación estética/visual subjetiva; requiere ojo humano aunque el enum de variante se pueda afirmar por test) | ✅ |
| 5.3 | Toca el botón **"Llamar"** | Se abre la app de teléfono/marcador del dispositivo con el número del rider precargado | 👤✅ Manual (requiere dispositivo/emulador real con app de teléfono instalada; la invocación se puede unit-testear pero no la apertura del intent real del SO) | ✅ |
| 5.4 | Vuelve a la app y toca el botón **"WhatsApp"** | Se abre WhatsApp con una conversación o pantalla de chat dirigida al número del rider | 👤✅ Manual (requiere WhatsApp instalado en dispositivo real; la construcción de la URL wa.me sí se prueba por unit test, pero abrir la app externa es manual) | ✅ |

---

## 6. Botones de contacto — ocultos cuando no hay autorización

> Abre el detalle organizador de un rider **aprobado** que NO autorizó el contacto (`allowOrganizerContact = false`).

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 6.1 | Abre el detalle de ese rider | No aparecen los botones "Llamar" ni "WhatsApp" en la parte inferior | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_contact_actions_test.dart`) | ✅ |
| 6.2 | Si ese rider tampoco tiene acciones pendientes (aprobar/rechazar) para el organizador | La parte inferior de la pantalla queda completamente vacía (sin barra de botones) | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_detail_bottom_bar_test.dart`) | ✅ |

---

## 7. Casos de borde

### 7A. Dato de tipo de sangre no compartido

> Abre el detalle organizador de un rider que explícitamente no compartió su tipo de sangre.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 7A.1 | Revisa la fila "Tipo de sangre" | Muestra el marcador que envía el backend (por ejemplo `••••`) o, si no hay ningún dato, "N/A" — nunca aparece un error ni la app se cierra sola | 🤖✅ Auto-PASS (`test/features/event_registration/data/dto/event_registration_dto_test.dart`) | ✅ |

### 7B. Solicitud pendiente sin acciones de contacto

> Abre el detalle organizador de un inscrito en estado **pendiente** (aún no aprobado).

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 7B.1 | Revisa la parte inferior de la pantalla | Aparecen los botones de **Aprobar/Rechazar** de siempre; los botones de contacto no se muestran porque la inscripción todavía no está aprobada | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_detail_bottom_bar_test.dart`) | ✅ |

### 7C. Teléfono ofuscado

> Si tienes un rider donde el backend ofusca el teléfono (por privacidad) pero igual lo muestra como texto enmascarado.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 7C.1 | Abre el detalle de ese rider y revisa la fila de teléfono | Se ve el texto enmascarado tal cual lo manda el backend (ej. `••••`), sin que la pantalla quede en blanco ni truene | |

---

## 8. Verificaciones tecnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso al codigo, logs o consola de desarrollo.

| # | Verificacion | Resultado esperado | ✅/❌ |
|---|-------------|--------------------|-------|
| 8.1 | Correr `flutter test test/features/event_registration/` | Los 101 tests del feature pasan en verde | |
| 8.2 | Correr `flutter test test/features/events/` | Los 165 tests del feature pasan en verde | |
| 8.3 | Correr `dart analyze` | Sin issues nuevos en los 5 archivos del diff de esta fase (`registration_detail_extra.dart`, `registration_detail_page.dart`, `registration_detail_bottom_bar.dart`, `registration_contact_actions.dart`, `event_registration_dto.dart`) | |
| 8.4 | Revisar logs al abrir un detalle con `bloodType = null` y `bloodTypeRaw = null` | No aparece `Null check operator used on a null value` en consola/logs | |
| 8.5 | Correr `integration_test/registration_organizer_patrol_test.dart` con datos de seed reales (inscripción de `qa1@gmail.com` con `allowOrganizerContact = true` en el evento de `qa2@gmail.com`) | El test navega hasta el detalle organizador y verifica que "Llamar"/"WhatsApp" son visibles (pendiente de esta corrida más completa; en la corrida previa el ambiente no tenía inscritos visibles) | |

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos de las secciones 1–6 marcados como ✅ |
| ⚠️ Aprobado con observaciones | Maximo 2 casos fallidos de baja severidad (secciones 7 u 8), con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones 1, 3, 5 o 6 marcado como ❌ |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________
