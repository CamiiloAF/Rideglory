# Documento de QA de Analítica — Rideglory

**Fase:** 10 — Auditoría no-PII transversal  
**Fecha de redacción:** 2026-06-04  
**Estado:** Aprobado por auditoría — cero violaciones de PII encontradas  
**Autor:** Fase 10 del plan `analytics-crashlytics-cobertura-total`

---

## 1. Prerrequisitos generales

### Build y entorno

| Requisito | Valor / Comando |
|-----------|----------------|
| Build mínimo | `staging` o `release` (en `kDebugMode` los handlers de crash no reportan) |
| Cuenta Google | Con acceso al proyecto Firebase de Rideglory |
| Herramienta | Firebase Console → Analytics → DebugView |
| Android mínimo | Android Studio con un emulador o dispositivo físico conectado via ADB |
| iOS mínimo | Xcode con simulador o dispositivo físico |

### Habilitar GA4 DebugView en Android

```bash
# Emulador o dispositivo físico conectado
adb shell setprop debug.firebase.analytics.app <package_id_de_rideglory>
# Para deshabilitar
adb shell setprop debug.firebase.analytics.app .none.
```

### Habilitar GA4 DebugView en iOS

En Xcode: **Esquema de ejecución → Arguments Passed On Launch → + → `-FIRAnalyticsDebugEnabled`**  
O en línea de comandos del simulador:
```bash
open -a Simulator
xcrun simctl launch booted <bundle_id> -FIRAnalyticsDebugEnabled
```

### Estado de captura por build (Tabla de síntesis del plan)

| Entorno | Analytics | Crashlytics no-fatales | Crashlytics fatales |
|---------|-----------|------------------------|---------------------|
| `kDebugMode = true` | **Deshabilitado** (`setEnabled(false)` en `main.dart`) | **No reporta** (gating en `registerCrashHandlers`) | **No reporta** |
| `staging` / `release` | **Habilitado** | **Reporta** | **Reporta** |

---

## 2. Catálogo completo de telemetría

### 2.1 Eventos de Firebase Analytics

| Nombre del evento | Cuándo se dispara | Params (clave → tipo → valor canónico/rango) | Feature | Call site (`archivo:símbolo`) |
|-------------------|-------------------|----------------------------------------------|---------|-------------------------------|
| `auth_flow_started` | El rider entra a login, signup o forgot_password | `auth_method` → String → `login` \| `signup` \| `forgot_password` | Auth | `login_view.dart`, `signup_view.dart`, `forgot_password_view.dart` |
| `auth_method_selected` | El rider pulsa submit/social para iniciar autenticación | `auth_method` → String → `email` \| `google` \| `apple` \| `forgot_password` | Auth | `login_view.dart`, `signup_view.dart`, `forgot_password_view.dart`, `login_social_section.dart`, `signup_social_buttons.dart` |
| `auth_succeeded` | El cubit confirma sesión exitosa | `auth_method` → String → `email` \| `google` \| `apple` \| `forgot_password` | Auth | `auth_cubit.dart:_onAuthenticated`, `auth_cubit.dart:sendPasswordResetEmail` |
| `auth_failed` | El cubit recibe un error de autenticación | `auth_method` → String, `auth_error_category` → String → `invalid_credentials` \| `network` \| `cancelled` \| `unknown` | Auth | `auth_cubit.dart` (4 call sites) |
| `auth_abandoned` | El rider cierra la vista de auth sin completar | `auth_method` → String → `login` \| `signup` \| `forgot_password` | Auth | `login_view.dart`, `signup_view.dart`, `forgot_password_view.dart` |
| `auth_first_home_entry` | Primera entrada a home tras autenticarse | — | Auth | `auth_cubit.dart:_onAuthenticated` |
| `soat_scan_attempted` | El rider inicia un escaneo de SOAT | — | SOAT | `scan_soat_usecase.dart` |
| `soat_scan_success` | El escaneo terminó con éxito (prefill) | `fields_extracted_count` → int, `insurer_detected` → int (0/1), `had_pdf` → int (0/1) | SOAT | `scan_soat_usecase.dart` |
| `soat_scan_failed` | El escaneo falló | `failure_reason` → String → enum `SoatScanFailureReason.analyticsValue` | SOAT | `scan_soat_usecase.dart:_logFailure` |
| `home_viewed` | El rider aterrizó en home con datos cargados | `upcoming_events_count` → int, `has_main_vehicle` → int (0/1) | Home | `home_cubit.dart:loadHomeData` |
| `events_list_viewed` | El rider vio la lista de eventos (carga real vs. backend) | `result_count` → int, `list_scope` → String → `all` \| `mine` | Events (lectura) | `events_cubit.dart` |
| `event_detail_viewed` | El rider abrió el detalle de un evento | `event_type` → String (enum apiValue), `event_state` → String (enum name), `is_owner` → int (0/1), `is_read_only` → int (0/1), `source` → String → `list` \| `draft` \| `deep_link` | Events (lectura) | `event_detail_page.dart` (camino lista/borrador), `event_detail_cubit.dart` (camino deep-link) |
| `events_create_started` | El rider inicia el formulario de creación/edición | `form_mode` → String → `create` \| `edit` | Events (escritura) | `event_form_cubit.dart` |
| `events_draft_saved` | El rider guardó el evento como borrador | `form_mode` → String → `create` \| `edit` | Events (escritura) | `event_form_cubit.dart` |
| `events_published` | El rider publicó el evento | `form_mode` → String → `create` \| `edit` | Events (escritura) | `event_form_cubit.dart` |
| `events_publish_failed` | El intento de publicar falló | `form_mode` → String, `failure_category` → String → `network` \| `validation` \| `not_found` \| `unknown` | Events (escritura) | `event_form_cubit.dart` |
| `events_delete_attempted` | El rider inició el borrado de un evento | — | Events (escritura) | `event_delete_cubit.dart` |
| `events_delete_succeeded` | El evento se borró exitosamente | — | Events (escritura) | `event_delete_cubit.dart` |
| `events_delete_failed` | El borrado del evento falló | `failure_category` → String | Events (escritura) | `event_delete_cubit.dart` |
| `registration_started` | El rider abrió el wizard de registro | — | Event Registration | `registration_form_cubit.dart` |
| `registration_step_advanced` | El rider avanzó al siguiente paso del wizard | `step_index` → int, `step_name` → String → `personal` \| `medical` \| `emergency` \| `vehicle` | Event Registration | `registration_form_cubit.dart` |
| `registration_step_back` | El rider retrocedió un paso del wizard | `step_index` → int, `step_name` → String | Event Registration | `registration_form_cubit.dart` |
| `registration_submitted` | El rider envió el registro exitosamente | `form_mode` → String → `create` \| `edit` | Event Registration | `registration_form_cubit.dart` |
| `registration_submit_failed` | El envío del registro falló | `form_mode` → String, `failure_category` → String | Event Registration | `registration_form_cubit.dart` |
| `registration_abandoned` | El rider cerró el wizard sin enviar | — | Event Registration | `registration_form_cubit.dart` (dispose) |
| `registration_approved` | El organizador aprobó una inscripción | — | Event Registration (aprobación) | `attendees_cubit.dart` |
| `registration_rejected` | El organizador rechazó una inscripción | — | Event Registration (aprobación) | `attendees_cubit.dart` |
| `registration_ready_for_edit` | El organizador marcó inscripción como "listo para editar" | — | Event Registration (aprobación) | `attendees_cubit.dart` |
| `registration_approval_failed` | Una acción de aprobación falló en el backend | `approval_action` → String → `approve` \| `reject` \| `ready_for_edit` | Event Registration (aprobación) | `attendees_cubit.dart` |
| `registration_my_list_viewed` | El rider vio su listado de inscripciones propias | — | Event Registration (mis registros) | `my_registrations_cubit.dart` |
| `registration_cancelled` | El rider canceló su propia inscripción | — | Event Registration (mis registros) | `my_registrations_cubit.dart` |
| `tracking_session_started` | El rider confirmó arranque exitoso de tracking | `tracking_role` → String → `lead` \| `rider` | Live Tracking | `live_tracking_cubit.dart` |
| `tracking_session_ended` | El tracking se detuvo efectivamente | `tracking_end_reason` → String → `user_left` \| `event_ended` \| `signed_out` | Live Tracking | `live_tracking_cubit.dart:_logSessionEnded` |
| `tracking_snapshot_received` | El mapa se pobló por primera vez en la sesión | `rider_count` → int | Live Tracking | `live_tracking_cubit.dart:_subscribeToRiders` |
| `sos_activated` | El rider disparó un SOS propio | `tracking_role` → String → `lead` \| `rider` | SOS | `live_tracking_cubit.dart:triggerSos` |
| `sos_confirmed` | El sistema confirmó/propagó el SOS del rider | — | SOS | `live_tracking_cubit.dart:_subscribeToSosAlerts` |
| `sos_cleared` | El SOS fue cerrado (propio o remoto) | `sos_clear_reason` → String → `user_cancel` \| `remote_clear` | SOS | `live_tracking_cubit.dart:cancelSos`, `_subscribeToSosCleared` |
| `vehicle_added` | El rider agregó un vehículo | `had_photo` → int (0/1) | Vehicles | `vehicle_form_cubit.dart` |
| `vehicle_updated` | El rider editó un vehículo | `had_photo` → int (0/1) | Vehicles | `vehicle_form_cubit.dart` |
| `vehicle_deleted` | El rider eliminó un vehículo | — | Vehicles | `vehicle_delete_cubit.dart` |
| `vehicle_set_main` | El rider marcó un vehículo como principal | — | Vehicles | `vehicle_cubit.dart:setMainVehicle` |
| `maintenance_added` | El rider guardó un registro de mantenimiento | `maintenance_type` → String (enum name), `maintenance_mode` → String → `completed` \| `scheduled` | Maintenance | `maintenance_form_cubit.dart` |
| `maintenance_history_viewed` | El rider vio el historial de mantenimientos | `result_count` → int | Maintenance | `maintenances_cubit.dart` |
| `maintenance_updated` | El rider actualizó un mantenimiento existente | `maintenance_type` → String (enum name), `maintenance_mode` → String → `completed` \| `scheduled` | Maintenance | `maintenance_form_cubit.dart` (rama `id != null`) |
| `maintenance_deleted` | El rider eliminó un mantenimiento | `maintenance_type` → String (enum name) | Maintenance | `maintenance_delete_cubit.dart` |
| `soat_status_viewed` | El rider vio el estado de un SOAT existente | `soat_status` → String → `valid` \| `expiringSoon` \| `expired` \| `noSoat` | SOAT | `soat_cubit.dart:load` |
| `soat_manual_saved` | El rider guardó un SOAT nuevo (manual) | `had_pdf` → int (0/1) | SOAT | `soat_cubit.dart:save` (id vacío) |
| `soat_updated` | El rider actualizó un SOAT existente | `had_pdf` → int (0/1) | SOAT | `soat_cubit.dart:save` (id no vacío) |
| `soat_deleted` | El rider eliminó el SOAT de un vehículo | — | SOAT | `soat_cubit.dart:delete` |
| `profile_viewed` | El rider cargó su propio perfil | — | Profile | `profile_cubit.dart` |
| `profile_edit_started` | El rider abrió el flujo de edición de perfil | — | Profile | `edit_profile_cubit.dart` |
| `profile_edit_succeeded` | El rider completó la edición de perfil | — | Profile | `edit_profile_cubit.dart` |
| `rider_profile_viewed` | El rider vio el perfil de otro rider | — | Users | `rider_profile_cubit.dart` |
| `notification_marked_read` | El rider marcó leída una notificación | `notification_type` → String (enum name) | Notifications | `notifications_cubit.dart` |
| `notifications_all_read` | El rider marcó todas las notificaciones como leídas | — | Notifications | `notifications_cubit.dart` |
| `fcm_token_registered` | Se registró el token FCM del dispositivo (señal de salud) | — | Notifications | `register_fcm_token_usecase.dart` |

### 2.2 Vistas de pantalla (screen_view)

El `AnalyticsRouteObserver` emite `logScreenView` automáticamente en cada cambio de ruta. Los nombres canónicos están en `analytics_screen_names.dart`. La garantía es que **nunca se usa el path con `:id`** como nombre de pantalla — siempre se hace lookup en el mapa estático.

| Ruta (AppRoutes) | Nombre canónico estable |
|------------------|------------------------|
| `/` (splash) | `splash` |
| `/login` | `login` |
| `/signup` | `signup` |
| `/forgot-password` | `forgot_password` |
| `/home` | `home` |
| `/garage` | `garage` |
| `/events` | `events` |
| `/profile` | `profile` |
| `/profile/edit` | `profile_edit` |
| `/garage/create-vehicle` | `vehicle_create` |
| `/garage/vehicle/:id` | `vehicle_detail` ← ID enmascarado |
| `/garage/vehicle/:id/edit` | `vehicle_edit` ← ID enmascarado |
| `/garage/vehicle/:id/maintenances` | `maintenances` |
| `/garage/vehicle/:id/maintenances/create` | `maintenance_create` |
| `.../maintenances/:id/edit` | `maintenance_edit` |
| `.../maintenances/:id/detail` | `maintenance_detail` |
| `/events/mine` | `events_mine` |
| `/events/drafts` | `events_drafts` |
| `/events/create` | `event_create` |
| `/events/:id/edit` | `event_edit` |
| `/events/:id` | `event_detail` |
| `/events/:id/registration` | `event_registration` |
| `/events/:id/attendees` | `event_attendees` |
| `/events/:id/live-map` | `live_map` |
| `/events/:id/participants` | `participants` |
| `/registrations` | `my_registrations` |
| `/registrations/:id` | `registration_detail` |
| `/riders/:id` | `rider_profile` |
| `/notifications` | `notifications` |
| `/garage/vehicle/:id/soat` | `soat_status` |
| `/garage/vehicle/:id/soat/capture` | `soat_manual_capture` |
| `/events/by-id/:id` | `event_detail` (alias) |

### 2.3 setUserId y user properties

| Tipo | Nombre | Valor | Call site |
|------|--------|-------|-----------|
| `setUserId` | — | SHA-256 hex del uid de Firebase (64 chars, nunca el uid en claro) | `auth_cubit.dart:_onAuthenticated` → `AnalyticsUidHasher.hash(firebaseUid)` |
| User property | `login_method` | `email` \| `google` \| `apple` | `auth_cubit.dart:_onAuthenticated` |
| User property | `has_vehicle` | `'0'` \| `'1'` (como String; GA4 acepta String para user props) | `vehicle_cubit.dart:fetchMyVehicles` |

### 2.4 Crashlytics — no-fatales de red (handlerExceptionHttp)

Todos los no-fatales son emitidos únicamente en modo **non-debug** (gating estricto). Las `information` son pares clave-valor no-PII:

| Tipo de excepción | `reason` | `information` (claves → valores) |
|-------------------|----------|-----------------------------------|
| `DioException` (timeout/5xx/connection) | `network_timeout` \| `network_connection` \| `network_5xx` | `error_category=network`, `http_status=<int>?`, `dio_type=<String>?`, `endpoint=<sanitized_url>` |
| `FirebaseAuthException` (network-request-failed) | `firebase_network` | `error_category=network` |
| `PlatformException` (inesperada) | `platform_unexpected` | `error_category=platform_unexpected` |
| catch genérico | `unexpected` | `error_category=unexpected` |

**Sanitización del endpoint:** la función `sanitizeEndpoint()` elimina query string, fragmento, y enmascara segmentos dinámicos (UUID v4, números puros, hex 24+ chars) como `:id`. Trunca a 100 chars (límite GA4 de valor string).

### 2.5 Crashlytics — handlers globales (fatales)

| Handler | Razón / Params | Comportamiento |
|---------|----------------|----------------|
| `FlutterError.onError` | `details.exceptionAsString()` como `reason`, `fatal: true` | Solo en release; el reason puede contener texto de excepción de Flutter (no PII de usuario, sí stack de framework) |
| `PlatformDispatcher.instance.onError` | Sin reason, `fatal: true` | Solo en release |
| `runZonedGuarded` en `main.dart` | `fatal: false` en zone handler | Solo en release |

> **Nota de PII:** El campo `reason` en crashes fatales puede incluir mensajes de excepción de Flutter/Dart. Esto es estándar de Crashlytics para crashes reales (no analítica GA4). No constituye una violación de la política no-PII de la analítica (GA4), sino el comportamiento esperado de la herramienta de crash reporting. Los mensajes de excepción de Flutter no contienen PII de usuario en el flujo normal de la app.

---

## 3. Política no-PII — Definición y checklist

### 3.1 Campos prohibidos como valor de parámetro o custom key

Los siguientes tipos de dato **NUNCA** deben aparecer como valor de un parámetro de Analytics ni como `information` de Crashlytics:

| Tipo de dato | Ejemplos concretos | Por qué está prohibido |
|---|---|---|
| Email | `user@example.com` | PII directa |
| Nombre / apellido | `Juan García` | PII directa |
| Teléfono | `+57 300 123 4567` | PII directa |
| Placa / patente | `ABC-123` | PII directa |
| VIN | `1HGBH41JXMN109186` | PII directa |
| Nombre de aseguradora | `Sura`, `Allianz` | Cuasi-PII / alta cardinalidad |
| Número de póliza SOAT | `98765432` | PII directa |
| Coordenadas (lat/lng) | `4.7109886, -74.0721372` | PII de ubicación |
| uid de Firebase en claro | `QabcXYZ123...` | Identificador linkeable |
| ID de evento / registro / vehículo | UUIDs dinámicos | Alta cardinalidad + linkeable |
| FCM token | `fGk3...` | Alta cardinalidad + PII de dispositivo |
| URL con id en path | `/events/abc-123` | Alta cardinalidad |
| Body de request/response | JSON crudo | Puede contener cualquier PII |
| Texto libre del usuario | Notas de mantenimiento | Alta cardinalidad + PII potencial |

### 3.2 Valores permitidos

| Tipo | Ejemplos |
|---|---|
| uid hasheado SHA-256 | `a3f1...` (64 chars hex) — solo en `setUserId` |
| Enums cerrados | `email`, `google`, `apple`, `network`, `valid`, `expired`, `lead`, `rider` |
| Contadores/agregados | `result_count: 5`, `rider_count: 12`, `upcoming_events_count: 3` |
| Booleanos como int | `had_photo: 1`, `is_owner: 0`, `has_main_vehicle: 1` |
| Nombres de pantalla canónicos | `event_detail`, `garage`, `profile` (sin `:id`) |
| Categorías de error | `invalid_credentials`, `network`, `not_found` |
| Paso de wizard | `personal`, `medical`, `emergency`, `vehicle` |

---

## 4. Auditoría no-PII por feature (11 features)

Estado de la auditoría realizada en la Fase 10 (2026-06-04). Todos los call sites fueron inspeccionados manualmente contra el catálogo de la Sección 2.

| Feature | Eventos esperados | Params auditados | Sin PII | Hallazgos | Firmado por |
|---------|-------------------|------------------|---------|-----------|-------------|
| **Authentication** | `auth_flow_started`, `auth_method_selected`, `auth_succeeded`, `auth_failed`, `auth_abandoned`, `auth_first_home_entry` | `auth_method`, `auth_error_category` (categoría, nunca msg crudo) | ✓ | Ninguno | Fase 10 |
| **Home** | `home_viewed` | `upcoming_events_count` (int), `has_main_vehicle` (0/1) | ✓ | Ninguno | Fase 10 |
| **Events (lectura)** | `events_list_viewed`, `event_detail_viewed` | `result_count`, `list_scope`, `event_type` (enum), `event_state` (enum), `is_owner` (0/1), `is_read_only` (0/1), `source` (enum) | ✓ | Ninguno | Fase 10 |
| **Events (escritura)** | `events_create_started`, `events_draft_saved`, `events_published`, `events_publish_failed`, `events_delete_attempted`, `events_delete_succeeded`, `events_delete_failed` | `form_mode` (enum), `failure_category` (categoría) | ✓ | Ninguno | Fase 10 |
| **Event Registration (wizard)** | `registration_started`, `registration_step_advanced`, `registration_step_back`, `registration_submitted`, `registration_submit_failed`, `registration_abandoned` | `step_index` (int), `step_name` (enum), `form_mode` (enum), `failure_category` (categoría) | ✓ | Ninguno | Fase 10 |
| **Event Registration (aprobación)** | `registration_approved`, `registration_rejected`, `registration_ready_for_edit`, `registration_approval_failed` | `approval_action` (enum) | ✓ | Ninguno | Fase 10 |
| **Event Registration (mis registros)** | `registration_my_list_viewed`, `registration_cancelled` | — | ✓ | Ninguno | Fase 10 |
| **Live Tracking + SOS** | `tracking_session_started`, `tracking_session_ended`, `tracking_snapshot_received`, `sos_activated`, `sos_confirmed`, `sos_cleared` | `tracking_role` (enum), `tracking_end_reason` (enum), `rider_count` (int, agregado), `sos_clear_reason` (enum). **Las coordenadas (lat/lng) NUNCA salen como param; el cubit las usa internamente para distancia pero no las envía a Analytics.** | ✓ | Ninguno | Fase 10 |
| **Vehicles + Garage** | `vehicle_added`, `vehicle_updated`, `vehicle_deleted`, `vehicle_set_main` | `had_photo` (0/1) | ✓ | Ninguno | Fase 10 |
| **Maintenance + SOAT** | `maintenance_added`, `maintenance_history_viewed`, `soat_scan_attempted`, `soat_scan_success`, `soat_scan_failed`, `soat_status_viewed`, `soat_manual_saved` | `maintenance_type` (enum), `maintenance_mode` (enum), `result_count` (int), `fields_extracted_count` (int), `insurer_detected` (0/1 — nunca el nombre), `had_pdf` (0/1), `soat_status` (enum), `failure_reason` (enum) | ✓ | Ninguno | Fase 10 |
| **Profile + Users + Notifications** | `profile_viewed`, `profile_edit_started`, `profile_edit_succeeded`, `rider_profile_viewed`, `notification_marked_read`, `notifications_all_read`, `fcm_token_registered` | `notification_type` (enum) | ✓ | Ninguno | Fase 10 |

**Veredicto final: CERO violaciones de PII encontradas en los 11 features.**

---

## 5. Validación de límites GA4

Verificado en código fuente. Todos los nombres de evento cumplen ≤40 chars y los valores de param son `Object` (int o String), sin `bool` crudo.

| Límite GA4 | Cumplimiento |
|---|---|
| Nombre de evento ≤40 chars | ✓ — el evento más largo es `registration_approval_failed` (28 chars) |
| Clave de parámetro ≤40 chars | ✓ — la clave más larga es `upcoming_events_count` (21 chars) |
| Valor string ≤100 chars | ✓ — todos los valores son enums cortos, ints o el endpoint sanitizado (truncado a 100) |
| Tipo de params `Map<String, Object>` | ✓ — definido en la firma de `AnalyticsService.logEvent` |
| Sin `bool` crudo | ✓ — todos los booleanos van como `int` 0/1 |

El test guardián `analytics_taxonomy_no_pii_test.dart` automatiza la verificación de nombre ≤40 chars y snake_case.

---

## 6. Procedimiento de verificación manual en GA4 DebugView

### Prerrequisito común
1. Build en staging/release con DebugView habilitado (ver Sección 1).
2. Abrir Firebase Console → tu proyecto → Analytics → DebugView.
3. La vista se refresca ~cada 2 segundos.

### 6.1 Embudo de auth (Auth feature)

| Acción en la app | Evento esperado en DebugView | Params a verificar |
|---|---|---|
| Entrar a la pantalla de login | `auth_flow_started` | `auth_method = login` |
| Salir de la pantalla sin autenticarse | `auth_abandoned` | `auth_method = login` |
| Pulsar "Iniciar con Google" | `auth_method_selected` | `auth_method = google` |
| Autenticación exitosa | `auth_succeeded`, luego `auth_first_home_entry` | `auth_method = google` |
| Introducir credenciales incorrectas | `auth_failed` | `auth_method = email`, `auth_error_category = invalid_credentials` |
| **Verificación no-PII:** inspeccionar todos los params del evento `auth_succeeded` | **No debe aparecer email, uid en claro, ni nombre** | Confirmar que `auth_method` solo es `email/google/apple` |

### 6.2 Home

| Acción | Evento | Params |
|---|---|---|
| Entrar a home tras login | `home_viewed` | `upcoming_events_count = <int>`, `has_main_vehicle = 0 o 1` |

### 6.3 Events — lectura

| Acción | Evento | Params |
|---|---|---|
| Ver la lista de todos los eventos | `events_list_viewed` | `result_count = <int>`, `list_scope = all` |
| Cambiar a "mis eventos" | `events_list_viewed` | `list_scope = mine` |
| Abrir detalle de un evento | `event_detail_viewed` | `event_type = <enum>`, `event_state = scheduled`, `source = list`, `is_owner = 0 o 1` |
| **Verificación no-PII:** `event_detail_viewed` | **No debe aparecer event_id, nombre del evento, city** | Solo enums y flags |

### 6.4 Events — escritura y registro

| Acción | Evento | Params |
|---|---|---|
| Crear evento (botón +) | `events_create_started` | `form_mode = create` |
| Guardar borrador | `events_draft_saved` | `form_mode = create` |
| Publicar evento | `events_published` | `form_mode = create` |
| Registrarse en un evento | `registration_started` | — |
| Avanzar al paso 2 | `registration_step_advanced` | `step_index = 1`, `step_name = medical` |
| Enviar registro | `registration_submitted` | `form_mode = create` |

### 6.5 Live Tracking y SOS

| Acción | Evento | Params |
|---|---|---|
| Unirse al tracking de una rodada | `tracking_session_started` | `tracking_role = rider o lead` |
| Primer snapshot de riders | `tracking_snapshot_received` | `rider_count = <int>` |
| Activar SOS | `sos_activated` | `tracking_role = rider o lead` |
| Cancelar SOS | `sos_cleared` | `sos_clear_reason = user_cancel` |
| Salir de la pantalla de tracking | `tracking_session_ended` | `tracking_end_reason = user_left` |
| **Verificación crítica no-PII:** ningún evento de tracking | **No debe aparecer latitude, longitude, userId, eventId** | Solo role, count, enums |

### 6.6 Garage, Mantenimiento y SOAT

| Acción | Evento | Params |
|---|---|---|
| Agregar vehículo con foto | `vehicle_added` | `had_photo = 1` |
| Marcar vehículo como principal | `vehicle_set_main` | — |
| Escanear SOAT con imagen | `soat_scan_attempted`, luego `soat_scan_success` o `soat_scan_failed` | Ver Sección 2.1 |
| Ver estado de SOAT | `soat_status_viewed` | `soat_status = valid o expired o expiringSoon` |
| Agregar mantenimiento | `maintenance_added` | `maintenance_type = <enum>`, `maintenance_mode = completed o scheduled` |
| **Verificación no-PII:** `soat_scan_success` | **No debe aparecer placa, VIN, nombre de aseguradora** | Solo `insurer_detected = 0 o 1` |

### 6.7 Perfil, Users y Notificaciones

| Acción | Evento | Params |
|---|---|---|
| Ver perfil propio | `profile_viewed` | — |
| Editar perfil | `profile_edit_started`, luego `profile_edit_succeeded` | — |
| Ver perfil de otro rider | `rider_profile_viewed` | — |
| Marcar notificación como leída | `notification_marked_read` | `notification_type = <enum>` |
| Marcar todas como leídas | `notifications_all_read` | — |
| **Verificación no-PII:** | **No debe aparecer userId del rider visitado, email, ni texto de notificación** | Solo `notification_type` |

---

## 7. Procedimiento de verificación en Crashlytics (no-fatales)

### 7.1 Forzar un no-fatal de prueba

**Opción A — timeout de red (simulado):**
1. En el emulador, cortar la conectividad: **Settings → Network → Airplane mode ON**.
2. Realizar cualquier acción que llame al backend (p.ej. abrir la lista de eventos).
3. El `handlerExceptionHttp` capturará el `DioException.connectionTimeout` y emitirá un no-fatal.

**Opción B — respuesta 5xx (si hay acceso al backend):**
1. En staging, configurar un endpoint para retornar 500 (o usar un proxy como Charles).
2. Hacer la llamada desde la app → `handlerExceptionHttp` reporta con `error_category=network`, `http_status=500`.

### 7.2 Verificar en la consola de Crashlytics

1. Firebase Console → tu proyecto → Crashlytics → pestaña "Non-fatals".
2. Filtrar por la sesión activa (puede tardar 2–5 minutos en aparecer).
3. Abrir el reporte y verificar:
   - **Mensaje:** debe ser el tipo de excepción Dart (`DioException`, etc.), no el body de la respuesta.
   - **Custom keys / information:** deben aparecer como `error_category=network`, `http_status=500`, `endpoint=api.rideglory.com/events` (nunca con id dinámico en claro).
   - **NO debe aparecer:** body de request, body de response, token de auth, email de usuario, uid en claro.

### 7.3 Verificar sanitización del endpoint

Ejemplo de verificación manual:
- URL real: `https://api.rideglory.com/api/events/3fa85f64-5717-4562-b3fc-2c963f66afa6`
- URL en Crashlytics custom key: `api.rideglory.com/api/events/:id`

Si la URL conserva el UUID, hay una regresión en `sanitizeEndpoint()`.

---

## 8. Verificación del gating debug/test

### 8.1 Confirmar que en kDebugMode Analytics no reporta

```bash
# Correr en debug mode
flutter run
# Ir a Firebase Console → Analytics → DebugView
# NO debe aparecer el dispositivo en la lista de dispositivos activos
```

### 8.2 Confirmar que la suite de tests usa la no-op impl

```bash
flutter test
# Ningún test debe fallar por "Firebase not initialized"
# El NoOpCrashReporter y el MockAnalyticsService capturan las llamadas sin contactar Firebase
```

### 8.3 Verificar gating de crash handlers

En el archivo `lib/core/services/crash/crash_handler_setup.dart`:
```dart
// Solo se registran cuando !isDebug
void registerCrashHandlers({required bool isDebug, ...}) {
  if (isDebug) return; // ← gating
  ...
}
```

En `main.dart`, el flag `isDebug` recibe `kDebugMode`. En debug builds, los handlers no se registran.

---

## 9. Hallazgos y tareas pendientes (no bloquean Fase 11)

**Ningún hallazgo de violación de PII** fue encontrado durante la auditoría de la Fase 10.

Los siguientes son **AC nice-to-have diferidos** (documentados como pendientes, no como violaciones):

| ID | Descripción | Feature | Fase de origen | Prioridad |
|----|-------------|---------|----------------|-----------|
| TASK-NTH-01 | Agregar evento `vehicle_archived` si en el futuro se introduce la función de archivar vehículos (distinto de eliminar). | Vehicles | Fase 9 | Baja |
| ~~TASK-NTH-02~~ | ✅ **Implementado** — `maintenance_updated` + `maintenance_deleted` instrumentados (CRUD completo de mantenimiento). | Maintenance | Fase 9 → hecho | — |
| ~~TASK-NTH-03~~ | ✅ **Implementado** — `soat_updated` + `soat_deleted` instrumentados (CRUD completo de SOAT). | SOAT | Fase 9 → hecho | — |
| TASK-NTH-04 | Agregar user property `has_soat` (0/1) después de que el rider cargue o actualice su SOAT, para segmentación en GA4. | SOAT | Fase 9 | Media |
| TASK-NTH-05 | Agregar event `registration_viewed` al abrir el detalle de una inscripción propia, para medir tasa de abandono post-envío. | Event Registration | Fase 7 | Baja |
| TASK-NTH-06 | Agregar `events_filter_applied` con param `filter_type` (enum) para medir uso de filtros en la lista de eventos. | Events | Fase 6 | Baja |
| TASK-NTH-07 | En el handler fatal de `FlutterError.onError`, evaluar si `details.exceptionAsString()` puede incluir PII en edge cases (e.g., un assertion con datos de usuario). Mitigación actual: los datos de usuario nunca aparecen en assertions de framework. | Core / Crash | Fase 4 | Baja |

**Estas tareas no bloquean la Fase 11 (opt-out de analítica).** Se pueden abordar en un ciclo de iteración posterior.

---

## 10. Test guardián automatizable

El test `test/core/services/analytics/analytics_taxonomy_no_pii_test.dart` corre como parte de `flutter test` y falla si:

- Un nombre de evento supera 40 chars.
- Un nombre de evento o clave de parámetro no es snake_case.
- Una clave de parámetro o nombre de evento contiene substrings PII prohibidos (email, latitude, longitude, user_id, event_id, vehicle_id, etc.).
- El catálogo tiene menos constantes de las esperadas (detección de eliminación accidental).
- Hay nombres de evento o claves de parámetro duplicadas.
- Un nombre de pantalla canónico contiene `:` (indicador de id dinámico sin enmascarar).

**Comando de ejecución:**
```bash
flutter test test/core/services/analytics/analytics_taxonomy_no_pii_test.dart
```

**Complemento manual (CI-friendly):**
```bash
# Verificar regla G1: ningún logEvent con literal directo (debe retornar vacío)
grep -rn "logEvent('" lib/ | grep -v ".g.dart\|.freezed.dart"
grep -rn 'logEvent("' lib/ | grep -v ".g.dart\|.freezed.dart"
```

---

## 11. Referencias

- Taxonomía de eventos: `lib/core/services/analytics/analytics_events.dart`
- Taxonomía de parámetros: `lib/core/services/analytics/analytics_params.dart`
- Nombres de pantalla: `lib/core/services/analytics/analytics_screen_names.dart`
- Contrato del servicio: `lib/core/services/analytics/analytics_service.dart`
- Hash de uid: `lib/core/services/analytics/analytics_uid_hasher.dart`
- Sanitización de endpoint: `lib/core/http/network_error_classifier.dart:sanitizeEndpoint`
- No-fatales de red: `lib/core/http/rest_client_functions.dart:handlerExceptionHttp`
- Gating de crash handlers: `lib/core/services/crash/crash_handler_setup.dart`
- Test guardián: `test/core/services/analytics/analytics_taxonomy_no_pii_test.dart`
- Catálogo de tests: `docs/testing/TEST_CATALOG.md`
- Standards y reglas: `.cursor/rules/rideglory-coding-standards.mdc`
