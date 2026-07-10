# Checklist de QA — Splash

**Feature:** Pantalla de arranque: decisión login vs home, force-update, permisos de ubicación (`lib/features/splash/`)
**Referencia:** `docs/features/splash.md` (actualizada 2026-07-04)
**Estado:** Pendiente de ejecución

---

## Pre-condiciones

- [ ] Un dispositivo/emulador donde se pueda desinstalar y reinstalar la app (para simular "primer arranque" real, incluyendo permisos de SO en estado no preguntado).
- [ ] Una cuenta de prueba (`qa1@gmail.com` / `Test123.`) para probar el arranque con sesión activa.
- [ ] Acceso a Firebase Remote Config del proyecto para editar `min_required_version` en vivo (probar force-update).
- [ ] El build instalado debe tener un número de versión conocido (revisar `pubspec.yaml` / `PackageInfo`) para poder fijar un `min_required_version` mayor y forzar el modal.
- [ ] Capacidad de simular sin conexión a internet / Remote Config no descargable (modo avión al primer arranque) para probar el fix de pantalla blanca.
- [ ] Dispositivo Android y dispositivo/simulador iOS si se quiere cubrir ambos flujos de apertura de tienda (`_openStore()`).
- [ ] Acceso a `adb`/Xcode logs o Sentry para revisar que no aparezcan crashes/errores no capturados durante el arranque.

---

## 1. Primer arranque sin sesión (→ login)

> Instala la app por primera vez (o borra datos de la app) y ábrela sin haber iniciado sesión nunca.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 1.1 | Abre la app recién instalada | Se ve el branding "RIDEGLORY · Connect. Ride. Explore." con barra de progreso animada, fondo oscuro sin parpadeo claro→oscuro | 👤 Manual (verificación visual del splash nativo + Flutter; no automatizable con flutter_test) | |
| 1.2 | Espera a que termine la animación/carga | Aparece un diálogo de permiso de ubicación del sistema operativo (primera vez) | 👤 Manual (requiere interacción real con el diálogo nativo del SO) | |
| 1.3 | Otorga o niega el permiso de ubicación | En ambos casos, el flujo continúa sin bloquearse hacia la decisión de navegación | 🤖✅ Auto-PASS (`test/features/splash/presentation/cubit/splash_cubit_test.dart` mockea `asked_location_permission_on_splash` y no depende del resultado del permiso para continuar el flujo) | |
| 1.4 | Sin sesión Firebase activa | El cubit emite `SplashLoading` y luego `SplashUnauthenticated`; la app navega con `pushReplacementNamed('/login')` | 🤖✅ Auto-PASS (`test/features/splash/presentation/cubit/splash_cubit_test.dart`, grupo `SplashCubit — sin sesión`) | |
| 1.5 | Verifica el tiempo total del splash | La animación se ve completa (no hay flash instantáneo) gracias al delay mínimo de ~1500ms | 👤 Manual (percepción visual del timing; no es determinístico vía widget test sin mockear timers) | |
| 1.6 | Vuelve a abrir la app (segunda vez, ya con el flag de permiso guardado) | NO se vuelve a mostrar el diálogo de permiso de ubicación | 👤 Manual (requiere cerrar/reabrir la app real y observar ausencia del diálogo) | |

---

## 2. Arranque con sesión activa (→ home)

> Con sesión iniciada previamente, cierra completamente la app y vuelve a abrirla.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 2.1 | Abre la app con sesión Firebase válida y usuario ya guardado en storage local | El cubit emite `SplashLoading` → `SplashAuthenticated`; navega con `pushReplacementNamed('/home')` | 🤖✅ Auto-PASS (`test/features/splash/presentation/cubit/splash_cubit_test.dart`, grupo `SplashCubit — camino feliz`) | |
| 2.2 | Revisa que `AuthCubit` quede sincronizado tras llegar a home | `context.read<AuthCubit>().checkAuthState()` se llama justo antes de navegar, así el resto de la app (guards del router, UI) ve el usuario correcto | 👤 Manual (requiere inspección de `SplashScreen._handleNavigation` en ejecución real o un widget test de `SplashScreen` que no existe hoy — ver "Fixes requeridos") | |
| 2.3 | Con usuario guardado localmente en `UserStorageService` (sin necesidad de llamar a la API) | `LoadCurrentUserUseCase` retorna el usuario desde storage sin hacer `GET /users/me` | 🤖✅ Auto-PASS (`test/features/splash/domain/use_cases/load_current_user_use_case_test.dart`, camino feliz) | |
| 2.4 | Borra el storage local pero mantén la sesión de Firebase Auth (reinstalar app sin cerrar sesión, o storage corrupto) | Se hace fallback a `UserRepository.getCurrentUser()` (`GET /users/me`) y de igual forma navega a home | 👤 Manual (requiere condición específica de storage vacío + sesión Firebase persistida; no cubierto directamente por el test del use case, que mockea `AuthService` completo) | |
| 2.5 | Simula un error al cargar el usuario (backend caído, token inválido) | El cubit emite `SplashError(message)`; el footer muestra el mensaje de error y un botón "Reintentar" | 🤖✅ Auto-PASS (`test/features/splash/presentation/cubit/splash_cubit_test.dart`, grupo `SplashCubit — error al cargar usuario`; `load_current_user_use_case_test.dart` cubre la propagación del `Left`) | |
| 2.6 | Toca "Reintentar" tras un error | Se resetea `_hasNavigated` y se vuelve a llamar `initialize()`, repitiendo todo el flujo | 👤 Manual (requiere widget test de `SplashScreen`/`SplashFooter` con interacción de tap, no existe hoy — ver "Fixes requeridos") | |
| 2.7 | Provoca una excepción inesperada durante `initialize()` (no un `Either.Left`, sino un throw) | Se captura en el `catch` genérico y emite `SplashError('Failed to initialize: ...')` sin crashear la app | 🤖✅ Auto-PASS (`test/features/splash/presentation/cubit/splash_cubit_test.dart`, grupo `SplashCubit — excepción inesperada`) | |

---

## 3. Force-update (versión mínima no cumplida)

> Configura en Firebase Remote Config un `min_required_version` mayor a la versión instalada del build de prueba.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3.1 | Abre la app con una versión instalada menor al `min_required_version` remoto | El cubit emite `SplashForceUpdate` antes de intentar cargar el usuario (no llega a `Authenticated`/`Unauthenticated` aunque haya sesión activa) | 🤖✅ Auto-PASS (`test/features/splash/presentation/cubit/splash_cubit_test.dart`, grupo `SplashCubit — chequeo de force update`) | |
| 3.2 | Revisa el modal que aparece | Se muestra `AppModal` variante `warning` con título/mensaje de actualización requerida y un único botón "Actualizar", sin botón de cierre/cancelar | 👤 Manual (verificación visual del modal compartido; no hay widget test de `SplashScreen` que confirme la llamada a `AppModal.show`, ver "Fixes requeridos") | |
| 3.3 | Intenta cerrar el modal tocando fuera de él o con el botón atrás del sistema | El modal no se cierra (`autoClose: false`, sin botón de cancelar) — la app queda bloqueada hasta actualizar | 👤 Manual (requiere interacción física con gestos de cierre de modal/back button) | |
| 3.4 | Toca "Actualizar" en Android | Se abre Play Store en la ficha de la app (`_openStore()` con el paquete Android) | 👤 Manual (requiere dispositivo Android real con Play Store instalada; abrir un intent externo no es testeable con flutter_test) | |
| 3.5 | Toca "Actualizar" en iOS | Se abre App Store en la ficha de la app (`id6778918834`) | 👤 Manual (requiere dispositivo iOS real con App Store) | |
| 3.6 | Con la versión instalada igual o mayor al `min_required_version` | No se muestra el modal de force-update; el flujo continúa normal hacia `Authenticated`/`Unauthenticated` | 🤖✅ Auto-PASS (implícito en los grupos "camino feliz" y "sin sesión" de `splash_cubit_test.dart`, que fijan `min_required_version=''` y no emiten `SplashForceUpdate`) | |
| 3.7 | Con `min_required_version` vacío o no configurado en Remote Config | No se bloquea el arranque (comparación semver tolera valor vacío) | 🤖✅ Auto-PASS (todos los tests de `splash_cubit_test.dart` usan `mockRemoteConfig.getString(...) → ''` como default sin disparar force-update) | |

---

## 4. Permisos de ubicación en el splash

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 4.1 | Primera apertura de la app (flag `asked_location_permission_on_splash` no seteado) | Se pide el permiso de ubicación (`locationWhenInUse` en iOS, `location` en Android) antes de decidir la navegación | 👤 Manual (requiere dispositivo real y observar el diálogo nativo; el flag se puede mockear pero el request real del SO no) | |
| 4.2 | El usuario niega el permiso | El flujo de splash continúa igual (login/home) sin quedar bloqueado por el permiso denegado | 🤖✅ Auto-PASS (`splash_cubit_test.dart` mockea el flag como ya preguntado y confirma que el flujo de navegación no depende del resultado del permiso) | |
| 4.3 | Segunda apertura de la app (flag ya seteado en `true`) | No se vuelve a pedir el permiso de ubicación, sin importar si fue otorgado o negado la primera vez | 👤 Manual (requiere reabrir la app real dos veces; el comportamiento del flag está documentado pero no hay test que verifique "no volver a preguntar" desde `LocationPermissionHandler` en un escenario end-to-end) | |
| 4.4 | Verifica que el flag se setea ANTES de esperar la respuesta del usuario | Aunque el usuario tarde en responder el diálogo del SO, el flag ya quedó en `true`, evitando reintentos | 👤 Manual (requiere inspección de `LocationPermissionHandler.requestOnceOnFirstSplashOpen()` en tiempo real; comportamiento documentado en el código, sin test unitario dedicado del handler — ver "Fixes requeridos") | |

---

## 5. Casos de borde

### 5A. Pantalla blanca en primer arranque (regresión del fix jun/2026)

> Simula fallo de red / Remote Config sin caché en el primer arranque (modo avión antes de abrir la app por primera vez).

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5A.1 | Instala la app, activa modo avión, ábrela por primera vez | La app NO se queda en blanco; se ve el splash con branding y, tras el flujo normal, navega a login (fallback fault-tolerant de Remote Config) | 👤 Manual (requiere reproducir la condición de red real del primer arranque; regresión histórica de alta severidad, validar manualmente en cada release) | |
| 5A.2 | Revisa logs/Sentry durante ese arranque sin red | No hay excepciones no capturadas de Remote Config ni errores de zone mismatch | 👤 Manual (requiere acceso a Sentry/logs del dispositivo) | |

### 5B. Doble navegación

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5B.1 | Fuerza una re-emisión del mismo estado del cubit (hot reload en desarrollo, o reemisión accidental) | No se dispara un segundo `pushReplacement` gracias al flag `_hasNavigated` | 👤 Manual (requiere provocar hot reload/reemisión en tiempo real; no hay widget test de `SplashScreen`/`_SplashContent` que lo confirme — ver "Fixes requeridos") | |

---

## 6. Verificaciones técnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso al código, logs o consola de desarrollo.

| # | Verificación | Resultado esperado | ✅/❌ |
|---|-------------|--------------------|-------|
| 6.1 | Correr `flutter test test/features/splash/` | Todos los tests del feature pasan en verde | |
| 6.2 | Correr `dart analyze` sobre `lib/features/splash/` | Sin issues nuevos | |
| 6.3 | Revisar `main.dart` — confirmar que `WidgetsFlutterBinding.ensureInitialized()`, `Firebase.initializeApp`, Sentry, Remote Config, DI y `runApp()` corren dentro de un único `runZonedGuarded` | Confirmado, evita el zone mismatch documentado en el fix de pantalla blanca | |
| 6.4 | Revisar orden de inicialización: Sentry antes de `ApiRemoteConfig.initialize(...)` | Confirmado; errores de red/Firebase del arranque quedan capturados por Sentry | |
| 6.5 | Confirmar que `SplashCubit` es `@injectable` (no singleton) y que solo se crea una instancia en el flujo normal | Confirmado por inspección de `splash_screen.dart`/DI | |
| 6.6 | Revisar si existe un widget test de `SplashScreen`/`_SplashContent` (navegación, `BlocListener`, `AppModal.show` en force-update) | Actualmente no existe (solo hay tests de cubit y use case) — confirmar gap de cobertura en capa de presentación | |
| 6.7 | Confirmar que `SplashGlowBackground` sigue sin montarse en el `Stack` de `SplashScreen` (o si se reactivó) | Documentar el estado actual para evitar código muerto sorpresa | |

---

## Fixes requeridos

> El feature tiene buena cobertura en `SplashCubit` y `LoadCurrentUserUseCase` (domain + estados), pero cero cobertura de widget/integración en `SplashScreen`, `SplashFooter` y `LocationPermissionHandler`.

1. **Alta prioridad** — No existe ningún widget test de `SplashScreen`/`_SplashContent` que verifique la navegación real (`BlocListener` → `pushReplacementNamed`) ni la llamada a `AppModal.show` en el caso `SplashForceUpdate`. Es el único punto donde se conecta el cubit con la UI/router; alto riesgo si se refactoriza.
2. **Alta prioridad** — El flujo "pantalla blanca en primer arranque" (fix jun/2026) es una regresión histórica crítica sin ningún test automatizado (ni unit ni integración) que la proteja. Evaluar un test de integración mínimo o al menos documentar el escenario en un checklist de release manual permanente.
3. **Media prioridad** — No existe test unitario de `LocationPermissionHandler.requestOnceOnFirstSplashOpen()` (guardado del flag antes de la respuesta, no repetir si ya está en `true`).
4. **Media prioridad** — El botón "Reintentar" de `SplashFooter` tras un `SplashError` no tiene widget test que confirme que resetea `_hasNavigated` y vuelve a llamar `initialize()`.
5. **Baja prioridad** — No hay test que confirme la sincronización `context.read<AuthCubit>().checkAuthState()` justo antes de navegar a home cuando el estado es `SplashAuthenticated`.

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos de las secciones 1–4 marcados como ✅ |
| ⚠️ Aprobado con observaciones | Máximo 2 casos fallidos de baja severidad (secciones 5 o 6), con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones 1, 2 o 3 marcado como ❌ |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________
