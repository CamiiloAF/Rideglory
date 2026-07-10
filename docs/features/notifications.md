# Documentación del Feature: Notifications

> Última actualización: 2026-07-04  
> Alcance: `lib/features/notifications/` + `lib/core/services/fcm_service.dart`

---

## Tabla de contenido

1. [Visión general](#1-visión-general)
2. [Modelo de dominio](#2-modelo-de-dominio)
3. [Arquitectura por capas](#3-arquitectura-por-capas)
   - 3.1 [Domain](#31-domain)
   - 3.2 [Data](#32-data)
   - 3.3 [Presentation](#33-presentation)
4. [Cubit y estados](#4-cubit-y-estados)
5. [Tipos de notificación](#5-tipos-de-notificación)
6. [FCM y deep linking](#6-fcm-y-deep-linking)
7. [Badge de no-leídas](#7-badge-de-no-leídas)
8. [Rutas de navegación](#8-rutas-de-navegación)
9. [API endpoints](#9-api-endpoints)
10. [Conexiones con otros features](#10-conexiones-con-otros-features)
11. [Analytics](#11-analytics)
12. [Patrones y trampas conocidas](#12-patrones-y-trampas-conocidas)
13. [Archivos clave de referencia rápida](#13-archivos-clave-de-referencia-rápida)

---

## 1. Visión general

El feature **Notifications** gestiona el centro de notificaciones de la app:

1. **Lista paginada** (cursor-based) de notificaciones del backend.
2. **Optimistic updates** al marcar como leída (UI primero, request después sin rollback).
3. **Badge de no-leídas** que aparece en la campana del `HomeHeader`.
4. **Deep linking** desde push notification: `rideglory://events/detail-by-id?id=xxx` → GoRouter.
5. **Registro automático de token FCM** post-autenticación (via `AuthCubit` → `FcmService.initialize()`).

El servicio FCM (`lib/core/services/fcm_service.dart`) **no vive** dentro de `features/notifications/` pero es parte esencial del feature: maneja permisos, canales Android, foreground notifications, deep links externos (app_links) y registro de token.

---

## 2. Modelo de dominio

### `NotificationModel`
> `lib/features/notifications/domain/model/notification_model.dart`

```
NotificationModel
  id: String                       (requerido)
  type: NotificationType           (requerido)
  title: String                    (requerido)
  body: String                     (requerido)
  createdAt: DateTime              (requerido)
  isRead: bool                     (default false)
  payload: Map<String, dynamic>?   — datos extras de la push
  route: String?                   — URI deep link "rideglory://..."
```

`copyWith()` permite actualizar `isRead`, `title`, `body` (usado en optimistic updates).

### `NotificationType` (enum)
```dart
enum NotificationType {
  soat30d,
  soat7d,
  soatDayOf,
  newRegistration,
  registrationApproved,
  registrationRejected,
  general,
}
```

### `NotificationsPage` (wrapper de paginación)
```
NotificationsPage
  data: List<NotificationModel>
  nextCursor: String?              — null = fin de paginación
```

---

## 3. Arquitectura por capas

### 3.1 Domain
```
lib/features/notifications/domain/
├── model/
│   └── notification_model.dart       (NotificationType + NotificationModel)
├── repository/
│   └── notifications_repository.dart (interface + NotificationsPage)
└── usecases/
    ├── get_notifications_usecase.dart
    ├── mark_notification_read_usecase.dart
    ├── mark_all_notifications_read_usecase.dart
    └── register_fcm_token_usecase.dart
```

**`NotificationsRepository`** (interface):
```dart
Future<Either<DomainException, NotificationsPage>> getNotifications({
  String? cursor,
  int limit = 20,
});
Future<Either<DomainException, void>> markRead(String notificationId);
Future<Either<DomainException, void>> markAllRead();
Future<Either<DomainException, void>> registerFcmToken(String token);
```

**Use cases (todos `@injectable`)**:
| Use case | Signature |
|---|---|
| `GetNotificationsUseCase` | `call({String? cursor, int limit = 20}) → Future<Either<DomainException, NotificationsPage>>` |
| `MarkNotificationReadUseCase` | `call(String notificationId) → Future<Either<DomainException, void>>` |
| `MarkAllNotificationsReadUseCase` | `call() → Future<Either<DomainException, void>>` |
| `RegisterFcmTokenUseCase` | `call(String token) → Future<Either<DomainException, void>>` |

---

### 3.2 Data
```
lib/features/notifications/data/
├── dto/
│   ├── notification_dto.dart            (NotificationDto + NotificationPageDto)
│   └── notification_dto.g.dart
├── repository/
│   └── notifications_repository_impl.dart   (@Injectable(as: NotificationsRepository))
└── service/
    ├── notifications_service.dart           (@singleton @RestApi)
    └── notifications_service.g.dart
```

**`NotificationDto`** (`@JsonSerializable(converters: apiJsonDateTimeConverters)`):

```
id: String
userId: String
type: String                  — 'SOAT_30D', 'NEW_REGISTRATION', etc.
payload: Map<String, dynamic> — datos crudos
isRead: bool
createdAt: DateTime?
```

`toModel()` mapea **manualmente** el string del tipo al enum `NotificationType` y **construye title/body en español** (hardcoded):

| `type` string | NotificationType | title (es) | body (es) |
|---|---|---|---|
| `SOAT_30D` | `soat30d` | "Tu SOAT vence en 30 días" | "El SOAT de tu moto vence en 30 días" |
| `SOAT_7D` | `soat7d` | "Tu SOAT vence en 7 días" | "El SOAT de tu moto vence en 7 días" |
| `SOAT_DAY_OF` | `soatDayOf` | "Tu SOAT vence hoy" | "El SOAT de tu moto vence hoy" |
| `NEW_REGISTRATION` | `newRegistration` | "Nueva inscripción" | "Un rider se inscribió a tu evento" |
| `REGISTRATION_APPROVED` | `registrationApproved` | "Inscripción aprobada" | "Tu inscripción fue aprobada" |
| `REGISTRATION_REJECTED` | `registrationRejected` | "Inscripción rechazada" | "Tu inscripción fue rechazada" |
| `MAINTENANCE_DATE_REMINDER` | `general` (fallback) | "Recordatorio de mantenimiento" | "Tu mantenimiento está programado en 30 días" |
| `EVENT_REMINDER` | `general` (fallback) | "Recordatorio de rodada" | "Tu rodada comienza en 24 horas" |
| `SOS_ALERT` | `general` (fallback) | "Alerta SOS" | "Un rider ha enviado una alerta SOS" |
| `TRACKING_ENDED` | `general` (fallback) | "Rodada finalizada" | "La rodada ha finalizado" |
| _otro_ | `general` | "Notificación" | "" |

`route` se extrae del payload: `payload['route'] as String?`.

**`NotificationPageDto`**:
```
data: List<NotificationDto>
nextCursor: String?
```

**`NotificationsService` (Retrofit)**:
```dart
@GET(ApiRoutes.notifications)
Future<NotificationPageDto> getNotifications({
  @Query('cursor') String? cursor,
  @Query('limit') int limit = 20,
});

@PATCH('/notifications/{notificationId}/read')
Future<void> markRead(@Path('notificationId') String notificationId);

@PATCH(ApiRoutes.notificationsReadAll)        // '/notifications/read-all'
Future<void> markAllRead();

@POST(ApiRoutes.notificationsFcmToken)        // '/notifications/fcm-token'
Future<void> registerFcmToken(@Body() Map<String, dynamic> body);   // body: {fcmToken: '...'}
```

**`NotificationsRepositoryImpl`** (`@Injectable(as: NotificationsRepository)`):
- Usa `executeService()` para todas las llamadas.
- `getNotifications()` mapea `NotificationDto` → `NotificationModel`.
- `registerFcmToken(token)` envía `{'fcmToken': token}` al body.

---

### 3.3 Presentation
```
lib/features/notifications/presentation/
├── cubit/
│   ├── notifications_cubit.dart
│   ├── notifications_state.dart       (freezed)
│   └── notifications_state.freezed.dart
├── notifications_page.dart
├── notifications_view.dart
└── widgets/
    ├── notification_bell_button.dart    (campana usada en HomeHeader)
    ├── notification_item.dart           (tarjeta de notificación con icono por tipo)
    ├── notifications_data_view.dart     (lista con secciones "Sin leer" / "Leídas" + load more)
    ├── notifications_empty_state.dart
    └── notifications_error_state.dart
```

---

## 4. Cubit y estados

| Cubit | Archivo | DI | Estado |
|---|---|---|---|
| `NotificationsCubit` | `presentation/cubit/notifications_cubit.dart` | `@lazySingleton` | `NotificationsState` (freezed) |

Es `@lazySingleton` y se inyecta globalmente en `main.dart` (root `MultiBlocProvider`). Por eso el badge de no-leídas funciona desde cualquier pantalla.

### `NotificationsState` (freezed)
```dart
@freezed
class NotificationsState {
  const factory NotificationsState({
    @Default(ResultState<List<NotificationModel>>.initial())
    ResultState<List<NotificationModel>> listResult,

    @Default(null) String? nextCursor,
    @Default(0) int unreadCount,
    @Default(false) bool isLoadingMore,    // secondary loading flag for pagination
  }) = _NotificationsState;
}
```

**Por qué `isLoadingMore` no es un `ResultState`:** `listResult` debe permanecer en `Data` mientras se cargan más páginas. Un segundo `ResultState` produciría rebuild ambiguo. La excepción está documentada en el código.

### Métodos públicos

| Método | Comportamiento |
|---|---|
| `load()` | `listResult = loading`. Llama `getNotifications()`. Si la lista llega vacía → `empty + unreadCount=0`. Si tiene datos → `data + nextCursor + unreadCount` |
| `loadMore()` | Si `nextCursor != null && !isLoadingMore` → `getNotifications(cursor)`, concatena lista, recalcula `unreadCount`, actualiza `nextCursor` |
| `markRead(String id)` | **Optimistic**: marca `isRead: true` localmente, decrementa `unreadCount`, emite. Luego llama `markRead()` use case en background (sin manejo de error/rollback) |
| `markAllRead()` | **Optimistic**: marca todas como leídas, `unreadCount = 0`, emite. Luego llama `markAllRead()` use case |

### `NotificationsPage` / `NotificationsView`

`NotificationsPage` provee `getIt<NotificationsCubit>()..load()` y renderiza `NotificationsView`. La view es un `Scaffold` con:

- **AppBar**: título "Centro de notificaciones" + acción "Marcar todo como leído" visible solo si `unreadCount > 0`.
- **Body**: `BlocBuilder<NotificationsCubit, NotificationsState>` que renderiza:
  - `loading`/`initial` → `AppLoadingIndicator`
  - `error` → `NotificationsErrorState` (con retry)
  - `empty` → `NotificationsEmptyState`
  - `data` → `NotificationsDataView`

### `NotificationsDataView`

- `RefreshIndicator` con `onRefresh: load()`.
- `CustomScrollView` con dos secciones:
  - **"SIN LEER"** (badge con contador en píldora primary) seguida de `SliverList.separated` de `NotificationItem`s con `isRead = false`.
  - **"LEÍDAS"** seguida de items leídos.
- Al final, botón "Cargar más" si `nextCursor != null` (o `CircularProgressIndicator` si `isLoadingMore`).
- Tap en notificación no-leída → `markRead(id)` + (si `route != null`) → `AppRouter.pushDeepLink(route)`.

### `NotificationItem`

Tarjeta con:
- Icono coloreado por tipo (ver tabla §5).
- Título + body + timestamp relativo ("Hace 2h", "Hace 1d", "Ahora", etc.).
- Punto azul si `isRead == false`.

---

## 5. Tipos de notificación

7 tipos en el enum `NotificationType` (ver §2). Mapeo a iconos/colores en `NotificationItem`:

| Tipo (enum) | Color icon | Color background | Icon |
|---|---|---|---|
| `registrationApproved` | `success` | `successSubtle` | `check_circle_outline_rounded` |
| `registrationRejected` | `error` | `errorSubtle` | `cancel_outlined` |
| `newRegistration` | `primary` | `primarySubtle` | `person_add_alt_1_outlined` |
| `soat30d` / `soat7d` / `soatDayOf` | `warning` | `warningSubtle` | `description_outlined` |
| `general` | `textOnDarkSecondary` | `darkTertiary` | `notifications_outlined` |

> Hay 4 tipos API adicionales (`MAINTENANCE_DATE_REMINDER`, `EVENT_REMINDER`, `SOS_ALERT`, `TRACKING_ENDED`) que el backend puede enviar pero que el cliente mapea a `NotificationType.general` (no tienen enum dedicado). Aún así, `NotificationDto._titleFromType()` les construye títulos en español específicos. Si se quiere icono particular, agregar al enum.

---

## 6. FCM y deep linking

### `FcmService` (`lib/core/services/fcm_service.dart`, `@singleton`)

**`initialize()`** se llama post-autenticación desde `AuthCubit`. Realiza:

1. **Permisos**: `messaging.requestPermission(alert, badge, sound)`. Si denegado → retorna sin más setup.
2. **Canal Android**: crea `AndroidNotificationChannel('rideglory_high_importance', importance: high)`.
3. **`FlutterLocalNotificationsPlugin.initialize()`** con `_onLocalNotificationTap` callback.
4. **iOS foreground**: `setForegroundNotificationPresentationOptions(alert, badge, sound)`.
5. **Listeners FCM**:
   - `FirebaseMessaging.onMessage` → `_showForegroundNotification` (solo Android; iOS lo hace nativo).
   - `FirebaseMessaging.onMessageOpenedApp` → `_onMessageTapped` (background tap).
   - `messaging.getInitialMessage()` → `_onMessageTapped` con delay 300ms (terminated state).
6. **`app_links`**: `appLinks.getInitialLink()` + `uriLinkStream.listen(_navigateFromUri)` (deep links externos `rideglory://...`).
7. **Token**: `messaging.getToken()` → `_registerToken(token)`. `messaging.onTokenRefresh.listen(_registerToken)`.

**`_registerToken(token)`** llama `RegisterFcmTokenUseCase(token)` → `POST /notifications/fcm-token` con `{'fcmToken': token}`.

**Background handler** (top-level, `@pragma('vm:entry-point')`):
```dart
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) log('FCM background message: ${message.messageId}');
}
```
Registrado en `main.dart` (`FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler)`).

### Deep linking

Flujo unificado para todos los caminos (foreground tap / background tap / terminated tap / app_links externo):

```
RemoteMessage.data['route'] = "rideglory://events/detail-by-id?id=abc"
   o
AppLinks URI            = rideglory://events/detail-by-id?id=abc
   │
   ▼
FcmService._navigateFromUri(uri)
   ├─ scheme != 'rideglory' → ignore
   └─ AppRouter.pushDeepLink(uri.toString())
        ├─ path = '/events/detail-by-id'
        ├─ if uri.hasQuery → path + '?' + uri.query
        └─ appRouter.push('/events/detail-by-id?id=abc')
```

**`AppRouter.pushDeepLink`** vive en `lib/shared/router/app_router.dart`. Convierte `rideglory://<host>/<path>?<query>` a la ruta interna `/<host>/<path>?<query>` y hace `push()` con el GoRouter.

**Cuando el usuario tapea una notificación del centro** (notifications_data_view) y tiene `route != null`, llama `AppRouter.pushDeepLink(notification.route!)` directamente.

---

## 7. Badge de no-leídas

Cálculo en `NotificationsCubit`:
```dart
final unread = notifications.where((n) => !n.isRead).length;
emit(state.copyWith(unreadCount: unread));
```
Recalculado en `load()`, `loadMore()`, `markRead()`, `markAllRead()`.

### Dónde se muestra

| Widget | Ubicación | Visualización |
|---|---|---|
| `NotificationBellButton` | `HomeHeader` (arriba derecha del home) | Badge circular rojo con número (máx "99+"); icon outlined si 0, filled si > 0 |
| `NotificationsView` AppBar action | Pantalla `/notifications` | Botón "Marcar todo como leído" visible solo si `> 0` |
| Sección "SIN LEER" header | `NotificationsDataView` | Píldora primary con contador |
| `NotificationItem` | Cada tarjeta | Punto azul si `isRead == false` |

> `MainShell.showNotificationBadge` se pasa como prop pero **no se usa** actualmente. El badge real vive solo en `NotificationBellButton`. Si se quiere badge en el bottom nav, hay que conectarlo.

---

## 8. Rutas de navegación

| Ruta | Constante | Página |
|---|---|---|
| `/notifications` | `AppRoutes.notifications` | `NotificationsPage` |

Navegación:
- Campana en home → `context.pushNamed(AppRoutes.notifications)`.
- Push notification con `route` → `AppRouter.pushDeepLink(route)` (no necesariamente a `/notifications`; puede ser cualquier ruta).

---

## 9. API endpoints

| Método | Endpoint | Body / Query / Response |
|---|---|---|
| `GET` | `/notifications` | Query `cursor?`, `limit=20` → `NotificationPageDto` |
| `PATCH` | `/notifications/{id}/read` | — → `void` |
| `PATCH` | `/notifications/read-all` | — → `void` |
| `POST` | `/notifications/fcm-token` | Body `{"fcmToken": "..."}` → `void` |

Constantes en `lib/core/http/api_routes.dart`:
- `notifications = '/notifications'`
- `notificationsFcmToken = '/notifications/fcm-token'`
- `notificationsReadAll = '/notifications/read-all'`
- `notificationRead(id) = '/notifications/{id}/read'`

---

## 10. Conexiones con otros features

| Feature | Conexión |
|---|---|
| `authentication` | `AuthCubit.{signIn*, signUp*, checkAuthState}` llama `FcmService.initialize().ignore()` post-autenticación |
| `home` | `HomeHeader` monta `NotificationBellButton` (lee `NotificationsCubit.state.unreadCount`) |
| `events` | Deep links a `eventDetailById` se reciben vía push notifications de `newRegistration`, `eventReminder`, etc. |
| `event_registration` | Tipos `newRegistration`, `registrationApproved`, `registrationRejected` |
| `soat` | Tipos `soat30d`, `soat7d`, `soatDayOf` (vienen programados desde backend) |
| `main.dart` | Registra `firebaseMessagingBackgroundHandler` y monta `NotificationsCubit` en root `MultiBlocProvider` |

---

## 11. Analytics

Instrumentación añadida en fase 9 (`AnalyticsService`, aditiva, sin tocar lógica de negocio):

| Evento | Disparado en | Parámetros |
|---|---|---|
| `notification_marked_read` | `NotificationsCubit.markRead()` (optimistic, antes de llamar al use case) | `notification_type` (nombre del enum `NotificationType`) |
| `notifications_all_read` | `NotificationsCubit.markAllRead()` (optimistic, antes de llamar al use case) | — |
| `fcm_token_registered` | `RegisterFcmTokenUseCase.call()`, solo si `registerFcmToken()` resulta `Right` | — (el token nunca se loguea, por PII/alta cardinalidad) |

Todas las llamadas usan `.ignore()` (fire-and-forget, no bloquean el flujo principal). `NotificationsCubit` y `RegisterFcmTokenUseCase` reciben `AnalyticsService` inyectado por constructor.

Tests: `test/features/notifications/presentation/cubit/notifications_analytics_test.dart` verifica estos 3 eventos con un mock de `AnalyticsService`.

---

## 12. Patrones y trampas conocidas

### Optimistic update sin rollback
`markRead()` y `markAllRead()` actualizan localmente primero y llaman al backend después **sin manejo de error**. Si la llamada falla, la UI ya muestra "leído" y queda desincronizada hasta el próximo `load()`. Aceptable hoy; si crece, agregar rollback o retry.

### `isLoadingMore` no es `ResultState`
Es un booleano secundario para no perder el `Data` de `listResult` mientras se carga más página. La excepción está documentada en `notifications_state.dart` comentarios.

### Title/body en cliente
`NotificationDto._titleFromType()` y `_bodyFromType()` hardcodean los textos en español según el `type` string. Si el backend envía otro idioma o quieres i18n real, hay que mover esto a `app_es.arb` y mapear por `type`.

### 4 tipos del backend no están en el enum
`MAINTENANCE_DATE_REMINDER`, `EVENT_REMINDER`, `SOS_ALERT`, `TRACKING_ENDED` se mapean a `NotificationType.general`. Pierden el icono/color específico aunque sí mantengan título/body propio. Si interesa diferenciarlos visualmente, agregar al enum y a `NotificationItem` switch.

### `MainShell.showNotificationBadge` no se usa
Se pasa `true` desde `app_router.dart` pero el bottom nav no lo lee. Si se quiere badge en el tab Inicio, hay que conectar con `NotificationsCubit.state.unreadCount` desde `HomeBottomNavigationBar`.

### Sin persistencia local
No hay cache. Cada `load()` produce HTTP. Offline = error. Si se requiere offline support, usar `Hive` o `Isar`.

### Deep link silencioso si scheme no es `rideglory`
`_navigateFromUri` retorna sin loguear si `scheme != 'rideglory'`. Útil para evitar consumir URIs ajenos, pero si el backend envía un `route` con otro scheme, no se navega ni se reporta error.

### Cast inseguro de payload
`payload['route'] as String?` falla silenciosamente si el shape es inesperado. Considerar `pigeon`-like schema o validación con `payload is Map<String, dynamic> ? ...`.

### Token refresh es fire-and-forget
`onTokenRefresh.listen(_registerToken)` no maneja errores. Si backend rechaza, no se reintenta. Considerar retry con backoff si el caso es crítico.

### Acceso al router global
`AppRouter.pushDeepLink` accede a `appRouter` static. Si el router no está inicializado (apertura antes de runApp), crash. Por eso `getInitialMessage` y `getInitialLink` tienen `Future.delayed(300ms)`.

### Hora relativa en cliente
"Hace 2h" se calcula en `NotificationItem._timeAgo()`. No se localiza (`Intl.plural`) ni se ajusta a zona horaria del backend. Considerar `intl` para casos formales.

### Sin opt-in per-type
El usuario no puede silenciar tipos específicos (p. ej. solo SOAT). Solo permisos globales de Firebase. Si se requiere granularidad, agregar pantalla de preferencias + backend.

### `NotificationsCubit` es `@lazySingleton`
Vive durante toda la app. `load()` se dispara cada vez que se entra a `NotificationsPage`. Si se quiere refresco automático en otras pantallas (badge actualizado en home), hay que llamar `load()` desde otro lugar o agregar polling.

---

## 13. Archivos clave de referencia rápida

| Qué buscar | Archivo |
|---|---|
| Modelo + enum tipos | `lib/features/notifications/domain/model/notification_model.dart` |
| Repository interface | `lib/features/notifications/domain/repository/notifications_repository.dart` |
| Use cases | `lib/features/notifications/domain/usecases/` |
| DTO + mapeo de tipos a títulos | `lib/features/notifications/data/dto/notification_dto.dart` |
| Service Retrofit | `lib/features/notifications/data/service/notifications_service.dart` |
| Repository impl | `lib/features/notifications/data/repository/notifications_repository_impl.dart` |
| Cubit global + paginación | `lib/features/notifications/presentation/cubit/notifications_cubit.dart` |
| Estado freezed | `lib/features/notifications/presentation/cubit/notifications_state.dart` |
| Tests de analytics | `test/features/notifications/presentation/cubit/notifications_analytics_test.dart` |
| Page + view | `lib/features/notifications/presentation/notifications_page.dart`, `notifications_view.dart` |
| Data view (lista + load more) | `lib/features/notifications/presentation/widgets/notifications_data_view.dart` |
| Item con icono por tipo | `lib/features/notifications/presentation/widgets/notification_item.dart` |
| Campana + badge | `lib/features/notifications/presentation/widgets/notification_bell_button.dart` |
| FCM service (init, deep links, token) | `lib/core/services/fcm_service.dart` |
| Background handler + main.dart | `lib/main.dart` |
| Router deep link | `lib/shared/router/app_router.dart` (`pushDeepLink`) |
| Endpoints API | `lib/core/http/api_routes.dart` |
