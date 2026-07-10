# Checklist de QA — Feature Events

**Feature:** Events (`lib/features/events/`) — CRUD de eventos, wizard de creación, publicación, ciclo de vida (draft→scheduled→inProgress→finished), tracking en vivo, SOS, gestión de asistentes, asistentes IA (descripción + portada)
**Doc de referencia:** `docs/features/events.md` (actualizada 2026-07-04)
**Estado:** Pendiente de ejecución

---

## Pre-condiciones

Antes de empezar, asegurate de tener:

- [ ] Cuenta organizadora `qa2@gmail.com` (password `Test123.`), dueña del evento **"Mi Evento"**.
- [ ] Cuenta rider `qa1@gmail.com` (password `Test123.`), sin eventos propios pero con al menos una inscripción a "Mi Evento".
- [ ] "Mi Evento" en estado `scheduled` al iniciar la sesión de QA (si quedó `inProgress`/`finished` de una corrida anterior, resetear en BD o crear un evento nuevo para las pruebas de ciclo de vida/tracking/SOS).
- [ ] "Mi Evento" con al menos una inscripción en estado **pendiente** (para la sección de gestión de asistentes) — se genera re-inscribiendo a `qa1@gmail.com` si una corrida previa ya la procesó.
- [ ] Emulador/dispositivo con **al menos una imagen en la galería** (Photo Picker nativo) — requerido por el paso de portada del wizard de creación:
  ```
  adb push sample.jpg /sdcard/Pictures/sample.jpg
  adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/sample.jpg
  ```
- [ ] Emulador con **ubicación GPS simulada** (fix rápido) para las pruebas de tracking en vivo y SOS (`adb emu geo fix <lng> <lat>` o equivalente).
- [ ] Conexión a red estable para probar el asistente de IA (descripción) — y, opcionalmente, forma de simular sin red / cuota agotada para los casos de borde de IA.
- [ ] Backend (`rideglory-api`) corriendo con el gateway de tracking (`/tracking/ws`) accesible.
- [ ] Un segundo dispositivo/emulador es **opcional pero recomendado** para casos de SOS multi-usuario (ver sección 8, casos marcados 🚫).

---

## 1. Lista de eventos y filtros

> Tab "Eventos" (`/events`) y "Mis eventos" (`/events/mine`).

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 1.1 | Abre el tab "Eventos" | Se lista el feed de eventos publicados (`scheduled`/`inProgress`/`finished`), sin errores en pantalla | 🤖✅ Auto-PASS (`integration_test/events_patrol_test.dart`) | |
| 1.2 | Con la lista vacía (sin filtros), revisa el estado vacío | Se muestra el mensaje de "no hay eventos" original (no el de "filtros sin resultados") | 🤖✅ Auto-PASS (`test/features/events/presentation/list/widgets/events_page_view_test.dart` TC-2-22) | |
| 1.3 | Aplica un filtro que no matchee ningún evento (p. ej. dificultad 5 + tipo Track Day) | Se muestra el estado vacío específico de "filtros sin resultados" con botón "Limpiar filtros" | 🤖✅ Auto-PASS (`test/features/events/presentation/list/widgets/events_page_view_test.dart` TC-2-21, TC-2-23) | |
| 1.4 | Toca "Limpiar filtros" desde el estado vacío filtrado | Los filtros se limpian y vuelve a verse el feed completo | 🤖✅ Auto-PASS (`test/features/events/presentation/list/widgets/events_page_view_test.dart` TC-2-24) | |
| 1.5 | Abre el bottom sheet de filtros y revisa el header | El botón "Limpiar todo" siempre está visible, tenga o no filtros activos | 🤖✅ Auto-PASS (`test/features/events/presentation/list/widgets/event_filters_bottom_sheet_test.dart` TC-2-18) | |
| 1.6 | Filtra por tipo de evento (server-side) | La lista se re-consulta al backend con el query `type` y muestra solo eventos de ese tipo | 🤖✅ Auto-PASS (`test/features/events/presentation/cubit/events_filter_cubit_test.dart`) | |
| 1.7 | Filtra por dificultad, "Solo gratis" o "Multi-marca" (client-side) | El feed se filtra localmente sin nueva llamada HTTP | 🤖✅ Auto-PASS (`test/features/events/presentation/cubit/events_filter_cubit_test.dart`) | |
| 1.8 | Filtra por rango de fechas y revisa el "date floor" | No aparecen eventos con fecha anterior a hoy aunque el filtro incluya fechas pasadas | 🤖✅ Auto-PASS (`test/features/events/presentation/list/events_cubit_date_filter_test.dart`) | |
| 1.9 | Busca un evento por nombre en el buscador | La lista se filtra por texto en tiempo real | 🤖✅ Auto-PASS (`test/features/events/presentation/cubit/events_filter_cubit_test.dart`) | |
| 1.10 | Haz pull-to-refresh en la lista | Se re-consulta `GET /events` y se refresca el feed | | |
| 1.11 | Ve a "Mis eventos" (organizador) | Se listan solo los eventos de los que la cuenta es dueña, incluyendo `finished`/`cancelled` | | |

---

## 2. Detalle de un evento

> Toca un evento desde la lista para abrir su detalle.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 2.1 | Abre el detalle de un evento cualquiera | Header full-bleed con imagen de portada, badge de estado y pill de dificultad superpuestos | 🤖✅ Auto-PASS (`test/features/events/presentation/detail/cubit/event_detail_cubit_test.dart`) | |
| 2.2 | Abre el detalle como **rider** (no dueño) | Se muestra el `EventDetailCTABar` (Inscribirse / Seguir / Cancelar según el estado de inscripción), sin controles de organizador | | |
| 2.3 | Abre el detalle como **organizador** (dueño) en estado `scheduled` | Se muestra `EventDetailOwnerLifecycleBar` con "Iniciar evento" | | |
| 2.4 | Revisa la sección de participantes en el detalle | Lista a los inscritos del evento | 🤖✅ Auto-PASS (`test/features/events/presentation/detail/widgets/event_detail_participants_section_test.dart`) | |
| 2.5 | Toca un participante desde esa sección | Abre el mismo "Detalle de solicitud" que desde "Gestionar Inscritos" | 🤖✅ Auto-PASS (`test/features/events/presentation/detail/widgets/event_detail_participants_section_test.dart`) | |
| 2.6 | Abre el detalle de un evento `finished`/`cancelled` como organizador | La barra de controles de organizador (lifecycle/live/SOS) NO aparece (`hasEnded` la oculta) | | |
| 2.7 | Vuelve atrás desde el detalle (llegaste desde la lista) | La lista se actualiza con los últimos cambios del evento sin volver a pedir el feed completo (cache local) | | |
| 2.8 | Abre un deep-link `EventDetailByIdPage?id=<eventId>` (p. ej. desde una notificación push) siendo el **dueño** del evento | El guard de redirect envía al detalle normal de organizador (no queda atascado en la vista genérica sin controles) | | |
| 2.9 | Abre el mismo deep-link como **rider** (no dueño) | Se muestra el detalle con `EventDetailCTABar`, igual que si se hubiera navegado desde la lista | | |

---

## 3. Crear evento — Wizard de 4 pasos

> Desde el tab Eventos, FAB "+" abre el wizard de creación.

### 3A. Step 1 — Básica (portada, nombre, dificultad, tipo)

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3A.1 | Abre el wizard sin seleccionar portada y toca "Continuar" | El paso NO avanza (portada obligatoria, `validateImageRequired`) | | |
| 3A.2 | Toca la portada vacía → "Subir desde galería" → selecciona una foto | La imagen se carga en el preview del wizard (`CoverPreviewWrapper`) | 🤖✅ Auto-PASS (`integration_test/events_create_publish_patrol_test.dart`) | |
| 3A.3 | Ingresa el nombre del evento | El campo acepta texto libre | 🤖✅ Auto-PASS (`test/features/events/presentation/form/widgets/steps/event_form_step1_test.dart`) | |
| 3A.4 | Selecciona una dificultad (chile) distinta al default | El selector refleja la nueva dificultad elegida | 🤖✅ Auto-PASS (`integration_test/events_create_publish_patrol_test.dart`) | |
| 3A.5 | Selecciona un tipo de evento (chip) distinto al default | El chip queda marcado como seleccionado | 🤖✅ Auto-PASS (`integration_test/events_create_publish_patrol_test.dart`) | |
| 3A.6 | Deja el nombre vacío y toca "Continuar" | El paso NO avanza (validación de campo requerido) | 🤖✅ Auto-PASS (`test/features/events/presentation/form/cubit/event_form_auditor_tests_test.dart` AC-8) | |
| 3A.7 | Revisa el indicador de pasos (stepper) en el paso 1 | El paso activo muestra su número; los futuros muestran su número (no check) | 🤖✅ Auto-PASS (`test/features/events/presentation/form/widgets/steps/event_form_stepper_p2_qa_test.dart` AC-5/6/7) | |

#### 3A-bis. Fecha y hora (dentro del Step 1, sección `EventFormDateTimeSection`)

> Gap de cobertura detectado por auditoría: la sección 3 no tenía ningún caso para el picker de fecha/hora del wizard (`EventFormDateTimeSection`, `EventSingleDayCard`, `EventMultiDayCard`). No se encontró ningún test de widget/cubit que ejercite estos componentes (`grep` sobre `EventFormDateTimeSection`/`EventSingleDayCard`/`EventMultiDayCard`/`isMultiDay` en `test/features/events/` no arroja resultados). Todos los casos siguientes quedan pendientes de automatizar.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3A.8 | En modo día único, toca la fila "Fecha" y selecciona una fecha | Se abre el date picker nativo (rango `[hoy, hoy+548 días]`); la fecha elegida se refleja en la fila con formato `EEE, dd MMM yyyy` | 🤖✅ Auto-PASS (`test/features/events/presentation/form/widgets/sections/event_form_date_time_section_test.dart` 3A.8) | |
| 3A.9 | Activa el switch "Es un evento de varios días" (`AppSwitchTile`) | La card cambia de `EventSingleDayCard` a `EventMultiDayCard` (fila "Fecha de inicio" + "Fecha de fin"), y el campo `dateRange` se limpia (`didChange(null)`) | 🤖✅ Auto-PASS (`test/features/events/presentation/form/widgets/sections/event_form_date_time_section_test.dart` 3A.9, incluye toggle on→off) | |
| 3A.10 | En modo varios días, selecciona "Fecha de inicio" y luego "Fecha de fin" | El date picker de fin solo permite fechas posteriores a la de inicio (`firstDate: start + 1 día`); si la fecha de fin elegida no es posterior a la de inicio, se muestra el error `event_startDateMustBeBeforeEndDate` | 🤖✅ Auto-PASS (`test/features/events/presentation/form/widgets/sections/event_form_date_time_section_test.dart` 3A.10 — selección real start/end vía date picker con "ACEPTAR"; el caso start==end se ejercita invocando directamente el validator vía `field.didChange`, ya que el picker real bloquea esa fecha con `firstDate`) | |
| 3A.11 | Toca la fila "Hora de inicio" (`meetingTime`, ambos modos) y selecciona una hora | Se abre el time picker nativo (hora inicial por defecto 07:00 a. m.); la hora elegida se refleja en la fila con formato `hh:mm a` | 🤖✅ Auto-PASS (`test/features/events/presentation/form/widgets/sections/event_form_date_time_section_test.dart` 3A.11) | |
| 3A.12 | Deja la fecha vacía (modo día único) y toca "Continuar" | El paso NO avanza; se muestra el error `event_startDateRequired` ("La fecha de inicio es requerida") | 🤖✅ Auto-PASS (`test/features/events/presentation/form/widgets/sections/event_form_date_time_section_test.dart` 3A.12, incluye también el caso multi-día `event_dateRangeRequired`) | |

### 3B. Step 2 — Descripción (editor + asistente IA)

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3B.1 | Escribe texto libre en el editor Quill | El texto se refleja en el editor con formato | 🤖✅ Auto-PASS (`integration_test/events_create_publish_patrol_test.dart`) | |
| 3B.2 | Abre el asistente de IA y pide una descripción | Se genera una respuesta en markdown que se inserta en el editor con el formato correcto (H2, bold, italic, bullets) | 🤖✅ Auto-PASS (`test/features/events/presentation/form/utils/markdown_to_delta_converter_test.dart`; `test/features/events/presentation/form/cubit/ai_description_chat_cubit_test.dart`) | |
| 3B.3 | Continúa la conversación con la IA más de una vez | El historial se envía correctamente (hasta 10 turnos) | 🤖✅ Auto-PASS (`test/features/events/domain/use_cases/generate_event_description_use_case_test.dart`) | |
| 3B.4 | Revisa el indicador de cuota restante de generaciones IA | Se muestra la cuota inicial al abrir el sheet (`initQuota`) | 🤖✅ Auto-PASS (`test/features/events/presentation/form/cubit/ai_description_chat_cubit_test.dart` AC15/AC16) | |

### 3C. Step 3 — Ruta y detalles (constructor de waypoints)

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3C.1 | Toca "Crear ruta" | Se abre el constructor de ruta (`EventRouteConfigScreen`) con mapa Mapbox | 🤖✅ Auto-PASS (`integration_test/events_create_publish_patrol_test.dart`) | |
| 3C.2 | Busca un lugar por texto (Mapbox Geocoding) y agrégalo como waypoint | El punto se agrega con su nombre real y aparece un pin numerado | 👤 Manual (requiere red y respuesta real de Mapbox; no cubierto por unit/widget test ni por el patrol actual, que usa "Seleccionar en mapa") | |
| 3C.3 | Usa "Seleccionar en mapa" (pin centrado) para agregar 2 waypoints | Cada punto se agrega con nombre geocodificado inverso o fallback "Punto en el mapa" si Mapbox falla | 🤖✅ Auto-PASS (`integration_test/events_create_publish_patrol_test.dart`) | |
| 3C.4 | Intenta agregar un 10º waypoint | El wizard bloquea el waypoint #10 (máximo 9) | | |
| 3C.5 | Elimina un waypoint ya agregado | El waypoint se quita de la lista y del polyline en el mapa | | |
| 3C.6 | Confirma la ruta con "Continuar" | El mapa ajusta la cámara para mostrar todos los puntos antes de cerrar el constructor | | |
| 3C.7 | Deja el cupo máximo y precio vacíos (opcionales) y continúa | El paso avanza sin bloquear (ambos campos son opcionales) | 🤖✅ Auto-PASS (`integration_test/events_create_publish_patrol_test.dart`) | |
| 3C.8 | Marca el evento como gratis (`isFree`) | El campo de precio se deshabilita/oculta y el evento se guarda sin costo | | |
| 3C.9 | Ingresa un precio y selecciona una o más marcas permitidas (`allowedBrands`, `EventFormMultiBrandSection`) | El evento se guarda con el precio y la lista de marcas seleccionada; en el detalle/filtro "Multi-marca" de la lista aparece correctamente | | |

### 3D. Step 4 — Revisión y publicación

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3D.1 | Llega al step 4 en modo creación | Solo se ofrece el botón "Publicar evento" (no hay opción de guardar borrador — funcionalidad eliminada del producto) | 🤖✅ Auto-PASS (`test/features/events/presentation/form/widgets/steps/publish_row_test.dart`) | |
| 3D.2 | Toca "Publicar evento" | Se abre el bottom sheet "Responsabilidad del organizador" (`EventOrganizerResponsibilitySheet`) | 🤖✅ Auto-PASS (`test/features/events/presentation/form/widgets/event_organizer_responsibility_sheet_test.dart`) | |
| 3D.3 | Toca "Acepto y publico el evento" | Se guarda `organizerAcceptedResponsibilityAt`, el evento se crea (`POST /events`) y se muestra el SnackBar "Evento creado exitosamente" | 🤖✅ Auto-PASS (`integration_test/events_create_publish_patrol_test.dart`; `test/features/events/presentation/form/cubit/event_form_cubit_organizer_responsibility_test.dart`) | |
| 3D.4 | Cierra el sheet sin aceptar ("Revisar") | El sheet se cierra, NO se llama `saveEvent` y el evento no se crea | 🤖✅ Auto-PASS (`test/features/events/presentation/form/widgets/event_organizer_responsibility_sheet_test.dart`) | |
| 3D.5 | Tras publicar, vuelve a la lista de eventos | El evento recién creado aparece en el feed sin necesidad de refrescar (`EventsCubit.addEvent`, optimista) | 🤖✅ Auto-PASS (`integration_test/events_create_publish_patrol_test.dart`) | |
| 3D.6 | En modo edición, revisa el step 4 | Se muestran botones "Editar" que llevan a los pasos 0/1/2, y el botón "Cerrar" (no "Publicar") | 🤖✅ Auto-PASS (`test/features/events/presentation/form/widgets/steps/event_form_step4_review_test.dart` — monta `EventFormStep4Review` real en modo edición, toca cada botón "Editar" y verifica `cubit.goToStep(0)/(1)/(2)`, y verifica un botón "Cerrar" real que dispara `Navigator.pop` (`NavigatorObserver.didPop`)) | |

---

## 4. Editar un evento existente

> Desde el detalle de "Mi Evento" (organizador), entra a editar.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 4.1 | Abre el evento en modo edición | El wizard NO muestra el `EventStepIndicator` (solo en creación) | 🤖✅ Auto-PASS (`test/features/events/presentation/form/widgets/steps/event_form_step4_review_test.dart` — monta el árbol real de edición (`EventFormStep4Review`, que ya compone su propio `EventStepNavBar`) y verifica `find.byType(EventStepIndicator)` findsNothing) | |
| 4.2 | Cambia el nombre y guarda | `PATCH /events/:id` se llama con el payload actualizado y el detalle refleja el cambio | 🤖✅ Auto-PASS (`test/features/events/domain/use_cases/update_event_use_case_test.dart`; `test/features/events/data/repository/event_repository_impl_test.dart`) | |
| 4.3 | Edita la ruta de un evento ya publicado (agrega/quita un waypoint) y guarda | El evento actualiza `routeGeoJson`/`waypoints` correctamente | 👤 Manual (sin cobertura de widget/e2e específica para editar ruta de un evento ya persistido) | |
| 4.4 | Intenta editar un evento `finished`/`cancelled` | El flujo de edición no debería estar disponible (o debe bloquear el guardado) — validar comportamiento real | 👤 Manual (comportamiento no documentado explícitamente ni cubierto por test) | |
| 4.5 | Guarda con un id inválido/evento borrado en paralelo | Se muestra un error legible, sin crash | | |

---

## 5. Eliminar un evento

> Solo disponible para el organizador, en estado `draft` o `scheduled`.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5.1 | Como organizador, elimina un evento propio en `scheduled` | Se pide confirmación antes de eliminar | 👤 Manual (no hay widget test del diálogo de confirmación de borrado en `test/features/events/`) | |
| 5.2 | Confirma la eliminación | `DELETE /events/:id` se llama y el evento desaparece de "Mis eventos" sin re-fetch | 🤖✅ Auto-PASS (`test/features/events/presentation/delete/cubit/event_delete_cubit_test.dart`; `test/features/events/domain/use_cases/delete_event_use_case_test.dart`) | |
| 5.3 | Intenta eliminar un evento en `inProgress`/`finished` | La opción de eliminar no debería estar disponible (validar UI) | 👤 Manual (restricción documentada en el ciclo de vida, sin test de UI que la verifique) | |
| 5.4 | Simula un fallo de red al eliminar | El evento permanece en la lista y se muestra un error, sin quedar en estado inconsistente | 👤 Manual (parcial) — `event_delete_cubit_test.dart` (TC-del-3) solo verifica que `EventDeleteCubit` emite `Loading` → `Error`; no hay test que confirme que el evento permanece en la lista de `EventsCubit` (ese es otro cubit, sin cobertura de este escenario) | |

---

## 6. Ciclo de vida: iniciar y detener la rodada

> "Mi Evento" en `scheduled`, cuenta organizadora `qa2@gmail.com`.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 6.1 | Abre el detalle y toca "Iniciar evento" | `POST /events/:id/tracking/start`, el evento pasa a `inProgress`, la barra owner cambia a estado EN VIVO ("Ver mapa" + "Detener evento") | 🤖✅ Auto-PASS (`integration_test/events_live_tracking_sos_patrol_test.dart`; `test/features/events/domain/use_cases/start_tracking_use_case_test.dart`) | |
| 6.2 | Toca "Ver mapa" | Se abre `LiveMapPage` con el mapa y el botón SOS visibles | 🤖✅ Auto-PASS (`integration_test/events_live_tracking_sos_patrol_test.dart`) | |
| 6.3 | Vuelve al detalle sin detener la rodada | El tracking (GPS + WS) sigue activo en segundo plano (`LiveTrackingSessionHolder` mantiene vivo el cubit) | 👤 Manual (requiere inspección de estado en background; no verificable solo por UI) | |
| 6.4 | Desde el detalle, toca "Detener evento" y confirma | `POST /events/:id/tracking/end`, el evento pasa a `finished`, la barra de controles owner desaparece por completo | 🤖✅ Auto-PASS (`integration_test/events_live_tracking_sos_patrol_test.dart`; `test/features/events/presentation/tracking/live_tracking_cubit_event_ended_test.dart`) | |
| 6.5 | Como rider (no owner) con el evento `inProgress` | Puede ver "Seguir" para entrar al mapa en vivo, sin controles de owner (start/stop) | | |
| 6.6 | Intenta iniciar un evento que ya está `inProgress`/`finished` (doble tap rápido) | El backend/UI evita una doble transición inválida | 🤖✅ Auto-PASS (`test/features/events/presentation/tracking/live_tracking_cubit_event_ended_test.dart` Caso B — doble disparo) | |

---

## 7. Tracking en vivo (marcadores, telemetría, reconexión)

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 7.1 | Entra al mapa en vivo como organizador (lead) | Aparece la tarjeta propia en el panel de Rider Telemetry con badge de rol "LEAD" | 🤖✅ Auto-PASS (`integration_test/events_live_tracking_sos_patrol_test.dart`) | |
| 7.2 | El snapshot inicial HTTP + el WS se combinan correctamente | La lista de riders activos incluye tanto el snapshot inicial como las actualizaciones WS subsecuentes | 🤖✅ Auto-PASS (`test/features/events/data/repository/tracking_repository_impl_test.dart`; `test/features/events/data/service/tracking_ws_client_test.dart`) | |
| 7.3 | Un rider nuevo se une al evento (no estaba en el snapshot) | Se agrega dinámicamente a la lista sin duplicados | 🤖✅ Auto-PASS (`test/features/events/data/service/tracking_ws_client_test.dart`) | |
| 7.4 | Un rider sale del tracking | Desaparece de la lista de riders activos | 🤖✅ Auto-PASS (`test/features/events/data/service/tracking_ws_client_test.dart`) | |
| 7.5 | Con dos o más riders conectados (multi-dispositivo), verifica los marcadores en el mapa | El marcador "lead" se distingue visualmente (glow + corona) de los marcadores "rider" | 👤 Manual (marcadores son imágenes nativas de Mapbox, no verificables por árbol de widgets — requiere inspección visual) | |
| 7.6 | Mueve el mapa con el dedo mientras hay riders en movimiento | El modo "follow" se desactiva al panear manualmente; el botón centrar lo reactiva | 👤 Manual (comportamiento de cámara, requiere verificación visual en dispositivo real) | |
| 7.7 | Tap en un marcador o tarjeta de telemetría de un rider | El mapa centra a ese rider y se resalta/sincroniza en la lista | 👤 Manual (sin widget test específico de esta interacción de sincronización mapa↔lista) | |
| 7.8 | Corta la conexión a internet durante el tracking (modo avión) y reconecta | El WS se reconecta automáticamente en ~2s sin intervención del usuario | 🤖✅ Auto-PASS (`test/features/events/data/service/tracking_ws_client_test.dart` "automatic reconnection") | |
| 7.9 | Mientras el WS está caído, revisa la UI | No hay una UI explícita de "reintentar" — depende del reconnect automático (comportamiento documentado, no un bug) | 👤 Manual (gap conocido documentado en `docs/features/events.md` §12 "Live tracking sin manejo de error de WS") | |
| 7.10 | Verifica el throttling de envío al backend (posiciones cada ≥4s) | Las actualizaciones de posición local (UI) son inmediatas pero el push al WS respeta el throttle de 4s | | |

---

## 8. SOS (activar, cancelar, recepción por otros)

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 8.1 | En el mapa en vivo, toca el botón SOS | Se abre `SosConfirmDialog` ("¿Enviar SOS?") | 🤖✅ Auto-PASS (`integration_test/events_live_tracking_sos_patrol_test.dart`) | |
| 8.2 | Confirma "Enviar SOS" | El botón SOS pasa a estado activo (`isActive == true`), se envía `tracking.sos` por WS | 🤖✅ Auto-PASS (`integration_test/events_live_tracking_sos_patrol_test.dart`; `test/features/events/presentation/tracking/widgets/live_map_sos_button_test.dart`; `test/features/events/presentation/tracking/live_tracking_cubit_analytics_test.dart`) | |
| 8.3 | Con el SOS activo, toca el botón de nuevo | Se abre confirmación danger "¿Desactivar SOS?" | 🤖✅ Auto-PASS (`integration_test/events_live_tracking_sos_patrol_test.dart`) | |
| 8.4 | Confirma "Desactivar SOS" | El botón vuelve a estado normal, se envía `tracking.sos.cancel` por WS | 🤖✅ Auto-PASS (`integration_test/events_live_tracking_sos_patrol_test.dart`; `test/features/events/presentation/tracking/live_tracking_cubit_analytics_test.dart`) | |
| 8.5 | **Recepción del SOS por OTRO rider conectado** (requiere 2 dispositivos) | El otro rider ve un `SosBannerWidget` compacto con nombre real, teléfono, marcador rojo en el mapa y tarjeta roja en Rider Telemetry | 🚫 No automatizable con la infraestructura actual (requiere 2 dispositivos/emuladores en paralelo; documentado como fuera de alcance en `integration_test/events_live_tracking_sos_patrol_test.dart`) | |
| 8.6 | **"Localizar" sobre el SOS de otro rider** | Abre `AppModal` con opciones "Centrar en el mapa" / "Abrir en Google Maps" | 🚫 No automatizable con la infraestructura actual (depende de 8.5) | |
| 8.7 | **Cancelación del SOS propagada a un tercero** (`tracking.sos.cleared`) | Todos los clientes conectados limpian el banner/marcador cuando alguien cancela su SOS | 🚫 No automatizable con la infraestructura actual (multi-dispositivo); el mensaje WS en sí SÍ está cubierto unitariamente | 🤖✅ Auto-PASS (parcial, solo mensaje WS: `test/features/events/data/service/tracking_ws_client_test.dart`) — |
| 8.8 | **Late-joiner recibe el SOS activo** (un rider se une a un evento con SOS ya activado) | El servidor reenvía `tracking.sos.alert` dirigido a ese cliente tras el snapshot | 🚫 No automatizable con la infraestructura actual (requiere 2 dispositivos + timing de unión tardía) | |
| 8.9 | El nombre mostrado en el banner/push de SOS | Nunca debe mostrar el UUID del usuario, siempre el nombre real resuelto por el backend | 👤 Manual (lógica de resolución vive en `events-ms`, fuera del alcance de tests Flutter) | |

---

## 9. Gestión de asistentes (aprobar / rechazar)

> "Gestionar Inscritos" desde el detalle de "Mi Evento" (organizador).

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 9.1 | Abre "Gestionar Inscritos" | AppBar muestra el conteo de pendientes en badge naranja; secciones "NUEVAS SOLICITUDES" y "YA PROCESADOS" | 🤖✅ Auto-PASS (`test/features/events/presentation/attendees/widgets/attendees_list_navigation_test.dart`) | |
| 9.2 | Filtra por chips inline (Todos/Pendientes/Aprobados/Rechazados) | La lista se filtra correctamente por estado | | |
| 9.3 | Busca un asistente por nombre | La lista se filtra por el texto ingresado | | |
| 9.4 | Toca "Aprobar" en una solicitud pendiente y confirma | La fila desaparece de "NUEVAS SOLICITUDES" y aparece en "YA PROCESADOS" con badge "APROBADO" (cambio optimista) | 🤖✅ Auto-PASS (`integration_test/events_attendees_approve_reject_patrol_test.dart`; `test/features/events/presentation/attendees/attendees_cubit_analytics_test.dart`) | |
| 9.5 | Toca "Rechazar" en una solicitud pendiente y confirma | La fila pasa a "YA PROCESADOS" con badge "RECHAZADO" | 🤖✅ Auto-PASS (`test/features/events/presentation/attendees/attendees_cubit_rollback_test.dart` TC-att-r4/r6: `rejectRegistration` cambia el status local a `rejected` de inmediato y se mantiene tras éxito del use case) | |
| 9.6 | Simula un fallo de red al aprobar/rechazar | El cambio optimista se revierte (rollback) al estado previo y se muestra un error | 🤖✅ Auto-PASS (`test/features/events/presentation/attendees/attendees_cubit_rollback_test.dart` TC-att-r2/r5/r8 verifican que, tras `Left` del use case, el status del registro afectado vuelve a `pending` en el `ResultState` emitido, para approve/reject/setReadyForEdit; TC-att-r10 confirma que el rollback no corrompe una acción exitosa posterior. El envío del error al canal `actionErrors` para mostrar el SnackBar ya estaba cubierto por `attendees_cubit_analytics_test.dart`) | |
| 9.7 | Solicita "editar" una inscripción (ready for edit) | Se refetcha la lista tras la respuesta del backend | | |
| 9.8 | Con el evento `finished`/`cancelled`, revisa los botones de aprobar/rechazar | Quedan deshabilitados (no se puede gestionar un evento ya terminado) | 🤖✅ Auto-PASS (`test/features/events/presentation/attendees/widgets/attendee_pending_request_card_finished_test.dart`) | |
| 9.9 | Toca un asistente desde la lista | Abre "Detalle de solicitud" (feature `event_registration`, ver `docs/testing/qa-checklists/` de esa feature) | | |

---

## 10. Asistente IA — descripción del evento

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 10.1 | Pide una descripción con datos válidos (título, tipo, dificultad) | Se genera texto en markdown, se convierte a Quill Delta y se inserta en el editor | 🤖✅ Auto-PASS (`test/features/events/domain/use_cases/generate_event_description_use_case_test.dart`; `test/features/events/presentation/form/utils/markdown_to_delta_converter_test.dart`) | |
| 10.2 | Agota la cuota diaria de generaciones IA (`quota_exceeded_user`) | El input del chat se deshabilita, NO se muestra botón "Reintentar" | 🤖✅ Auto-PASS (`test/features/events/presentation/form/widgets/ai_chat/ai_description_chat_sheet_test.dart` AC13) | |
| 10.3 | Simula cuota del proyecto agotada (`quota_exceeded_project`) | Se muestra el error y SÍ aparece "Reintentar" | 🤖✅ Auto-PASS (`test/features/events/presentation/form/widgets/ai_chat/ai_description_chat_sheet_test.dart` AC14) | |
| 10.4 | Simula un mensaje bloqueado por seguridad (`safety_blocked`) | Se muestra el error correspondiente con botón "Reintentar" | 🤖✅ Auto-PASS (`test/features/events/data/repository/ai_description_repository_impl_test.dart`) | |
| 10.5 | Simula el servicio de IA caído (`ai_network_error`, 503) | Se muestra error de red con botón "Reintentar" | 🤖✅ Auto-PASS (`test/features/events/presentation/form/widgets/ai_chat/ai_description_chat_sheet_test.dart`) | |
| 10.6 | Envía más de 10 turnos de conversación | El historial se recorta a los últimos 10 antes de enviarse al backend | 🤖✅ Auto-PASS (`test/features/events/domain/use_cases/generate_event_description_use_case_test.dart`) | |
| 10.7 | Cierra el sheet de IA sin usar la respuesta generada | El editor conserva el texto que tenía antes (no se pierde ni se sobreescribe accidentalmente) | | |

---

## 11. Asistente IA — portada / cover del evento

> El endpoint `POST /events/generate-cover` fue **eliminado en Fase 5**; verificar el mecanismo vigente de generación de portada IA (`GetGenerateCoverUseCase` / `EventCoverRepository.generateCover`).

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 11.1 | En el step 1, intenta generar una portada con IA (si la UI aún lo ofrece) | Se genera una imagen de portada acorde al título/tipo/ciudad del evento | 👤 Manual (sin test unitario/widget para `GetGenerateCoverUseCase` ni `EventCoverRepositoryImpl` — gap de cobertura) | |
| 11.2 | Revisa si el botón de generación de portada con IA sigue existiendo en la UI actual | Confirmar si sigue vigente o si, como documenta el patrol de creación, la única vía real es "Subir desde galería" (`CoverPickerSheet` sin botón de IA) | 👤 Manual (contradicción a resolver entre `docs/features/events.md` §5/§9 que mencionan el use case, y el comentario del patrol test que dice "no AI generation button") | |
| 11.3 | Si existe, simula un error al generar portada con IA | Se muestra un error legible sin bloquear el flujo (el usuario puede volver a subir desde galería) | 👤 Manual (sin cobertura) | |

---

## 12. Casos de borde

### 12A. Evento sin waypoints / sin ruta

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 12A.1 | Intenta continuar del step 3 sin crear ninguna ruta | Verificar si el wizard bloquea el avance o permite continuar sin ruta | 👤 Manual (comportamiento no documentado explícitamente) | |
| 12A.2 | Abre el detalle de un evento sin `routeGeoJson`/waypoints (dato legado o creado sin ruta) | `meetingPoint`/`destination` (getters computados) no truenan; el detalle no muestra mapa de ruta o muestra un estado vacío correcto | | |

### 12B. WebSocket caído / reconexión

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 12B.1 | El WS nunca logra conectar (token expirado, sin red) desde el inicio del tracking | El stream de riders emite un error (`StateError`), sin crashear la pantalla | 🤖✅ Auto-PASS (`test/features/events/data/repository/tracking_repository_impl_test.dart` "forwards errors emitted by the WS stream") | |
| 12B.2 | El WS se cae a mitad de una sesión de tracking activa | Reconecta automáticamente en ~2s sin intervención manual | 🤖✅ Auto-PASS (`test/features/events/data/service/tracking_ws_client_test.dart` "automatic reconnection") | |
| 12B.3 | Mensajes WS mal formados o de tipo desconocido llegan al cliente | Se ignoran sin lanzar excepción | 🤖✅ Auto-PASS (`test/features/events/data/service/tracking_ws_client_test.dart` "message parsing edge cases") | |

### 12C. Error de cuota / servicio de IA

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 12C.1 | Cuota de usuario agotada mientras se redacta un mensaje largo | El mensaje no se pierde visualmente pero el envío queda bloqueado hasta que se resetee la cuota | 👤 Manual (comportamiento de UX no cubierto por test automatizado) | |
| 12C.2 | Mensaje de más de 2000 caracteres en un turno | El backend rechaza con 400; la UI debe mostrar un error claro (validar longitud client-side también) | 👤 Manual (no hay test de validación de longitud de turno en el cliente) | |

### 12D. Igualdad de `EventModel` por id únicamente

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 12D.1 | Dos eventos nuevos sin persistir (`id == null`) conviven en la misma pantalla (p. ej. wizard abierto dos veces) | No deben tratarse como el mismo evento en listas/sets — vigilar regresiones si se usa `Set<EventModel>` o `.contains()` en código nuevo | 👤 Manual (trampa arquitectónica documentada en `docs/features/events.md` §12, no un caso de UI verificable directamente) | |

---

## 13. Verificaciones técnicas (equipo de desarrollo)

> Requieren acceso al código, logs o consola de desarrollo.

| # | Verificación | Resultado esperado | ✅/❌ |
|---|-------------|--------------------|-------|
| 13.1 | Correr `flutter test test/features/events/` | Todos los tests del feature pasan en verde | |
| 13.2 | Correr `dart analyze` | Sin issues nuevos en `lib/features/events/` | |
| 13.3 | Correr `patrol test -t integration_test/events_patrol_test.dart --device-id <id> --dart-define=TEST_EMAIL=qa2@gmail.com --dart-define=TEST_PASSWORD=Test123.` | Login → tab Eventos carga correctamente | |
| 13.4 | Correr `patrol test -t integration_test/events_create_publish_patrol_test.dart` (con galería sembrada, ver pre-condiciones) | El wizard completo crea y publica un evento nuevo, visible en la lista | |
| 13.5 | Correr `patrol test -t integration_test/events_attendees_approve_reject_patrol_test.dart` (con una inscripción PENDING en "Mi Evento") | El organizador aprueba la solicitud y la ve pasar a "YA PROCESADOS" | |
| 13.6 | Correr `patrol test -t integration_test/events_live_tracking_sos_patrol_test.dart` ("Mi Evento" en `scheduled`, GPS mockeado) | Iniciar rodada → SOS activar/cancelar → detener rodada, todo en un solo dispositivo | |
| 13.7 | Revisar logs durante `events_live_tracking_sos_patrol_test.dart` | No aparecen excepciones no capturadas ni `Null check operator used on a null value` | |
| 13.8 | Verificar en BD (o vía `GET /events/:id`) que tras publicar un evento de prueba, `organizerAcceptedResponsibilityAt` quedó persistido | El campo no es `null` tras el flujo de publicación | |
| 13.9 | Verificar en BD que al aprobar/rechazar un asistente, el estado de la inscripción cambió realmente en el backend (no solo en la UI optimista) | El estado persistido coincide con lo mostrado en "YA PROCESADOS" | |
| 13.10 | Verificar en BD que `stopEvent()`/"Detener evento" dejó el evento en `finished` (no solo en el estado local del cliente) | El campo `state` del evento en BD es `finished` | |
| 13.11 | Revisar si `GetGenerateCoverUseCase`/`EventCoverRepositoryImpl` siguen teniendo callsite real en la UI actual, o si son código muerto (como pasó con `saveDraft()`) | Si son código muerto, documentarlo y planear su eliminación; si están vivos, agregar tests (gap actual) | |

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos de las secciones 1, 2, 3, 6, 9 marcados como ✅ |
| ⚠️ Aprobado con observaciones | Máximo 3 casos fallidos de baja severidad (secciones 4, 5, 7, 10, 11, 12), con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones 3D, 6, 8 (excepto 8.5–8.8, marcados 🚫) o 9 marcado como ❌ |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________

---

## Fixes requeridos

> Gaps de cobertura detectados durante la planeación de este checklist (no ejecución — pendiente de correr `qa-auto` o `rg-exec` lite por cada uno).

1. **[Alta]** Sin tests para `GetGenerateCoverUseCase` / `EventCoverRepositoryImpl` (generación de portada con IA) — no hay unit tests ni widget tests, y hay una posible contradicción entre la documentación (`events.md` §9) y el comentario del patrol de creación que afirma "no AI generation button". Verificar si el flujo sigue vivo en la UI y, si es así, escribir tests; si es código muerto, documentarlo/eliminarlo.
2. **[Media]** Sin patrol test de **rechazo** de asistentes (`events_attendees_approve_reject_patrol_test.dart` solo ejerce "Aprobar"). Agregar un caso de rechazo end-to-end o, como mínimo, documentar por qué no se agregó.
3. **[Media]** Sin patrol/widget test del flujo de **eliminar evento** (diálogo de confirmación + navegación tras borrar). Solo hay cobertura del cubit (`EventDeleteCubit`), no de la UI que lo dispara.
4. **[Media]** Sin patrol test de **editar** un evento ya publicado (solo existe el de crear+publicar). Agregar un caso e2e de edición para validar que el `PATCH` real funciona desde la UI.
5. **[Baja]** Sin widget test para el constructor de ruta (`EventRouteConfigScreen`) más allá de lo ejercido indirectamente por el patrol de creación — casos como el límite de 9 waypoints o eliminar un waypoint no tienen cobertura unitaria/widget dedicada.
6. **[Baja]** Recepción de SOS por otro rider (multi-dispositivo) sigue sin infraestructura de test — considerar un patrol multi-dispositivo dedicado si Patrol lo soporta en este repo, dado que hoy es un gap conocido y documentado pero no cerrado.

> Resuelto (2026-07-04): los ítems 7, 8 y 9 (wiring real de `goToStep`/"Cerrar" en step 4, `EventStepIndicator` ausente en edición, y cobertura de `EventFormDateTimeSection`/`EventSingleDayCard`/`EventMultiDayCard`) quedaron cubiertos por `test/features/events/presentation/form/widgets/steps/event_form_step4_review_test.dart` y `test/features/events/presentation/form/widgets/sections/event_form_date_time_section_test.dart` — ver casos 3D.6, 4.1 y 3A.8–3A.12 arriba.
