# 01 — System Scan: Analíticas + Crashlytics (cobertura total)

- Slug: `analytics-crashlytics-cobertura-total`
- Fecha (UTC): 2026-06-04T00:48:48Z
- Lente: `docs/plans/analytics-crashlytics-cobertura-total/00-intake.md` (gap-analysis)

## Inventario Flutter

11 features bajo `lib/features/`. Capas por feature (D=domain, Da=data, P=presentation):

| Feature | Capas | Notas relevantes para instrumentación |
|---|---|---|
| `authentication` | P (+`application/`, `constants/`) | Sin domain/data clásicos; estado vía `auth_cubit` en `application/`. Flujos: login, signup, forgot-password, social (Google/Apple). Login/signup tienen `login/` y `signup/` con sub-`presentation/`. |
| `home` | D, Da, P | Dashboard; `home_cubit`, `home_page`. |
| `vehicles` | D, Da, P | 7 usecases (add/update/delete/archive/unarchive/get/setMain); cubits: `vehicle_cubit` (app-wide), `vehicle_form_cubit`, `vehicle_delete_cubit`, `vehicle_maintenances_cubit`. Pages: garage/detail/form. |
| `events` | D, Da, P | Mayor superficie: cubits list/detail/form/delete/attendees + `live_tracking_cubit` (+factory). Pages: list/detail/detail_by_id/drafts/form/attendees + tracking (`live_map_page`, participants). |
| `event_registration` | D, Da, P | `registration_form_cubit`, `my_registrations_cubit`. Pages: registration/my_registrations/registration_detail. Workflow aprobación. |
| `maintenance` | D, Da, P | `maintenance_form_cubit`, `maintenances_cubit`, `maintenance_delete_cubit`. Pages list/detail/form. |
| `notifications` | D, Da, P | 4 usecases (get/markRead/markAllRead/registerFcmToken); `notifications_cubit`. |
| `profile` | D, P | `profile_cubit`. Pages: profile/edit_profile. |
| `soat` | D, Da, P | 5 usecases incl. `scan_soat_usecase` (ÚNICO call site de `AnalyticsService` hoy). Cubits: `soat_cubit`, `soat_upload_cubit`. Pages: manual_capture/status. |
| `users` | D, Da, P | `rider_profile_cubit`, `rider_profile_page` (descubrimiento). |
| `splash` | D, P | `splash_cubit`. |

- Pages totales detectadas: ~24 `*_page.dart`/`*_view.dart` (router con **37 `GoRoute`**).
- **Semilla de analítica** (`lib/core/services/analytics/`): solo 2 archivos.
  - `analytics_service.dart`: interfaz mínima `Future<void> logEvent(String, [Map<String,Object>?])`. Doc-comment ya promete "anonymous, no PII, no recognized text/images".
  - `firebase_analytics_service.dart`: `@Injectable(as: AnalyticsService)` envuelve `FirebaseAnalytics.logEvent`. Sin `screen_view`, sin `setUserId`, sin `setUserProperty`, sin enable/disable.
- **Bootstrap** (`lib/main.dart`): `Firebase.initializeApp` (L39) → `configureDependencies()` (L51) → `runApp` (L53). **Sin** `runZonedGuarded`, **sin** `FlutterError.onError`, **sin** handler Crashlytics.
- **Router** (`lib/shared/router/app_router.dart`): `GoRouter` estático único, `refreshListenable` a `AuthCubit`, **sin `observers`** → punto único de enganche para `screen_view` (NavigatorObserver).
- **Errores** (`lib/core/http/rest_client_functions.dart`): `executeService<Model>` mapea `DioException`/`FirebaseAuthException`/`PlatformException`/`DomainException`/`catch` genérico → `Either<DomainException, Model>`. Punto natural para no-fatales con categorización por tipo (Dio vs Firebase vs Platform vs genérico/inesperado).
- `auth_cubit` vive en `authentication/application/` (no `presentation/`) — matiz para reglas de capa.

## Dependencias (pubspec.yaml)

- **Ya presentes:** `firebase_analytics: ^12.0.0`, `firebase_core: ^4.2.1`, `firebase_auth: ^6.1.2`, `firebase_messaging: ^16.2.0`, `firebase_storage: ^13.1.0`, `firebase_remote_config: ^6.4.0`.
- **FALTA:** `firebase_crashlytics` → añadir (alinear major con `firebase_core 4.x`).
- Resto stack: `flutter_bloc ^9.1.1`/`bloc ^9.1.0`, `injectable ^2.7.1`, `go_router ^17.0.0`, `dio ^5.9.2`, `retrofit ^4.9.2`, `web_socket_channel ^3.0.3`, `mapbox_maps_flutter ^2.2.0`, `geolocator ^14.0.2`, `envied ^1.3.3`. Dev: `bloc_test ^10.0.0` (útil para tests de call sites con mock).
- `AppEnv` (`lib/core/config/app_env.dart`) es `envied`-backed (solo claves Firebase/Maps). No hay flag de gating de analítica → habría que añadir uno (o usar `kDebugMode`/`--dart-define`).

## Superficie rideglory-api

Monorepo NestJS: **api-gateway** (BFF) + microservicios (`events-ms`, `users-ms`, `vehicles-ms`, `maintenances-ms`, `notifications-ms`). Endpoints del gateway (cliente Flutter consume estos), agrupados:

- **Users**: `POST /sign-up`, `GET /me`, `GET /:id`, `PATCH /:id`.
- **Vehicles**: `GET`, `POST`, `GET my`, `POST my`, `PUT my/:id/main`, `GET/PATCH/DELETE(hard) :id`, `POST/GET/DELETE :vehicleId/soat`.
- **Events**: `POST generate-cover`, `POST`, `GET`, `GET my`, `GET upcoming`, `PATCH :id/publish`, `GET/PATCH/DELETE :id`.
- **Registrations**: `POST events/:eventId/registrations`, `PATCH/cancel/approve/reject/ready-for-edit registrations/:id`, `GET events/:eventId/registrations(+/me)`, `GET registrations/me`.
- **Tracking** (HTTP): `POST :eventId/tracking/start|end`, `POST :eventId/tracking/session/start|stop`, `GET :eventId/tracking/snapshot`, `GET :eventId/route`. + **WebSocketGateway** (`tracking-ms`/gateway) para broadcast en vivo.
- **Notifications**: `POST notifications/fcm-token`, `GET notifications`, `PATCH notifications/:id/read`, `PATCH notifications/read-all`.
- **Maintenances**: `GET/POST vehicle/:vehicleId`, `PATCH/DELETE vehicle/:vehicleId/:id`.
- **Home**: `GET`. **Places**: `GET autocomplete|details|geocode`. **Health**: `GET`.

**Implicación:** la analítica es client-side; el backend NO necesita cambios para esta planeación, salvo (a confirmar, pregunta abierta #3) si se decide que el id anónimo de usuario lo provea el server en `GET /me` en lugar de hashear el uid en cliente.

## Gap analysis (vs objetivo de cobertura total)

| Capacidad | Estado | Qué falta |
|---|---|---|
| Dep `firebase_analytics` | implemented | — (ya en pubspec) |
| Dep `firebase_crashlytics` | **not started** | Añadir paquete + setup nativo (Android `google-services` ya, falta plugin gradle/Crashlytics; iOS dSYM upload). |
| `AnalyticsService` interfaz | **partial** | Solo `logEvent`. Falta `logScreenView`, `setUserId(hashed)`, `setUserProperty`, `setEnabled`/gating, `resetAnalyticsData`. |
| `CrashReporter` (abstracción + impl) | **not started** | Crear abstracción core + impl Crashlytics (`recordError` fatal/no-fatal, `log`, `setCustomKey`, `setUserId`). |
| Bootstrap crash handlers | **not started** | `runZonedGuarded`, `FlutterError.onError`, `PlatformDispatcher.onError`, gating en debug/tests, init en `main.dart`. |
| `screen_view` automático | **not started** | `NavigatorObserver` registrado en `GoRouter.observers`; mapear nombres de ruta legibles (37 rutas). |
| Captura no-fatales en HTTP | **not started** | Enganche en `executeService`; política de severidad (qué se reporta vs ruido). |
| Captura errores `ResultState.error`/`DomainException` | **not started** | Estrategia: solo en `executeService` o también en cubits; evitar doble-conteo. |
| Taxonomía centralizada (constantes) | **not started** | No existen constantes; los 3 eventos de soat son strings mágicos en el usecase. Falta doc + naming convention + clases de constantes. |
| Instrumentación por feature/embudo | **partial (1/11)** | Solo `soat` tiene 3 eventos (attempt/success/fail). Faltan auth, events(crear/detalle), registration(+aprobación), tracking/SOS, vehicles, maintenance, notifications, profile, users, home, splash. |
| Gating debug/tests | **not started** | Sin flag; no hay no-op impl para tests. |
| Privacidad/consentimiento | **not started** | Sin hashing de uid, sin opt-out, sin UI/strings. `docs/privacy-policy.html` ya publicada (revisar si menciona analítica). |
| Verificación (DebugView/Crashlytics) | **not started** | Sin doc de QA de analítica. |

## Patrones (a respetar en el plan)

- **Clean Architecture** estricta: abstracción en `core`, impl Firebase como `@Injectable(as: Interface)`; presentación/cubits consumen abstracción, nunca SDK. **Anomalía a resolver:** hoy `AnalyticsService` se inyecta en un usecase de **domain** (`scan_soat_usecase`) — pregunta abierta #1 (¿la abstracción es válida en domain, o solo presentación/cubits?).
- **DI**: GetIt+Injectable; Firebase providers en `firebase_module.dart` (ahí ya se da `FirebaseAnalytics` como `@lazySingleton`; añadir `FirebaseCrashlytics` igual). Cubits son `@injectable` + BlocProvider (no singleton/getIt), excepto `AuthCubit`.
- **Estado**: `ResultState<T>` (Initial/Loading/Data/Empty/Error). El estado `Error` lleva `DomainException` → fuente canónica de eventos de error.
- **Errores HTTP**: centralizados en `executeService` (un solo sitio para no-fatales de red).
- **Strings UI** en `lib/l10n/app_es.arb` con `context.l10n.*` (si se añade consentimiento/opt-out).
- **Widgets**: un widget por archivo, sin métodos que retornan widgets, reusar `lib/shared/widgets/form/` (`AppButton`, `AppSwitch`/`AppSwitchTile` para opt-out). Relevante si se hace wrapper de auto-logging de CTAs (pregunta abierta #2).
- **Design**: `docs/handoffs/design.md` está en **Stand-down** (iteración 6, refactor sin frames). `docs/design/html-mockups/` existe pero no es de esta iniciativa. Solo se necesitaría diseño si entra UI de consentimiento/opt-out.

## Implicaciones para el plan

1. **F1 fundaciones es desbloqueante y autocontenida:** añadir `firebase_crashlytics` (+setup nativo Android/iOS), ampliar `AnalyticsService`, crear `CrashReporter`, proveer DI, y cablear `main.dart` (`runZonedGuarded`+`FlutterError.onError`+`PlatformDispatcher.onError`) con gating debug/tests. Sin esto nada más funciona.
2. **Dos puntos de enganche únicos y baratos** dan cobertura amplia con poco código: `GoRouter.observers` (screen_view de las 37 rutas) y `executeService` (no-fatales de red categorizados). Conviene que sean fases tempranas separadas.
3. **Taxonomía centralizada antes de instrumentar features:** definir clases de constantes + naming + doc, y migrar los 3 eventos de soat existentes a ella (resuelve pregunta #7). Evita strings mágicos y reduce reprocesos al instrumentar 11 features.
4. **Resolver la ubicación de capa de `AnalyticsService`** (pregunta #1) es prerequisito de arquitectura: hoy un usecase de domain depende de la abstracción; el plan debe fijar la regla (probable: domain puede depender de la abstracción core pura, o moverla a `core/domain`) para no propagar la violación a 11 features.
5. **Backend fuera de alcance** salvo la decisión de id anónimo server-provided (pregunta #3); por defecto, hashing del uid en cliente mantiene esto 100% client-side. Privacidad (no-PII, uid hasheado, opt-out + revisión de `privacy-policy.html`) debe ser su propia fase con posible toque mínimo de UI/`app_es.arb`.
