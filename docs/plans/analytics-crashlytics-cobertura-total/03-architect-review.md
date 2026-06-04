# 03 — Architect Review: Analíticas + Crashlytics (cobertura total)

- Slug: `analytics-crashlytics-cobertura-total`
- Fecha (UTC): 2026-06-04T00:53:57Z
- Insumos: `01-scan.md`, `02-po-proposal.md`, código verificado en `lib/`
- Sesión: PLANEACIÓN (no se modifica código de la app)

Veredicto general: **ok con ajustes**. La descomposición del PO es técnicamente
sólida y respeta el stack existente (Firebase Analytics GA4 + Crashlytics + capa
abstracta por DI). Todo es **client-side**: `rideglory-api` no requiere cambios.
Los ajustes son de orden, precisión de puntos de enganche y una decisión de capa
que debe quedar fijada en F1 antes de tocar 11 features.

---

## Validación por fase

### F1 — Fundaciones de observabilidad y captura de crashes · Complejidad: **media-alta**
Viable. Verificado:
- `firebase_module.dart` ya provee `FirebaseAnalytics` como `@lazySingleton` (L21);
  añadir `FirebaseCrashlytics get firebaseCrashlytics => FirebaseCrashlytics.instance`
  es trivial y consistente con el patrón.
- `main.dart` hoy NO tiene `runZonedGuarded`/`FlutterError.onError`/`PlatformDispatcher.onError`
  (confirmado L26-54). El cableado debe envolver **tanto `configureDependencies()` como
  `runApp()`** dentro del mismo `runZonedGuarded` para capturar errores de arranque, y
  registrar `FlutterError.onError` y `PlatformDispatcher.onError` antes de `runApp`.
- La interfaz `AnalyticsService` (L5-7) hoy solo expone `logEvent`. Ampliarla con
  `logScreenView`, `setUserId`, `setUserProperty`, `setEnabled` es directo; la impl
  Firebase (L13-15) ya envuelve el SDK 1:1.
- `firebase_analytics: ^12` y `firebase_core: ^4.2.1` ya están; `firebase_crashlytics`
  debe alinearse al major compatible con `firebase_core 4.x` (verificar resolución de
  versión en `pub get`, no fijar a ciegas).

La complejidad real **no está en Dart** sino en el **setup nativo**:
- Android: añadir el plugin Gradle `com.google.firebase.crashlytics`. `settings.gradle.kts`
  ya declara `com.google.gms.google-services` (L23, apply false) y `app/build.gradle.kts`
  ya lo aplica (L4-6). Hay que añadir el plugin Crashlytics en ambos sitios siguiendo el
  mismo patrón, y habilitar subida de mapping/NDK.
- iOS: subida de dSYM (build phase / Fastlane / upload-symbols). Frágil; debe verificarse
  con crash de prueba en build real.

Riesgo de capa (ver más abajo) y de **gating en tests** deben resolverse aquí. El gating
debe usar `setEnabled(false)` en debug/tests + una no-op impl registrada para la suite,
y los crash handlers deben **no-reportar** en `kDebugMode`.

### F2 — Taxonomía centralizada y migración del call site existente · Complejidad: **baja**
Viable y necesaria como prerequisito. Verificado: `scan_soat_usecase.dart` tiene los 3
strings mágicos (`soat_scan_attempted`, `soat_scan_success`, `soat_scan_failed`) y ya
documenta el patrón de "bool → 0/1" porque GA4 descarta booleanos — ese aprendizaje debe
codificarse en la convención (params de tipo `Object`, sin bool). Migrar esos 3 eventos a
constantes es de bajo riesgo. **Ajuste:** F2 debe entregar también el **mapa de nombres de
ruta** (insumo de F3) y la regla de truncado de GA4 (nombre de evento ≤40 chars,
param key ≤40, value string ≤100) para que las 11 fases no la reaprendan.

### F3 — Recorrido de pantallas automático (screen_view) · Complejidad: **baja-media**
Viable. `app_router.dart` usa un `GoRouter` estático único (L63) **sin `observers`** →
punto de enganche único. Un `NavigatorObserver` que lea `route.settings.name` y emita
`logScreenView` cubre las 37 rutas. Riesgos reales:
- go_router 17 con `ShellRoute`/rutas anidadas: el `didPush`/`didReplace` puede no traer
  un `name` legible para sub-rutas o shells; el observer debe degradar a un nombre estable
  (path o name del `GoRoute`) y **no** emitir `screen_view` duplicados en `pushReplacement`.
- Rutas con parámetros (`:id`, `detail_by_id`) NO deben mandar el id como nombre de pantalla
  (PII/cardinalidad). Mapear a nombre canónico estable (p.ej. `event_detail`).

### F4 — Captura de errores y no-fatales de red · Complejidad: **media**
Viable, con **una corrección de punto de enganche**: el lugar correcto NO es
`executeService` (L139, solo desempaqueta `ApiResult`→`Either`), sino
**`handlerExceptionHttp`** (L15-70), donde ya están separados los `catch` por tipo
(`DioException`, `FirebaseAuthException`, `PlatformException`, `DomainException`, genérico).
Ahí se conoce la categoría real y el `stackTrace`. La política de severidad:
- Reportar como no-fatal: `DioException` 5xx y `connectionError`/timeouts (agregados, sin
  body), `PlatformException` inesperadas, y el `catch` genérico (estos son los bugs reales).
- NO reportar como crash: 400/401/403/404/409 (errores de negocio esperados) ni
  `FirebaseAuthException` de credenciales (wrong-password, etc.) → a lo sumo evento GA4.
- `DomainException` ya capturada y relanzada (L57-58) NO se reporta dos veces.
- **Evitar doble-conteo:** la verdad de errores de red vive SOLO en `handlerExceptionHttp`;
  los cubits NO reportan errores de red (ya vienen de aquí). Cubits solo reportan errores
  de lógica propia que no pasan por HTTP.

### F5 — Embudos de adquisición: auth y onboarding · Complejidad: **media**
Viable. Matiz de capa: `auth_cubit` vive en `authentication/application/` (no `presentation/`).
El `setUserId` hasheado debe dispararse al confirmar sesión (en `AuthCubit`, que es la
excepción singleton/router). **Decisión a fijar:** hash del uid de Firebase en cliente
(SHA-256) por defecto → mantiene todo client-side, sin tocar `GET /me`. user properties
no-PII (método de login, has_vehicle, etc.) sí, nunca email/nombre.

### F6 — Núcleo de eventos (crear/descubrir/registrar/aprobar) · Complejidad: **media-alta**
Viable; es la mayor superficie (cubits list/detail/form/delete/attendees + registration +
my_registrations). Solo instrumentación sobre taxonomía F2; sin cambios de contrato. El
riesgo es de **volumen de trabajo**, no técnico. Considerar partir si excede el tamaño de
las demás fases.

### F7 — Tracking en vivo y SOS · Complejidad: **media**
Viable. Verificado que SOS vive en `live_map_page.dart`/`participants_*` y el estado en
`live_tracking_cubit` (`sosAlertResult`). **Instrumentar hitos** (start/stop sesión,
SOS activado/confirmado/cerrado), NUNCA cada ping de ubicación ni coordenadas (PII +
volumen + costo GA4). El WebSocket de tracking NO se instrumenta por mensaje; solo
ciclo de vida (conectar/reconectar/fallo) como señal de salud, opcional.

### F8 — Garaje, mantenimientos y SOAT · Complejidad: **baja-media**
Viable. `vehicles` (7 usecases) y `maintenance` con cubits ya claros. Completa `soat`
(estado, captura manual) sobre el scan ya migrado en F2. Riesgo PII: NUNCA loguear placa,
VIN ni aseguradora identificable como param de alta cardinalidad.

### F9 — Perfil, descubrimiento y notificaciones · Complejidad: **baja-media**
Viable. Cierra cobertura. `notifications` (FCM token como señal de salud, abrir/marcar
leída). Riesgo PII: en `users`/descubrimiento NO loguear ids de otros riders como params.

### F10 — Privacidad, opt-out y verificación e2e · Complejidad: **media**
Viable con **un hallazgo**: NO existe una pantalla de Ajustes. `lib/features/profile/presentation/`
solo tiene `profile_page` y `edit_profile_page`. El opt-out (`AppSwitchTile`) debe alojarse
en una sección de privacidad dentro de profile/edit_profile, o crearse una `settings_page`
mínima (más alcance). Hay que decidirlo en el plan. El switch persiste vía
`UserStorageService` (SharedPreferences) y llama `setEnabled`. `docs/privacy-policy.html`
está en working tree modificada — revisar que mencione analítica/Crashlytics. Strings en
`app_es.arb`. Esta fase también ejecuta la **auditoría no-PII transversal** y el doc de QA.

---

## Contratos

### rideglory-api
**Sin cambios.** Toda la analítica y el crash reporting son client-side. Confirmado contra
el inventario de endpoints del scan. Única decisión que tocaría el backend (descartada por
defecto): que el id anónimo lo provea `GET /me` en vez de hashear el uid en cliente → se
mantiene **hashing client-side**, cero contrato nuevo.

### Datos / migraciones
Ninguna migración de BD. Persistencia local nueva: una clave de opt-out en
`UserStorageService`/SharedPreferences (F10).

### Code-gen
- Injectable: re-run `build_runner` tras añadir provider de `FirebaseCrashlytics` y la
  nueva impl de `CrashReporter`/no-op (`@Injectable(as: ...)`, `@Environment` para no-op
  en tests si se usa esa vía).
- l10n: `flutter gen-l10n` / `build_runner` tras añadir strings de opt-out (F10).
- No hay DTOs nuevos (no es Pattern B; la analítica no serializa modelos de API).

### Plataforma (nativo)
- Android: plugin Gradle Crashlytics en `settings.gradle.kts` + `app/build.gradle.kts`
  (junto a `google-services` ya presente); mapping upload para deobfuscación.
- iOS: subida de dSYM (upload-symbols / build phase / Fastlane).
- Ambos: verificación con crash de prueba en build real, no en debug.

### WebSocket
`TrackingWsClient` no requiere cambios de contrato. Solo instrumentación opcional de
ciclo de vida (F7), nunca por mensaje.

### Abstracción de capa (decisión arquitectónica de F1 — bloqueante)
Hoy `ScanSoatUseCase` (domain) inyecta `AnalyticsService` (core). Regla a fijar:
**`AnalyticsService` y `CrashReporter` son abstracciones puras en `core/` (sin Flutter ni
SDK), consumibles desde domain y presentation; el SDK Firebase solo aparece en la impl
`@Injectable(as: Interface)`.** Esto legitima el call site de soat (no es violación: domain
depende de una abstracción core pura, no de infraestructura) y da regla única para 11
features. NO mover la abstracción a cada feature.

---

## Riesgos

1. **Setup nativo de Crashlytics (F1).** Plugin Gradle Android y dSYM iOS son frágiles;
   mal setup = crashes sin símbolos. *Mitigación:* verificar con crash de prueba en build
   release/staging real antes de cerrar F1; documentar pasos en handoff DevOps.
2. **Punto de enganche equivocado en F4.** Si se engancha en `executeService` (que solo
   desempaqueta) en vez de `handlerExceptionHttp`, se pierde la categoría y el stackTrace.
   *Mitigación:* el plan fija explícitamente `handlerExceptionHttp` como sitio único.
3. **Ruido / doble-conteo de no-fatales.** *Mitigación:* política de severidad explícita
   (5xx/timeouts/genéricos sí; 4xx/credenciales no) + verdad única en la capa HTTP; cubits
   no re-reportan errores de red.
4. **PII y alta cardinalidad.** Ids de evento/registro/rider, placas, VIN, aseguradora,
   coordenadas, email/nombre como params. *Mitigación:* taxonomía revisada (F2), uid
   hasheado (F5), auditoría transversal (F10); regla "ids canónicos de pantalla, nunca el
   valor dinámico".
5. **Volumen del tracking en vivo (F7).** *Mitigación:* solo hitos (start/stop/SOS), nunca
   pings ni mensajes WS.
6. **Gating insuficiente en tests/CI.** Eventos enviados o flakiness. *Mitigación:* no-op
   impl + `setEnabled(false)` + handlers no-report en `kDebugMode`, verificado en F1 y
   reutilizado.
7. **Propagación de la anomalía de capa.** *Mitigación:* regla única de F1 verificada por
   el revisor de arquitectura antes de instrumentar features.
8. **screen_view en go_router 17 (F3).** Shells/sub-rutas sin `name` legible, duplicados en
   `pushReplacement`, ids dinámicos en el nombre. *Mitigación:* mapa de rutas canónico en
   F2/F3, dedupe en el observer.
9. **Sin pantalla de Ajustes para opt-out (F10).** *Mitigación:* decidir alojar el switch
   en profile/edit_profile o crear `settings_page` mínima; persistir en SharedPreferences.
10. **Versión de `firebase_crashlytics` vs `firebase_core 4.x`.** *Mitigación:* resolver vía
    `pub` (no fijar a ciegas) y correr `flutter pub get` + `build_runner` en F1.

---

## Ajustes

1. **F4: enganchar en `handlerExceptionHttp`, no en `executeService`.** Es ahí donde existe
   la categorización por tipo y el `stackTrace`; `executeService` solo mapea `ApiResult`→`Either`.
2. **F2 entrega también el mapa canónico de nombres de ruta** (insumo de F3) y la convención
   de límites GA4 (nombres ≤40, value string ≤100, sin bool → 0/1, params `Object`).
3. **Fijar la regla de capa en F1 como decisión explícita** ("abstracción core pura,
   consumible por domain y presentation; SDK solo en impl") y declarar que el call site de
   soat YA cumple, para no refactorizarlo innecesariamente.
4. **F1: `runZonedGuarded` debe envolver `configureDependencies()` + `runApp()`** y registrar
   `FlutterError.onError` + `PlatformDispatcher.onError`; los handlers no reportan en
   `kDebugMode`.
5. **F5: `setUserId` con uid hasheado (SHA-256) en `AuthCubit`** (excepción singleton/router),
   por defecto client-side; cero cambios en `GET /me`.
6. **F10: resolver el alojamiento del opt-out** — no hay `settings_page`; ubicarlo en
   profile/edit_profile o crear una mínima. Persistir en `UserStorageService`.
7. **F7: instrumentar solo hitos del flujo (start/stop/SOS)**, nunca pings de ubicación ni
   mensajes WebSocket; coordenadas fuera de params.
8. **Considerar partir F6** (mayor superficie: events + registration) si excede el tamaño de
   las otras fases, para mantener fases comparables y revisables.
9. **El orden propuesto (1→10) es correcto:** fundaciones → taxonomía → dos palancas baratas
   (screen_view, no-fatales) → embudos por dominio → privacidad/verificación. Mantener.
