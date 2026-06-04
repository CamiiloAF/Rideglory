# 05 — Síntesis del PO: Analíticas + Crashlytics (cobertura total)

- Slug: `analytics-crashlytics-cobertura-total`
- Fecha (UTC): 2026-06-04T01:00:22Z
- Insumos: `02-po-proposal.md`, `03-architect-review.md`, `04-plan-review.md`
- Sesión: PLANEACIÓN (no se modifica código de la app)
- Esquema de IDs: **única numeración 1..11** (ver Crosswalk). Toda la prosa de este
  documento usa exclusivamente los IDs 1..11; los nombres "FX" del Architect/Plan Review
  se conservan SOLO en la tabla Crosswalk.

## Overview

Rideglory gana **observabilidad de producto end-to-end** (recorrido de pantallas, embudos
por feature, errores reales de usuarios y crashes simbolizados) sobre el stack ya decidido
(Firebase Analytics GA4 + Crashlytics) más una **capa abstracta propia en `core/`** inyectada
por DI. La entrega es **incremental y sin regresión**: las fases 1–9 son **cero-UI** (no
añaden ni cambian pantallas); la única superficie de UI nueva es el **opt-out** (fase 11).
Cada fase deja la app funcional y aporta datos verificables (GA4 DebugView / consola
Crashlytics) desde su cierre.

El orden mantiene la recomendación del Architect (fundaciones → taxonomía → dos palancas
baratas → embudos por dominio → privacidad): primero las **fundaciones + gating + regla de
capa** (fase 1), luego la **taxonomía centralizada con el mapa canónico de rutas y los
límites GA4** (fase 2), después las **dos palancas más baratas y de mayor cobertura**
(screen_view automático en fase 3, no-fatales de red en fase 4), seguido de los **embudos
por dominio** (fases 5–9) y finalmente **privacidad/auditoría/opt-out/QA** (fases 10–11).

Respecto a la propuesta original de 10 fases, esta síntesis aplica **dos splits** pedidos en
review para que ninguna fase quede sobredimensionada o "sin cerrar":
- el núcleo de eventos (legacy F6) se parte en **lectura (fase 6)** y **escritura/aprobación
  (fase 7)**;
- la fase de privacidad/verificación (legacy F10) se separa en **auditoría no-PII + doc QA
  (fase 10)** y **UI de opt-out (fase 11)**, de modo que el opt-out cierre aunque la
  auditoría deje hallazgos como tareas.

## Crosswalk (FX-legacy → ID de esta tabla)

| Nombre legacy (en 02/03/04) | ID(s) en esta síntesis | Nota |
|---|---|---|
| F1 — Fundaciones + crashes | **1** | sin cambio de alcance |
| F2 — Taxonomía + migración soat | **2** | + mapa canónico de rutas + límites GA4 |
| F3 — screen_view automático | **3** | dedupe explícito para `StatefulShellRoute.indexedStack` |
| F4 — No-fatales de red | **4** | enganche en `handlerExceptionHttp`, no en `executeService` |
| F5 — Auth / onboarding | **5** | `setUserId` SHA-256 client-side |
| **F6 — Núcleo de eventos** | **6 + 7** | **split**: 6 = lectura, 7 = escritura/aprobación |
| F7 — Tracking en vivo + SOS | **8** | solo hitos; nunca pings |
| F8 — Garaje / mant / SOAT | **9** | fusionada con perfil/users/notif en fase 9 |
| F9 — Perfil / users / notif | **9** | fusionada con garaje/mant/SOAT; alcance mínimo verificable por feature |
| **F10 — Privacidad / opt-out / QA** | **10 + 11** | **split**: 10 = auditoría no-PII + doc QA; 11 = UI opt-out |

Equivalencias rápidas (para leer 03/04 sin ambigüedad):
- `F6-Núcleo (02/03/04)` = **fases 6 + 7**.
- `F7-Tracking (03)` = **fase 8**.
- `F8-Garaje (03)` + `F9-Perfil (03)` = **fase 9** (alcance mínimo verificable por feature).
- `F10-opt-out (03/04)` = **fase 11**; `F10-auditoría/doc QA (03/04)` = **fase 10**.

## Cambios aplicados

Todos los IDs siguientes refieren al esquema 1..11 de esta síntesis.

1. **Fase 4 — punto de enganche corregido.** El reporte de no-fatales se engancha en
   `handlerExceptionHttp` (`lib/core/http/rest_client_functions.dart` L15–70), donde existen
   los `catch` por tipo (`DioException` L21, `FirebaseAuthException` L33, `PlatformException`
   L45, `DomainException` L57, genérico L59) y el `stackTrace`. **No** en `executeService`,
   que solo mapea `ApiResult`→`Either`.
2. **Fase 2 — entrega ampliada.** Además de la taxonomía y la migración de los 3 eventos de
   `soat`, la fase 2 entrega (a) el **mapa canónico ruta→nombre estable sin ids/params**
   (insumo de la fase 3) y (b) la **convención de límites GA4**: nombre de evento ≤40 chars,
   param key ≤40, value string ≤100, params de tipo `Object`, **sin bool → 0/1** (el use case
   de soat ya documenta este aprendizaje).
3. **Fase 1 — regla de capa como decisión explícita (G0).** Se escribe una sola regla:
   `AnalyticsService` y `CrashReporter` son **abstracciones puras en `core/`** (Dart puro,
   sin Flutter ni SDK), consumibles por domain y presentation; el SDK Firebase aparece SOLO
   en la impl `@Injectable(as: Interface)` bajo `core/services/.../firebase_*`. Se declara
   que el call site de `ScanSoatUseCase` **YA cumple** (domain depende de abstracción core
   pura, no de infraestructura) → **sin refactor**, solo normalización del call site a la
   constante de taxonomía cuando llegue la fase 2.
4. **Fase 1 — cableado de captura.** `runZonedGuarded` envuelve **`configureDependencies()` +
   `runApp()`** en la misma zona; se registran `FlutterError.onError` y
   `PlatformDispatcher.onError` antes de `runApp`. Los handlers **no reportan en
   `kDebugMode`**. Gating de tests: no-op impl + `setEnabled(false)`.
5. **Fase 5 — `setUserId` hasheado.** Se fija uid de Firebase **hasheado SHA-256 en cliente**
   dentro de `AuthCubit` (excepción singleton/router), client-side por defecto, **sin tocar
   `GET /me`**.
6. **Fase 11 (opt-out) — no existe `settings_page`.** Verificado: `profile/presentation/`
   solo tiene `profile_page` y `edit_profile_page`. El opt-out se aloja en la sección
   "Ajustes" del perfil (dentro de `ProfileActionsList`). Se persiste en
   `UserStorageService`/SharedPreferences. (La auditoría no-PII y el doc QA viven en la
   **fase 10**, separada — no confundir la fase 11 de opt-out con la fase 10 de auditoría.)
7. **Fase 11 — widget del opt-out.** `ProfileActionsList` **no es un form**, y `AppSwitchTile`
   exige `FormBuilder` ancestro → se usa el átomo **`AppSwitch`** (`value`/`onChanged`) en una
   **fila propia (clase y archivo propios)** consistente con `ProfileMenuItem`. Knob "on"
   **oscuro** (`darkBgPrimary`/`onPrimary`), nunca blanco.
8. **Fase 11 — default y política definidos en el plan.** Default **opt-in** (colección
   activa por defecto; analítica anónima sin PII, alineada con la política de privacidad).
   El opt-out la desactiva vía `setEnabled(false)`. Se alinea `docs/privacy-policy.html`
   (mención explícita de analítica anónima + Crashlytics + cómo desactivarla). Estado de
   **error al persistir**: si falla SharedPreferences → **revertir el switch** y mostrar aviso
   ES sentence-case.
9. **Fase 8 (tracking/SOS) — solo hitos.** Se enumeran los hitos exactos: inicio de sesión,
   fin de sesión, snapshot, **SOS activado / confirmado / cerrado**. **Prohibido por escrito**
   loguear cada ping de ubicación o mensaje WebSocket; **coordenadas fuera de params**.
10. **Fase 6 (núcleo de eventos) — partida.** Legacy F6 se divide en **fase 6 (lectura)** y
    **fase 7 (escritura/aprobación)** para mantener fases comparables y revisables.
11. **Fase 9 — alcance mínimo verificable por feature.** Al fusionar garaje/mant/SOAT con
    perfil/users/notif, se fija qué eventos son **obligatorios** vs **nice-to-have** por
    feature (ver Criterios de aceptación), para que no sea una fase que no cierra.
12. **Fase 4 — matriz anti doble-conteo + severidad (G5).** Se publica la matriz "categoría
    de error → único punto que reporta" y la política de severidad; se **sanitizan
    mensajes/URLs** antes de `recordError`.
13. **Fase 3 — dedupe del shell.** Confirmado: el router usa
    `StatefulShellRoute.indexedStack` (`lib/shared/router/app_router.dart` L141). El
    `NavigatorObserver` debe **deduplicar al cambiar de tab del IndexedStack** (no solo en
    `pushReplacement`): cada branch del shell debe emitir **un** `screen_view` por activación
    de tab, sin duplicar el de la ruta hija ni re-emitir al volver a un tab ya visitado
    consecutivamente.
14. **Transversal — tests con mock.** Cada fase que añade call sites añade su **test unitario
    con mock** de `AnalyticsService`/`CrashReporter` (no solo DebugView). La no-op impl se
    provee en la fase 1.
15. **Transversal — "sin UI / sin regresión" + estado de captura.** Cada fase 1–9 declara
    explícitamente "sin UI / sin regresión de comportamiento" y su **estado de captura**
    (activa en release / off en debug / no-op en tests) para que QA no busque pantallas
    inexistentes.

## Estado de captura por fase

Esquema de IDs 1..11. "Estado de captura" = cómo se comporta la instrumentación según build.

| Fase | ¿UI nueva? | Captura en release | Captura en debug | En tests |
|---|---|---|---|---|
| 1 Fundaciones + crashes + gating + regla de capa | No | Activa (crash handlers reportan) | Off (handlers no reportan en `kDebugMode`) | No-op + `setEnabled(false)` |
| 2 Taxonomía + mapa rutas + límites GA4 + migración soat | No | Activa (soat normalizado) | Off | No-op (mock en test de soat) |
| 3 screen_view automático | No | Activa | Off | No-op (mock del observer) |
| 4 No-fatales de red | No | Activa (solo categorías accionables) | Off | No-op (mock) |
| 5 Embudos auth/onboarding + setUserId | No | Activa | Off | No-op (mock) |
| 6 Núcleo eventos — LECTURA | No | Activa | Off | No-op (mock) |
| 7 Núcleo eventos — ESCRITURA/APROBACIÓN | No | Activa | Off | No-op (mock) |
| 8 Tracking en vivo + SOS (solo hitos) | No | Activa | Off | No-op (mock) |
| 9 Garaje/mant/SOAT + perfil/users/notif | No | Activa | Off | No-op (mock) |
| 10 Auditoría no-PII + doc QA | No | n/a (revisión, no añade call sites) | n/a | n/a |
| 11 Opt-out (UI) | **Sí** | Activa hasta opt-out; `setEnabled(false)` al desactivar | Off | No-op |

## Lista final de fases

Touchpoints y criterios de aceptación por fila (DebugView/consola + test unitario con mock).
Rutas siempre absolutas a partir de la raíz del repo.

| ID | Título | Goal | Resumen | dependsOn | Touchpoints (rutas de código) | Criterios de aceptación (observables y testeables) |
|----|--------|------|---------|-----------|-------------------------------|----------------------------------------------------|
| 1 | Fundaciones de observabilidad, captura de crashes y regla de capa | El equipo recibe automáticamente crashes fatales y no-fatales de cualquier usuario, con gating en debug/tests, sin que la app cambie de comportamiento. | Añadir `firebase_crashlytics` (+setup nativo Gradle Android y dSYM iOS). Ampliar `AnalyticsService` (`logScreenView`, `setUserId`, `setUserProperty`, `setEnabled`). Crear abstracción `CrashReporter` + impl Crashlytics + **no-op impl** para tests. Proveer por DI. Cablear `runZonedGuarded(configureDependencies()+runApp())` + `FlutterError.onError` + `PlatformDispatcher.onError`; handlers no reportan en `kDebugMode`. **Escribir la regla de capa (G0)** y declarar que el call site de soat ya cumple. | — | `pubspec.yaml`; `android/settings.gradle.kts` (L23 google-services), `android/app/build.gradle.kts` (L4–6); iOS dSYM/build phase; `lib/main.dart` (L26–54, sin runZonedGuarded hoy); `lib/core/di/firebase_module.dart` (L21 FirebaseAnalytics lazySingleton); `lib/core/services/analytics/analytics_service.dart` (L5–7 interfaz); nueva abstracción `CrashReporter` en `core/` | (a) Crash de prueba forzado aparece **simbolizado** en consola Crashlytics en build staging **Android e iOS**. (b) Un fallo de init de Crashlytics **no** rompe `runApp` (degrada silencioso, sin pantalla en blanco). (c) En `kDebugMode` los handlers no reportan (verificable en log). (d) Test unitario: con no-op impl + `setEnabled(false)`, `flutter test` no intenta enviar eventos; `dart analyze` limpio. (e) Grep: 0 imports de `package:firebase_crashlytics`/`firebase_analytics` fuera de `core/services/.../firebase_*`. |
| 2 | Taxonomía centralizada, mapa de rutas, límites GA4 y migración soat | El analista tiene un catálogo único, documentado y sin PII de eventos/parámetros, más el mapa de rutas y las reglas GA4 que toda la instrumentación reutiliza. | Constantes centralizadas de eventos/params (snake_case, prefijo por feature). Convención de límites GA4 (≤40/≤40/≤100, `Object`, sin bool→0/1). **Mapa canónico ruta→nombre estable sin ids/params**. Doc de taxonomía + política no-PII. Migrar los 3 eventos `soat` a constantes y auditar sus params contra checklist no-PII. | 1 | `lib/features/soat/domain/usecases/scan_soat_usecase.dart` (3 strings mágicos: `soat_scan_attempted/success/failed`); nuevas clases de constantes en `core/services/analytics/`; doc taxonomía en `docs/`; mapa de rutas vs `lib/shared/router/app_router.dart` (~37 rutas) | (a) DebugView: los 3 eventos `soat` siguen llegando con nombres normalizados. (b) **G1**: grep de `logEvent(` con literal directo = **0**. (c) Params de `soat_scan_success/failed` verificados agregados/booleanos, sin campos del documento (placa/aseguradora). (d) El mapa de rutas cubre las ~37 rutas con nombre estable sin `:id`. (e) Test: el use case de soat emite las constantes esperadas (mock de `AnalyticsService`). |
| 3 | Recorrido de pantallas automático (screen_view) | El analista ve en GA4 por qué pantallas pasa cada rider y dónde se queda, sin instrumentar pantalla por pantalla. | `NavigatorObserver` registrado en `GoRouter.observers` que emite `screen_view` por las ~37 rutas usando el mapa canónico de la fase 2. **Dedupe explícito para el `StatefulShellRoute.indexedStack`**. Respeta gating. | 1, 2 | `lib/shared/router/app_router.dart`: `GoRouter` (L63, hoy sin `observers`), `StatefulShellRoute.indexedStack` (L141) con branches por tab (home L151, garage L161, …); `GoRouter.observers`; nuevo observer en `lib/shared/router/` | (a) DebugView: navegar 5 rutas con params (`event_detail_by_id`, etc.) muestra **nombres estables sin id** (p.ej. `event_detail`). (b) **Cambiar de tab en el `StatefulShellRoute.indexedStack` (L141) emite un solo `screen_view` por activación de tab, sin duplicar la ruta hija ni re-emitir al volver al mismo tab consecutivamente** (no solo dedupe en `pushReplacement`). (c) `pushReplacement` no genera doble `screen_view`. (d) Test: simular `didPush`/`didChangeRoute` del observer con un mock y verificar 1 `logScreenView` por evento de navegación, incluido el cambio de branch del IndexedStack. |
| 4 | Captura de errores y no-fatales de red | El equipo ve en Crashlytics los fallos reales (5xx, timeouts, errores inesperados) categorizados, sin ruido ni doble-conteo. | Enganchar el reporte de no-fatales en `handlerExceptionHttp` (un solo sitio), categorizado por tipo de `catch`. Política de severidad + matriz "categoría→único punto que reporta" (G5). Sanitizar mensajes/URLs antes de `recordError`. | 1, 2 | `lib/core/http/rest_client_functions.dart`: `handlerExceptionHttp` (L15–70) — `DioException` L21, `FirebaseAuthException` L33, `PlatformException` L45, `DomainException` L57, genérico L59; **no** `executeService` | (a) Provocar timeout/5xx → no-fatal categorizado en consola con stackTrace. (b) 400/401/403/404/409 y `FirebaseAuthException` de credenciales **no** generan no-fatal (a lo sumo evento GA4). (c) `DomainException` ya capturada (L57) **no** se reporta dos veces. (d) Mensajes/URLs sin ids ni body en el reporte (sanitizados). (e) Test: cada rama de `catch` con mock de `CrashReporter` verifica reporta/no-reporta según la matriz. |
| 5 | Embudos de adquisición: autenticación y onboarding | El analista mide cuántos riders inician sesión/registro, por qué método y dónde abandonan, con uid anónimo. | Instrumentar `splash`→`authentication` (login, signup, forgot-password, Google/Apple): inicio, método, éxito/fallo/abandono, primera entrada a home. `setUserId` **SHA-256** del uid en `AuthCubit`; user properties no-PII. | 1, 2 | `lib/features/authentication/application/auth_cubit.dart`; `lib/features/splash/`; vistas auth (`LoginView`, `SignupView`, `ForgotPasswordView`); `setUserId` en `AuthCubit` (singleton/router) | (a) DebugView: embudo `splash→login/signup→home` con paso de inicio/método/éxito/fallo/**abandono**. (b) `setUserId` envía hash SHA-256, **nunca** uid en claro ni email. (c) User properties no-PII (método login, has_vehicle), nunca nombre/email. (d) **Sin** cambios en `GET /me`. (e) Test: login exitoso dispara `setUserId(hash)` + evento éxito (mock). |
| 6 | Embudo del núcleo de eventos — LECTURA (home + descubrir/ver) | El analista ve cómo los riders descubren y consultan rodadas (home, listar, ver detalle). | Instrumentar `home` (entrada/uso de secciones) y `events` lectura (listar, ver detalle, abrir borradores en solo-lectura) con params no-PII (sin id de evento como valor de alta cardinalidad). | 1, 2, 3 | `lib/features/home/`; `lib/features/events/presentation/` cubits de list/detail; rutas `events`, `event_detail_by_id` en `app_router.dart` | (a) DebugView: entrada a home + listar + ver detalle emiten eventos con nombres de la taxonomía. (b) Ningún param lleva id de evento como valor (cardinalidad/PII). (c) Test: el cubit de detalle dispara el evento de "ver detalle" (mock). (d) Sin UI/sin regresión. |
| 7 | Embudo del núcleo de eventos — ESCRITURA y aprobación | El analista entiende dónde se cae la conversión al crear/publicar eventos y en el workflow de aprobación. | Instrumentar `events` escritura (crear, publicar, guardar borrador) y `event_registration` (registrarse, solicitar/aprobar/rechazar/cancelar, ready-for-edit, "mis registros"). Embudos inicio→avance→éxito/abandono por flujo. | 1, 2, 6 | `lib/features/events/presentation/` cubits form/create/publish/delete/attendees; `lib/features/event_registration/`; `my_registrations` cubit | (a) DebugView: embudo crear-evento (inicio→pasos→publicar) y embudo registrarse/aprobar completos. (b) Estados de embudo por paso multistep: avance vs abandono. (c) Sin id de registro/rider como param de valor. (d) Test: aprobar un registro dispara el evento correspondiente (mock). (e) Sin UI/sin regresión. |
| 8 | Embudos de tracking en vivo y SOS (solo hitos) | El equipo mide adopción/abandono del tracking en vivo y el contexto de activaciones de SOS, sin volumen ni PII. | Instrumentar **solo hitos**: inicio de sesión, fin de sesión, snapshot, **SOS activado/confirmado/cerrado**. Prohibido loguear cada ping de ubicación o mensaje WebSocket; coordenadas fuera de params. | 1, 2 | `lib/features/events/.../live_tracking_cubit` (`sosAlertResult`); `live_map_page.dart`; `participants_*`; `TrackingWsClient` (NO por mensaje) | (a) DebugView: iniciar/terminar sesión y disparar SOS de prueba → exactamente los hitos enumerados. (b) **Cero** eventos por ping de ubicación o mensaje WS (verificable navegando una sesión activa). (c) Ningún param contiene lat/lng. (d) Test: activar SOS en el cubit dispara 1 evento `sos_activated` (mock), sin eventos de ubicación. |
| 9 | Garaje, mantenimientos, SOAT, perfil, descubrimiento y notificaciones | El analista cierra la cobertura de los features restantes con un alcance mínimo verificable por feature. | Instrumentar con **alcance mínimo obligatorio**: vehículos (alta/edición/borrado, set principal), mantenimiento (alta, ver historial), SOAT (estado, captura manual), perfil (ver/editar), users (ver perfil de rider), notificaciones (abrir, marcar leída, registro FCM token). **Nice-to-have**: archivar vehículo, editar/borrar mantenimiento, detalle de descubrimiento. | 1, 2 | `lib/features/vehicles/` (7 usecases); `lib/features/maintenance/`; `lib/features/soat/`; `lib/features/profile/presentation/`; `lib/features/users/`; `lib/features/notifications/` | (a) DebugView (obligatorios): agregar vehículo, registrar mantenimiento, ver estado SOAT, editar perfil, abrir notificación → eventos presentes. (b) **G2**: nunca placa/VIN/aseguradora ni id de otro rider como param. (c) Notificación distingue recibida vs abierta. (d) Test: al menos un call site por feature (vehículo/mant/perfil/notif) verificado con mock. (e) Sin UI/sin regresión. |
| 10 | Auditoría no-PII transversal y documento de QA de analítica | El equipo tiene garantía documentada de cero PII y un procedimiento reproducible para validar toda la analítica. | Auditar todos los eventos/params/custom keys de las fases 2–9 contra checklist no-PII (uid hasheado, sin email/placa/coordenadas/ids dinámicos). Escribir doc de **QA de analítica** (cómo validar en DebugView/Crashlytics) + checklist de cobertura por feature. Hallazgos quedan como tareas, sin bloquear el opt-out (fase 11). | 2, 3, 4, 5, 6, 7, 8, 9 | Revisión transversal de constantes de `core/services/analytics/`; reportes en `handlerExceptionHttp`; doc QA en `docs/` | (a) Checklist no-PII firmado por feature (11 features). (b) Confirmado: 0 eventos/params con email/placa/VIN/coordenadas/ids dinámicos. (c) `setUserId` siempre hash. (d) Doc QA reproducible (pasos DebugView + Crashlytics). (e) Hallazgos pendientes registrados como tareas, sin bloquear la fase 11. |
| 11 | Privacidad: opt-out en perfil y alineación de la política | El rider controla su privacidad con un opt-out funcional, anónimo y sin PII, alineado con la política publicada. | UI de **opt-out** en la sección "Ajustes" del perfil usando el átomo **`AppSwitch`** en una fila/clase/archivo propios (NO `AppSwitchTile`, NO form). Default **opt-in**. Persistir en `UserStorageService`/SharedPreferences y llamar `setEnabled`. Strings ES en `app_es.arb`. Alinear `docs/privacy-policy.html`. Estado de error al persistir. | 1, 10 | `lib/features/profile/presentation/widgets/profile_actions_list.dart` (Column de `ProfileMenuItem`, NO form); nuevo widget de fila opt-out; `lib/shared/widgets/form/app_switch.dart`; `UserStorageService`; `lib/l10n/app_es.arb`; `docs/privacy-policy.html` | (a) Alternar opt-out: `setEnabled(false/true)` detiene/reanuda colección (verificable en DebugView). (b) Preferencia persiste entre arranques (SharedPreferences). (c) Default **opt-in** al primer arranque. (d) Fallo al persistir → **revierte el switch** + aviso ES sentence-case. (e) Widget propio (un widget/archivo), `AppSwitch` con knob "on" **oscuro**, touch target ≥44px. (f) `privacy-policy.html` menciona analítica anónima + Crashlytics + cómo desactivar. |

## Supuestos y riesgos

### Supuestos
- Stack cerrado (Firebase Analytics GA4 + Crashlytics + capa propia); no se reabre.
- Analítica **100% client-side**; `rideglory-api` **sin cambios** (uid hasheado en cliente,
  sin tocar `GET /me`).
- Regla de capa (fase 1) aplica a fases 2–9: abstracción `core` Dart-puro consumible por
  domain+presentación; SDK Firebase solo en `core/services/.../firebase_*`.
- Gating único (fase 1): no-op impl + `setEnabled(false)` + handlers no-report en
  `kDebugMode`, reutilizado por todas las fases.
- Verificación = DebugView/Crashlytics **+ test unitario con mock** en cada fase que añade
  call sites. La no-op impl la provee la fase 1.
- "Cobertura total" = los 11 features con embudo o interacciones clave instrumentadas; no
  implica loguear cada botón.
- Default de privacidad: **opt-in** (analítica anónima activa por defecto), opt-out explícito
  en perfil (fase 11). Performance/rendimiento percibido queda **fuera de alcance**.

### Riesgos
1. **Setup nativo de Crashlytics (fase 1).** Gradle Android + dSYM iOS frágiles; mal setup =
   crashes sin símbolos. *Mitigación*: criterio de aceptación = crash de prueba **simbolizado**
   en staging Android+iOS antes de cerrar la fase 1; documentar en handoff DevOps.
2. **Enganche equivocado en fase 4.** Si va en `executeService` se pierde categoría y
   stackTrace. *Mitigación*: la fase 4 fija `handlerExceptionHttp` (L15–70) como sitio único.
3. **Ruido / doble-conteo de no-fatales (fase 4).** *Mitigación*: política de severidad +
   matriz "categoría→único punto que reporta"; cubits no re-reportan errores de red.
4. **PII y alta cardinalidad.** Ids de evento/registro/rider, placa, VIN, aseguradora,
   coordenadas, email/nombre. *Mitigación*: taxonomía revisada (fase 2), uid hasheado
   (fase 5), auditoría transversal (fase 10); "ids canónicos de pantalla, nunca el valor
   dinámico".
5. **Volumen del tracking en vivo (fase 8).** *Mitigación*: solo hitos (start/stop/snapshot/
   SOS); cero pings ni mensajes WS.
6. **Gating insuficiente en tests/CI.** *Mitigación*: no-op + `setEnabled(false)` + handlers
   no-report en debug, verificado en fase 1 y reutilizado.
7. **Propagación de la anomalía de capa.** *Mitigación*: regla única de fase 1 (G0) verificada
   por el revisor de arquitectura antes de instrumentar features.
8. **Doble screen_view en el shell (fase 3).** El router usa `StatefulShellRoute.indexedStack`
   (`app_router.dart` L141): cambiar de tab puede emitir múltiples `screen_view`.
   *Mitigación*: el observer deduplica por activación de tab **y** en `pushReplacement`; nombres
   estables sin id desde el mapa de la fase 2.
9. **Fase 6 sobredimensionada (núcleo de eventos).** *Mitigación*: partida en lectura (fase 6)
   y escritura/aprobación (fase 7).
10. **Fase 9 que no cierra (muchos features).** *Mitigación*: alcance mínimo obligatorio vs
    nice-to-have fijado por feature en los criterios de aceptación.
11. **Fase 10/11 mezclando auditoría + UI + doc.** *Mitigación*: separadas — la auditoría
    no-PII y el doc QA (fase 10) no bloquean el opt-out (fase 11); hallazgos quedan como tareas.
12. **Opt-out con widget equivocado (fase 11).** `AppSwitchTile` exige `FormBuilder` y
    `ProfileActionsList` no es form. *Mitigación*: usar `AppSwitch` en fila/clase/archivo
    propios; knob "on" oscuro; estado de error revierte el switch.
13. **Versión `firebase_crashlytics` vs `firebase_core 4.x`.** *Mitigación*: resolver vía `pub`
    (no fijar a ciegas) + `flutter pub get` + `build_runner` en la fase 1.
