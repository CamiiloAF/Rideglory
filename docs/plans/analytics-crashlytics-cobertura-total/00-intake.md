# 00 — Intake: Analíticas + Crashlytics (cobertura total)

- Slug: `analytics-crashlytics-cobertura-total`
- Fecha (UTC): 2026-06-04T00:46:58Z
- Sesión: PLANEACIÓN (no se modifica código de la app)

## Fuente

`docs/improvements/analytics-crashlytics.md` (archivo existente, leído completo).

Objetivo declarado: instrumentar **toda** la app para observabilidad de producto
(cómo recorren los flujos, qué usan/no usan, dónde abandonan, errores/fallas) y
capturar crashes, con un stack ya decidido (no reabrir).

## Objetivo

Dotar a Rideglory de **observabilidad de producto end-to-end**: una capa propia
`AnalyticsService` + `CrashReporter` (abstracción en core, impl Firebase) inyectada por
DI, `screen_view` automático sobre todas las rutas de go_router, embudos por flujo
crítico (inicio→avance→éxito/abandono), captura de errores `ResultState.error` /
`DomainException` y crashes fatales + no-fatales en Crashlytics, todo con una
**taxonomía de eventos centralizada, documentada y sin PII**, desactivable en
debug/tests y verificable en GA4 DebugView / consola de Crashlytics. Entregable por
fases, dejando la app funcional y aportando datos accionables en cada una.

## Alcance percibido

### Stack decidido (no reabrir)
- Firebase Analytics (GA4) para eventos de producto.
- Firebase Crashlytics para crashes y no-fatales.
- Capa propia `AnalyticsService` (ya existe semilla) + nuevo `CrashReporter`.
- BigQuery export / GA4 funnels para análisis (configuración de consola, no código de app).

### Estado actual del repo (hallazgos relevantes)
- `firebase_analytics: ^12.0.0` **ya está** en `pubspec.yaml`. **NO** está
  `firebase_crashlytics` → habrá que añadirlo.
- Ya existe una **semilla** de la capa de analítica:
  - `lib/core/services/analytics/analytics_service.dart` — interfaz mínima:
    `Future<void> logEvent(String name, [Map<String, Object>? parameters])`.
  - `lib/core/services/analytics/firebase_analytics_service.dart` — impl
    `@Injectable(as: AnalyticsService)` envolviendo `FirebaseAnalytics`.
  - `FirebaseAnalytics` ya provisto como `@lazySingleton` en
    `lib/core/di/firebase_module.dart`.
  - Único call site actual: `lib/features/soat/domain/usecases/scan_soat_usecase.dart`
    (eventos `soat_scan_attempted` / `soat_scan_success` / `soat_scan_failed`).
    OJO: hoy el `AnalyticsService` se inyecta en un **use case de domain** (revisar
    encaje con Clean Architecture: ¿abstracción en domain o en core/services?).
- `lib/main.dart`: bootstrap **sin** `runZonedGuarded`, sin `FlutterError.onError`,
  sin handler de Crashlytics. `Firebase.initializeApp` + FCM + RemoteConfig +
  `configureDependencies()` + `runApp`. Raíz con `MultiBlocProvider`.
- Router: `lib/shared/router/app_router.dart` — `GoRouter` único estático, **sin
  `observers`** hoy (~32 `GoRoute`). Es el punto de enganche del `screen_view`
  automático (NavigatorObserver).
- Manejo de errores: `lib/core/http/rest_client_functions.dart` (`executeService`)
  mapea Dio/Firebase a `DomainException` → punto natural para loguear no-fatales.
- `ResultState<T>` (core/domain) con estado `Error` → fuente de eventos de error a nivel
  presentación/cubits.

### Features a cubrir (cobertura total, `lib/features/`)
`authentication`, `home`, `vehicles`, `events`, `event_registration`, `maintenance`,
`notifications`, `profile`, `soat`, `users`, `splash`.

### Embudos/flujos críticos candidatos (a confirmar en planeación)
- Auth (login/signup, Google/Apple).
- Crear evento.
- Registrarse a evento + workflow de aprobación de asistencia.
- Tracking en vivo / SOS.
- Garage / vehículos (alta/edición).
- Mantenimientos.
- SOAT (scan).
- Perfil / usuarios (descubrimiento).

### Trabajo transversal previsible (a desglosar por fases)
1. **Fundaciones**: ampliar `AnalyticsService` (screen_view, setUserId hasheado,
   setUserProperty, enable/disable); nuevo `CrashReporter` (abstracción + impl
   Crashlytics); añadir dep `firebase_crashlytics`; provisión DI; bootstrap en
   `main.dart` (`runZonedGuarded` + `FlutterError.onError` + zona).
2. **Taxonomía centralizada**: constantes de nombres de eventos/parámetros (sin
   strings mágicos), convención de naming, documento de taxonomía.
3. **screen_view automático**: `NavigatorObserver` registrado en `GoRouter.observers`.
4. **Captura de errores/no-fatales**: enganche en `executeService` /
   `DomainException` y en estados `ResultState.error`.
5. **Instrumentación por flujo/feature**: eventos de embudo e interacción, fase por feature.
6. **Privacidad/consentimiento**: hashing de user id, no PII, opt-out si aplica
   (Play/App Store), gating debug/tests, posible UI de consentimiento (strings `app_es.arb`).
7. **Verificación**: GA4 DebugView / consola Crashlytics; doc de cómo validar.

### Constraints (de la fuente, vinculantes)
- Clean Architecture: abstracción en core/domain, impl en data; presentación usa la
  abstracción (nunca SDK directo).
- Sin PII en eventos ni claves de Crashlytics; user id hasheado/anónimo.
- Taxonomía documentada y centralizada (constantes).
- Strings de UI en `app_es.arb` si se añade consentimiento/opt-out.
- Desactivable en debug/desarrollo y en tests.
- No big-bang: fases entregables, app siempre funcional.

### Fuera de alcance (esta planeación)
- Cambios en `rideglory-api` (analítica es client-side; salvo necesidad de user-id
  hasheado server-provided — a confirmar).
- Implementación de código de app (esta sesión solo produce el plan).
- Dashboards de negocio fuera de GA4/Crashlytics.

## Preguntas abiertas

1. **Encaje del `AnalyticsService` en capas**: hoy se inyecta en un use case de
   `domain` (soat). ¿La abstracción vive en `core/services` (como ahora) o se mueve a
   `core/domain`? ¿Domain puede depender de ella, o solo presentación/cubits? Definir
   regla única para evitar violaciones de arquitectura.
2. **Granularidad de eventos de interacción**: ¿se instrumentan todos los botones/CTAs
   "relevantes" manualmente, o se introduce un wrapper/helper en widgets shared
   (`AppButton`, tabs, filtros, `AppSwitch`) para auto-loguear con taxonomía? Impacta
   esfuerzo y consistencia.
3. **Estrategia de user id hasheado**: ¿hash del uid de Firebase en cliente (qué algo,
   sal), o el backend provee un id anónimo? ¿Aplica `setUserId` de GA4/Crashlytics?
4. **Consentimiento/opt-out**: ¿se requiere UI de consentimiento para Play/App Store en
   este alcance, o basta opt-out en ajustes? ¿Default opt-in u opt-out? ¿Afecta la
   política de privacidad ya publicada (`docs/privacy-policy.html`)?
5. **Gating debug/tests**: mecanismo preferido (flag de `AppEnv`/`--dart-define`,
   `kDebugMode`, `setAnalyticsCollectionEnabled(false)`, no-op impl en tests). Definir uno.
6. **Captura de no-fatales desde errores**: ¿logueamos automáticamente TODO
   `ResultState.error`/`DomainException` como no-fatal (riesgo de ruido), o solo
   categorías concretas (5xx, timeouts, inesperados)? Definir política de severidad.
7. **Migración del call site existente (soat)**: ¿se adapta a la nueva taxonomía
   centralizada en la fase de fundaciones o en la fase del feature soat?
8. **Verificación/QA de analítica**: ¿se exige tests unitarios sobre call sites con
   `AnalyticsService` mock, o validación manual vía DebugView, o ambos?
9. **Performance / rendimiento percibido** (punto 5 de la fuente, marcado "opcional"):
   ¿entra en este plan o se difiere a una fase posterior fuera de alcance inicial?
10. **Número y corte de fases**: confirmar el desglose entregable (p.ej. F1 fundaciones+
    screen_view+crash, F2 errores/no-fatales, F3..N un grupo de features por fase).
