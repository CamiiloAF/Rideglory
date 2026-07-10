# Checklist de QA — Notifications

**Feature:** Centro de notificaciones, FCM y deep linking (`lib/features/notifications/` + `lib/core/services/fcm_service.dart`)
**Referencia:** `docs/features/notifications.md` (actualizada 2026-07-04, incluye sección de analytics)
**Estado:** Pendiente de ejecución

---

## Pre-condiciones

- [ ] Dispositivo o emulador con Google Play Services (necesario para FCM) y notificaciones push habilitadas a nivel de SO.
- [ ] Cuenta de prueba autenticada (`qa1@gmail.com` / `Test123.`) con sesión iniciada al menos una vez (para que se registre el token FCM).
- [ ] Acceso a Firebase Console (o al backend) para enviar una notificación push de prueba a un usuario/token específico, con al menos un `payload.route` tipo `rideglory://events/detail-by-id?id=<uuid>` apuntando a un evento existente.
- [ ] Al menos 5-10 notificaciones de prueba insertadas para el usuario en backend (mezcla de leídas/no leídas, distintos `type`) para poder probar paginación (`limit=20`) y las dos secciones ("SIN LEER"/"LEÍDAS").
- [ ] Un evento real accesible por el usuario de prueba (para verificar el deep link `newRegistration`/`registrationApproved`/`registrationRejected`).
- [ ] App cerrada completamente (terminated state), en background, y en foreground — se necesitan los tres estados para probar el tap sobre la notificación.
- [ ] Dos dispositivos/cuentas si se quiere probar `newRegistration` end-to-end (uno organiza el evento, otro se inscribe).

---

## 1. Registro de token FCM

> Verifica que el token se registra después de autenticarse.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 1.1 | Inicia sesión con una cuenta nueva (o cierra sesión y vuelve a entrar) | `FcmService.initialize()` corre tras el login; no se ve ningún crash ni bloqueo del flujo de login | 👤 Manual (requiere dispositivo real/emulador con Play Services; el flujo de inicialización no es unit-testeable sin mockear todo el SDK de Firebase Messaging) | |
| 1.2 | Revisa en backend (tabla de tokens FCM o logs) que el token del dispositivo quedó asociado al usuario | El token aparece registrado tras el login | 👤 Manual (requiere acceso a BD/backend) | |
| 1.3 | Verifica que `POST /notifications/fcm-token` se llama con `{"fcmToken": "..."}` | El use case delega correctamente en el repository, que envía el body esperado | 🤖✅ Auto-PASS (`test/features/notifications/domain/usecases/register_fcm_token_usecase_test.dart`; `test/features/notifications/data/repository/notifications_repository_impl_test.dart`) | |
| 1.4 | Fuerza un error de red al registrar el token (o revisa el caso de error del use case) | El use case retorna `Left(DomainException)` sin crashear la app; el login sigue funcionando con normalidad | 🤖✅ Auto-PASS (`test/features/notifications/domain/usecases/register_fcm_token_usecase_test.dart`) | |
| 1.5 | Verifica en Analytics (o logs) el evento `fcm_token_registered` solo cuando el registro fue exitoso | El evento se dispara únicamente en el camino feliz, sin loguear el valor del token (PII) | 👤 Manual (requiere consola de Analytics/Firebase para confirmar el evento real; la lógica de disparo condicional se prueba a nivel de código pero no la ausencia del token en el dashboard) | |

---

## 2. Recibir notificación push (FCM) — foreground

> Con la app abierta y en primer plano, envía una push de prueba al usuario.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 2.1 | Envía una push mientras la app está en foreground (Android) | Aparece una notificación local (banner) generada por `_showForegroundNotification`, sin duplicarse | 👤 Manual (requiere envío real de push vía Firebase Console/backend y observación visual del banner en el dispositivo) | |
| 2.2 | Envía la misma push en iOS con la app en foreground | La notificación la maneja el SO nativo (`setForegroundNotificationPresentationOptions`), se ve el banner del sistema | 👤 Manual (comportamiento nativo de iOS, no automatizable con flutter_test) | |
| 2.3 | Toca la notificación foreground | Navega a la ruta indicada en `payload.route` vía `AppRouter.pushDeepLink` | 👤 Manual (requiere push real + tap físico; el parseo de la URI se cubre por separado, ver sección 6) | |

---

## 3. Recibir notificación push (FCM) — background y terminated

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3.1 | Envía una push con la app en background (minimizada, no cerrada) | Llega la notificación del sistema; al tocarla, `onMessageOpenedApp` navega a la ruta del payload | 👤 Manual (requiere dispositivo real y manipular el ciclo de vida de la app) | |
| 3.2 | Envía una push con la app completamente cerrada (terminated) | Al abrir la app tocando la notificación, tras el delay de 300ms definido en `getInitialMessage()`, navega directo a la ruta del payload (no se queda en home/splash) | 👤 Manual (requiere matar la app y reabrir desde la notificación; comportamiento del SO) | |
| 3.3 | Revisa logs/consola con la app en background al recibir cualquier push | Se ve el log `FCM background message: <messageId>` del `firebaseMessagingBackgroundHandler` en modo debug, sin excepciones | 👤 Manual (requiere logs del dispositivo/logcat) | |

---

## 4. Ver el centro de notificaciones

> Entra a la campana desde Home.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 4.1 | Toca la campana en `HomeHeader` | Navega a `/notifications` (`NotificationsPage`) con el AppBar "Centro de notificaciones" | 🤖✅ Auto-PASS (`test/features/notifications/presentation/widgets/notification_bell_button_test.dart`, TC-notif-bell-1: confirma que tocar `NotificationBellButton` navega a la ruta `AppRoutes.notifications`; el AppBar de `NotificationsView` no se re-verifica aquí porque ya se prueba visualmente en la app) | |
| 4.2 | Con notificaciones existentes (mezcla leídas/no leídas), abre la pantalla | Se listan en dos secciones: "SIN LEER" (con píldora de contador) arriba y "LEÍDAS" abajo | 🤖✅ Auto-PASS (`test/features/notifications/presentation/cubit/notifications_cubit_test.dart`, grupo `load (US-2-11)`) | |
| 4.3 | Revisa cada tarjeta de notificación | Muestra icono coloreado según el tipo (`registrationApproved`=verde, `registrationRejected`=rojo, `newRegistration`=primary, `soat*`=warning, `general`=gris), título, cuerpo y tiempo relativo ("Hace 2h", "Ahora", etc.) | 👤 Manual (no existe widget test de `NotificationItem`; verificación visual del mapeo icono/color y del cálculo de tiempo relativo) | |
| 4.4 | Sin ninguna notificación (usuario nuevo) | Se muestra el estado vacío (`NotificationsEmptyState`) | 🤖✅ Auto-PASS (`test/features/notifications/presentation/widgets/notifications_empty_state_test.dart`, TC-notif-empty-1: verifica icono, título "Sin notificaciones" y subtítulo; el estado `empty` del cubit ya estaba cubierto en `notifications_cubit_test.dart`) | |
| 4.5 | Simula un error de red al cargar (apaga backend/wifi) | Se muestra `NotificationsErrorState` con botón de reintento; al tocarlo, reintenta `load()` | 🤖✅ Auto-PASS (`test/features/notifications/presentation/widgets/notifications_error_state_test.dart`, TC-notif-error-1 y TC-notif-error-2: verifica icono/título/subtítulo y que tocar "Reintentar" invoca el callback `onRetry` que `NotificationsView` conecta a `load()`) | |
| 4.6 | Haz pull-to-refresh en la lista | Se dispara `load()` de nuevo y la lista se actualiza | 👤 Manual (requiere interacción de gesto sobre `RefreshIndicator`; no hay widget test específico del pull-to-refresh) | |

---

## 5. Marcar una notificación como leída

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5.1 | Toca una notificación no leída (sin `route` en el payload) | Se marca como leída al instante (optimistic), el punto azul desaparece y pasa a la sección "LEÍDAS"; `unreadCount` baja en 1 | 🤖✅ Auto-PASS (`test/features/notifications/presentation/cubit/notifications_cubit_test.dart`, grupo `markRead optimistic update`) | |
| 5.2 | Toca una notificación no leída que sí tiene `route` en el payload | Se marca como leída Y navega al deep link correspondiente | 👤 Manual (requiere combinar el tap con la navegación real de `AppRouter.pushDeepLink`; no cubierto por widget/unit test) | |
| 5.3 | Revisa que se llame `PATCH /notifications/{id}/read` en background tras el tap | El use case y el repository invocan el endpoint correctamente y manejan el error sin romper la UI (ya está "leída" localmente aunque el backend falle) | 🤖✅ Auto-PASS (`test/features/notifications/domain/usecases/mark_notification_read_usecase_test.dart`; `test/features/notifications/data/repository/notifications_repository_impl_test.dart`) | |
| 5.4 | Revisa Analytics tras marcar como leída | Se dispara `notification_marked_read` con el parámetro `notification_type` (nombre del enum), antes de llamar al use case | 🤖✅ Auto-PASS (`test/features/notifications/presentation/cubit/notifications_analytics_test.dart`) | |
| 5.5 | Verifica que cargar la lista (`load()`) NO dispare el evento de analytics de "marcado como leído" | `load()` no emite `notification_marked_read` | 🤖✅ Auto-PASS (`test/features/notifications/presentation/cubit/notifications_analytics_test.dart`, TC-notif-a2) | |

---

## 6. Marcar todas como leídas

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 6.1 | Con `unreadCount > 0`, revisa el AppBar | Aparece el botón/acción "Marcar todo como leído" | 👤 Manual (no hay widget test de `NotificationsView`/AppBar; se infiere de la lógica del cubit pero falta verificación visual) | |
| 6.2 | Toca "Marcar todo como leído" | Todas las notificaciones pasan a "LEÍDAS" de inmediato (optimistic), `unreadCount` queda en 0 y el botón desaparece | 🤖✅ Auto-PASS (`test/features/notifications/presentation/cubit/notifications_cubit_test.dart`, grupo `markAllRead optimistic update`) | |
| 6.3 | Revisa que se llame `PATCH /notifications/read-all` en background | El use case y repository invocan el endpoint y toleran errores sin bloquear la UI | 🤖✅ Auto-PASS (`test/features/notifications/domain/usecases/mark_all_notifications_read_usecase_test.dart`; `test/features/notifications/data/repository/notifications_repository_impl_test.dart`) | |
| 6.4 | Revisa Analytics tras "marcar todo como leído" | Se dispara `notifications_all_read` sin parámetros | 🤖✅ Auto-PASS (`test/features/notifications/presentation/cubit/notifications_analytics_test.dart`, TC-notif-a3) | |
| 6.5 | Con `unreadCount == 0` desde el inicio (todas ya leídas) | El botón "Marcar todo como leído" no se muestra | 👤 Manual (condicional de UI del AppBar no cubierto por widget test) | |

---

## 7. Badge de no-leídas

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 7.1 | Con notificaciones no leídas, revisa la campana en `HomeHeader` | Muestra un badge circular rojo con el número de no-leídas (icono relleno si `> 0`) | 🤖✅ Auto-PASS (`test/features/notifications/presentation/widgets/notification_bell_button_test.dart`, TC-notif-bell-3: `unreadCount = 3` → icono relleno (`Icons.notifications`) y badge con texto "3") | |
| 7.2 | Recibe más de 99 notificaciones no leídas (o simula el estado) | El badge muestra "99+" en vez del número exacto | 🤖✅ Auto-PASS (`test/features/notifications/presentation/widgets/notification_bell_button_test.dart`, TC-notif-bell-4: `unreadCount = 150` → badge muestra "99+") | |
| 7.3 | Sin notificaciones no leídas | El icono de la campana se ve outlined (no relleno) y sin badge | 🤖✅ Auto-PASS (`test/features/notifications/presentation/widgets/notification_bell_button_test.dart`, TC-notif-bell-2: `unreadCount = 0` → icono outlined y sin texto de badge) | |
| 7.4 | Marca una notificación como leída y vuelve a Home sin recargar Home | El badge de la campana refleja el nuevo `unreadCount` (cubit es `@lazySingleton`, vive en toda la app) | 🤖✅ Auto-PASS (`test/features/notifications/presentation/widgets/notification_bell_button_test.dart`, TC-notif-bell-5: emite un nuevo estado por el stream del cubit mockeado, sin recrear el widget, y confirma que el badge pasa de sin-badge/outlined a "5"/relleno) | |

---

## 8. Deep linking desde notificación a la pantalla correcta

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 8.1 | Recibe una notificación de tipo `newRegistration` con `route = rideglory://events/detail-by-id?id=<uuid>` y tócala | Navega directo al detalle del evento correspondiente, no a `/notifications` ni a home | 👤 Manual (requiere push real end-to-end; el parseo de la URI en sí se puede revisar en código de `AppRouter.pushDeepLink`, sin test unitario dedicado — ver "Fixes requeridos") | |
| 8.2 | Recibe un deep link externo (`app_links`, ej. desde un link compartido) con scheme `rideglory://` | Se navega igual que una push, usando el mismo `_navigateFromUri` | 👤 Manual (requiere abrir un link externo real desde otra app en el dispositivo) | |
| 8.3 | Recibe una URI con scheme distinto de `rideglory://` | Se ignora silenciosamente, sin navegar ni crashear | 👤 Manual (no hay test unitario de `_navigateFromUri`; función privada de `FcmService`) | |
| 8.4 | Toca una notificación del centro (`NotificationsDataView`) que tiene `route` distinto a `/notifications` (por ejemplo un evento) | Marca como leída Y navega a esa ruta con `AppRouter.pushDeepLink` | 👤 Manual (mismo caso que 5.2) | |

---

## 9. Casos de borde

### 9A. Tipos de notificación no mapeados al enum

> Un tipo del backend como `MAINTENANCE_DATE_REMINDER`, `EVENT_REMINDER`, `SOS_ALERT` o `TRACKING_ENDED`.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 9A.1 | Recibe/lista una notificación de tipo `SOS_ALERT` (o los otros 3 tipos sin enum dedicado) | Se muestra con el icono/color de fallback `general` pero con título/body específicos en español ("Alerta SOS", etc.) | 🤖✅ Auto-PASS (`test/features/notifications/data/dto/notification_dto_test.dart`: cubre los 4 tipos sin enum dedicado — `MAINTENANCE_DATE_REMINDER`, `EVENT_REMINDER`, `SOS_ALERT`, `TRACKING_ENDED` — verificando `type == NotificationType.general` junto con el título/cuerpo específico en español vía `NotificationDto.toModel()`; incluye además un caso de tipo totalmente desconocido que cae al fallback genérico "Notificación"/body vacío) | |

### 9B. Payload sin `route`

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 9B.1 | Recibe una notificación cuyo `payload` no trae `route` (o el cast falla) | El tap solo marca como leída, sin intentar navegar ni crashear | 👤 Manual (cast inseguro documentado como trampa conocida; no hay test que fuerce un payload malformado) | |

### 9C. Paginación (`loadMore`)

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 9C.1 | Con más de 20 notificaciones, llega al final de la lista y toca "Cargar más" | Se agregan más notificaciones a la lista existente, se actualiza `nextCursor` y se recalcula `unreadCount` | 🤖✅ Auto-PASS (`test/features/notifications/presentation/cubit/notifications_cubit_test.dart`, grupo `loadMore (cursor pagination)`) | |
| 9C.2 | Toca "Cargar más" repetidas veces rápido (doble tap) | No se disparan requests duplicados mientras `isLoadingMore == true` | 🤖✅ Auto-PASS (`test/features/notifications/presentation/cubit/notifications_cubit_test.dart`, TC-2-38b: dispara `loadMore()` sin esperar su resultado — dejando el use case pendiente vía `Completer` — y llama `loadMore()` una segunda vez mientras `isLoadingMore == true`; verifica que `mockGetNotifications(cursor: 'cursor-1')` se llamó una sola vez y que la lista final no duplica datos) | |
| 9C.3 | Llega al final de la lista (`nextCursor == null`) | No aparece el botón "Cargar más" | 👤 Manual (condicional de UI de `NotificationsDataView`, sin widget test dedicado) | |

---

## 10. Verificaciones técnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso al código, logs o consola de desarrollo.

| # | Verificación | Resultado esperado | ✅/❌ |
|---|-------------|--------------------|-------|
| 10.1 | Correr `flutter test test/features/notifications/` | Todos los tests del feature pasan en verde | |
| 10.2 | Correr `dart analyze` sobre `lib/features/notifications/` y `lib/core/services/fcm_service.dart` | Sin issues nuevos | |
| 10.3 | Revisar que `NotificationsCubit` esté registrado como `@lazySingleton` en el root `MultiBlocProvider` de `main.dart` | Confirmado; el badge funciona desde cualquier pantalla sin recrear el cubit | |
| 10.4 | Revisar logs al forzar un error en `markRead`/`markAllRead` (backend caído) | No hay excepciones no capturadas; la UI queda "leída" localmente aunque desincronizada del backend (comportamiento documentado, sin rollback) | |
| 10.5 | Confirmar que `firebaseMessagingBackgroundHandler` está registrado en `main.dart` antes de `runApp()` | `FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler)` se llama en el punto correcto del arranque | |
| 10.6 | Revisar si existen widget tests para `NotificationBellButton`, `NotificationItem`, `NotificationsEmptyState`, `NotificationsErrorState` y `NotificationsView`/AppBar | Parcialmente resuelto: ya existen tests de `NotificationBellButton` (`notification_bell_button_test.dart`), `NotificationsEmptyState` (`notifications_empty_state_test.dart`) y `NotificationsErrorState` (`notifications_error_state_test.dart`). Sigue faltando `NotificationItem` y `NotificationsView`/AppBar (botón "Marcar todo como leído") — ver "Fixes requeridos" | |

---

## Fixes requeridos

> Gaps de cobertura de presentación identificados durante la planificación. Actualización 2026-07-04: se cerraron los gaps de `NotificationBellButton`, `NotificationsEmptyState`, `NotificationsErrorState`, el fallback título/cuerpo de `NotificationDto` y la guarda de concurrencia de `loadMore()`. Quedan pendientes los siguientes:

1. **Alta prioridad** — No existe widget test de `NotificationItem` (mapeo icono/color por tipo, punto azul de no-leído, tiempo relativo). Lógica de presentación pura, fácil de testear con `testWidgets` + `WidgetTester`.
2. **Media prioridad** — No hay test de `NotificationsView`/AppBar que confirme que el botón "Marcar todo como leído" aparece/desaparece según `unreadCount`.
3. **Baja prioridad** — No hay unit test de `AppRouter.pushDeepLink` para el caso `scheme != 'rideglory'` (debe ignorar sin crashear) ni de la conversión de URI a ruta interna.

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos de las secciones 1–8 marcados como ✅ |
| ⚠️ Aprobado con observaciones | Máximo 2 casos fallidos de baja severidad (secciones 9 o 10), con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones 1, 4, 5, 6 u 8 marcado como ❌ |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________
