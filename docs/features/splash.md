# Documentación del Feature: Splash

> Última actualización: 2026-06-05  
> Alcance: `lib/features/splash/`

---

## Tabla de contenido

1. [Visión general](#1-visión-general)
2. [Modelo de dominio](#2-modelo-de-dominio)
3. [Arquitectura por capas](#3-arquitectura-por-capas)
   - 3.1 [Domain](#31-domain)
   - 3.2 [Presentation](#32-presentation)
4. [Cubit y estados](#4-cubit-y-estados)
5. [Flujo de arranque](#5-flujo-de-arranque)
6. [Permisos de ubicación](#6-permisos-de-ubicación)
7. [Rutas de navegación](#7-rutas-de-navegación)
8. [API endpoints](#8-api-endpoints)
9. [Dependencias clave](#9-dependencias-clave)
10. [Patrones y trampas conocidas](#10-patrones-y-trampas-conocidas)
11. [Archivos clave de referencia rápida](#11-archivos-clave-de-referencia-rápida)

---

## 1. Visión general

El feature **Splash** es la primera pantalla que ve el usuario al abrir la app. Tiene tres responsabilidades:

1. **Pedir permiso de ubicación una sola vez** (la primera apertura).
2. **Cargar el usuario actual** (Firebase Auth + storage local + API).
3. **Decidir el destino inicial** — `/login` si no hay sesión, `/home` si hay sesión válida.

Mientras esto sucede, muestra el branding "RIDEGLORY · Connect. Ride. Explore." con una barra de progreso animada (~2.2s).

No tiene capa de datos propia: depende de `AuthService` (capa `core/services`) y delega en `LoadCurrentUserUseCase` el chequeo.

---

## 2. Modelo de dominio

Splash **no define modelos propios**. Consume:

- `UserModel` desde `lib/features/users/domain/model/user_model.dart` (resultado de cargar usuario).
- `DomainException` desde `lib/core/exceptions/domain_exception.dart` (errores).

---

## 3. Arquitectura por capas

### 3.1 Domain
```
lib/features/splash/domain/
└── use_cases/
    └── load_current_user_use_case.dart
```

**`LoadCurrentUserUseCase`** (`@injectable`):
- Depende de `AuthService` (singleton de `core/services`).
- Llama `_authService.loadCurrentUser()`.
- Retorna `Future<Either<DomainException, UserModel?>>`.
- Un `Right(null)` significa "no hay sesión Firebase activa".

> No hay `repository/` propio. La capa de datos vive en `core/services/auth_service.dart`.

---

### 3.2 Presentation
```
lib/features/splash/presentation/
├── cubit/
│   ├── splash_cubit.dart
│   ├── splash_state.dart           ← part of splash_cubit.dart
│   └── splash_cubit.freezed.dart   ← generado
├── splash_screen.dart
└── widgets/
    ├── splash_brand_content.dart   ← logo + tagline
    ├── splash_footer.dart          ← barra de progreso o error
    └── splash_glow_background.dart ← halo radial (no usado en el árbol actual)
```

**`SplashScreen`** (StatelessWidget) provee el cubit con `BlocProvider<SplashCubit>` y llama `.initialize()` inmediatamente. Su contenido real es `_SplashContent` (StatefulWidget) que:

- Controla la `AnimationController` de la barra de progreso (`0.0 → 0.85`, easeInOut, 2200ms).
- Escucha `SplashCubit` con `BlocListener` para navegar en función del estado.
- Usa un flag `_hasNavigated` para evitar navegaciones duplicadas.

`SplashFooter` reacciona al estado:
- `SplashError` → muestra mensaje rojo + botón "Reintentar".
- Cualquier otro estado → renderiza la barra de progreso animada (`AnimatedBuilder` sobre `_progressAnimation`).

`SplashBrandContent` es estático: muestra `appName.toUpperCase()` + `'Connect. Ride. Explore.'`.

`SplashGlowBackground` existe pero **no está montado** dentro del `Stack` de `SplashScreen` (ver §10).

---

## 4. Cubit y estados

| Cubit | Archivo | DI | Estado base | Notas |
|---|---|---|---|---|
| `SplashCubit` | `presentation/cubit/splash_cubit.dart` | `@injectable` | `SplashState` (freezed union) | Llama `initialize()` una sola vez desde `SplashScreen.build()` |

**`SplashState`** (freezed sealed union):

```dart
@freezed
abstract class SplashState with _$SplashState {
  const factory SplashState.initial()         = SplashInitial;
  const factory SplashState.loading()         = SplashLoading;
  const factory SplashState.authenticated()   = SplashAuthenticated;
  const factory SplashState.unauthenticated() = SplashUnauthenticated;
  const factory SplashState.error(String message) = SplashError;
  const factory SplashState.forceUpdate()     = SplashForceUpdate;
}
```

> No usa `ResultState<T>` porque la salida no es un dato sino una decisión de navegación.

`SplashForceUpdate` se emite cuando la versión instalada es menor a `min_required_version` en Firebase Remote Config. El `BlocListener` muestra un `ForceUpdateDialog` no descartable (`barrierDismissible: false`, `PopScope(canPop: false)`) con un botón "Actualizar" que abre la Play Store / App Store.

**`SplashCubit.initialize()`** — único método público (más allá de los heredados):

```dart
Future<void> initialize() async {
  emit(SplashLoading());

  try {
    await LocationPermissionHandler.requestOnceOnFirstSplashOpen();
    await Future.delayed(const Duration(milliseconds: 1500));   // animación visible

    final result = await _loadCurrentUserUseCase();
    result.fold(
      (failure) => emit(SplashError(failure.message)),
      (user)    => emit(user == null
          ? SplashUnauthenticated()
          : SplashAuthenticated()),
    );
  } catch (e) {
    emit(SplashError('Failed to initialize: ${e.toString()}'));
  }
}
```

El delay de 1500ms es intencional para que la animación de la barra de progreso se vea aunque el chequeo sea muy rápido.

---

## 5. Flujo de arranque

```
App start
  │
  ▼
GoRouter initialLocation = '/'  →  SplashScreen
  │
  ├─ BlocProvider crea SplashCubit (DI) y llama .initialize()
  │
  ├─ _SplashContent.initState():
  │     AnimationController forward (2200ms, end=0.85)
  │
  ▼
SplashCubit.initialize()
  │
  ├─ LocationPermissionHandler.requestOnceOnFirstSplashOpen()
  │     └─ SharedPreferences['asked_location_permission_on_splash']
  │        si false → request locationWhenInUse (iOS) / location (Android)
  │
  ├─ delay 1500ms                         ← animación visible
  │
  └─ LoadCurrentUserUseCase()
        └─ AuthService.loadCurrentUser()
              ├─ FirebaseAuth.currentUser == null → null   →  Unauthenticated
              ├─ UserStorageService.getUser(uid)   → stored →  Authenticated
              └─ fallback: UserRepository.getCurrentUser() →  Authenticated o error

BlocListener<SplashCubit> en _SplashContent:
  │
  ├─ SplashForceUpdate     → showDialog(ForceUpdateDialog, barrierDismissible: false)
  ├─ SplashUnauthenticated → context.pushReplacementNamed('/login')
  ├─ SplashAuthenticated   → context.pushReplacementNamed('/home')
  └─ SplashError           → footer muestra error + botón Reintentar
                             onRetry → _hasNavigated=false + cubit.initialize()
```

**Navegación protegida adicional**: `AppRouter.redirect` (en `app_router.dart`) bloquea acceso a rutas autenticadas si `FirebaseAuth.instance.currentUser == null`, redirigiendo a `/login`. Splash es ruta pública (no se redirige).

---

## 6. Permisos de ubicación

`LocationPermissionHandler.requestOnceOnFirstSplashOpen()` (en `lib/core/permissions/`) implementa el patrón "preguntar una sola vez":

1. Lee `SharedPreferences['asked_location_permission_on_splash']`.
2. Si es `true` → retorna sin pedir nada.
3. Si es `false`/`null`:
   - Setea el flag a `true` **antes** de pedir (no se reintenta aunque el usuario niegue).
   - Llama `Permission.locationWhenInUse.request()` en iOS o `Permission.location.request()` en Android.

> Para tracking en vivo (background + notification) se usa otro flujo: `requestForLiveTracking()`, invocado desde `LiveTrackingCubit`.

---

## 7. Rutas de navegación

| Ruta | Constante | Página | Notas |
|---|---|---|---|
| `/` | `AppRoutes.splash` | `SplashScreen` | `initialLocation` de `GoRouter`. Sin params |

**Navegaciones salientes** (siempre `pushReplacementNamed`):
- `AppRoutes.login` (`/login`)
- `AppRoutes.home` (`/home`)

---

## 8. API endpoints

Splash no llama directamente a la API. Indirectamente, vía `AuthService.loadCurrentUser()` → `UserRepository.getCurrentUser()` puede ejecutar:

| Método | Endpoint | Descripción |
|---|---|---|
| `GET` | `/users/me` | Obtener perfil del usuario actual (solo si no estaba en storage local) |

Solo se ejecuta cuando `UserStorageService.getUser(firebaseUid)` retorna `null` (primera carga después de login en otro dispositivo, o storage borrado).

---

## 9. Dependencias clave

| Tipo | Nombre | Origen |
|---|---|---|
| Service | `AuthService` | `lib/core/services/auth_service.dart` (`@singleton`) |
| Service | `UserStorageService` | `lib/core/services/user_storage_service.dart` |
| Use case | `LoadCurrentUserUseCase` | propio (`@injectable`) |
| Repository | `UserRepository` | `lib/features/users/domain/repository/` (vía `AuthService`) |
| Permission | `LocationPermissionHandler` | `lib/core/permissions/location_permission_handler.dart` |
| L10n | `context.l10n.appName`, `splash_errorPrefix`, `splash_retryLabel` | `lib/l10n/app_es.arb` |

---

## 10. Patrones y trampas conocidas

### Doble navegación protegida con `_hasNavigated`
El flag local de `_SplashContentState` evita que el `BlocListener` dispare dos `pushReplacement` si el estado vuelve a emitirse (por ejemplo, hot reload o re-emisión).

### `Future.delayed(1500ms)` no es desperdicio
Es intencional para que la barra de progreso animada (2200ms, hasta 0.85) sea visible. Sin el delay, en redes rápidas la pantalla se vería como un flash. **Si se cambia la duración de la animación, este delay también debe ajustarse.**

### `requestOnceOnFirstSplashOpen` setea el flag antes de la respuesta
Si el usuario niega el permiso, no se le volverá a preguntar desde splash. Para volver a pedirlo (por ejemplo desde Live Tracking), hay que usar `LocationPermissionHandler.requestForLiveTracking()` o `openSettings()`.

### `SplashGlowBackground` no está montado
El widget existe en `widgets/splash_glow_background.dart` pero no aparece en el `Stack` de `SplashScreen`. Está disponible como pieza decorativa lista para reutilizar, pero hoy no se renderiza. Si se "limpia" el feature, considerar si se vuelve a montar o se borra.

### `SplashState` usa freezed union, no `ResultState<T>`
A diferencia del resto del codebase, splash usa una unión sellada de 5 casos en lugar de `ResultState<T>`. Razón: la salida del flujo no es un dato consumible, sino una decisión de navegación discreta. Mantener este patrón si se agregan estados (ej. `SplashOnboardingNeeded`).

### El delay se interpone con `LoadCurrentUserUseCase`
Si `AuthService.loadCurrentUser()` tarda más de 1500ms, el delay no añade latencia (corre antes). Si tarda menos, el usuario igual ve la animación completa. El total mínimo es ~1500ms.

### El cubit es `@injectable`, no singleton
Cada `SplashScreen.build()` crea una nueva instancia. En la práctica solo se crea uno porque solo se monta una vez, pero si se vuelve a navegar a `/` (no es el flujo normal) se crearía otro.

---

## 11. Archivos clave de referencia rápida

| Qué buscar | Archivo |
|---|---|
| Use case de carga de usuario | `lib/features/splash/domain/use_cases/load_current_user_use_case.dart` |
| Cubit y estados | `lib/features/splash/presentation/cubit/splash_cubit.dart` |
| Pantalla principal | `lib/features/splash/presentation/splash_screen.dart` |
| Logo + tagline | `lib/features/splash/presentation/widgets/splash_brand_content.dart` |
| Barra de progreso / error | `lib/features/splash/presentation/widgets/splash_footer.dart` |
| Halo radial (no montado) | `lib/features/splash/presentation/widgets/splash_glow_background.dart` |
| AuthService (carga de usuario) | `lib/core/services/auth_service.dart` |
| Permission handler | `lib/core/permissions/location_permission_handler.dart` |
| Guard de rutas | `lib/shared/router/app_router.dart` (`redirect`) |
| Rutas constantes | `lib/shared/router/app_routes.dart` |
