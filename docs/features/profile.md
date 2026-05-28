# Documentación del Feature: Profile

> Última actualización: 2026-05-28  
> Alcance: `lib/features/profile/`

---

## Tabla de contenido

1. [Visión general](#1-visión-general)
2. [Modelo de dominio](#2-modelo-de-dominio)
3. [Arquitectura por capas](#3-arquitectura-por-capas)
   - 3.1 [Domain](#31-domain)
   - 3.2 [Presentation](#32-presentation)
4. [Cubit y estados](#4-cubit-y-estados)
5. [Estructura de la pantalla](#5-estructura-de-la-pantalla)
6. [Flujo de edición](#6-flujo-de-edición)
7. [Logout](#7-logout)
8. [Rutas de navegación](#8-rutas-de-navegación)
9. [API endpoints](#9-api-endpoints)
10. [Conexiones con otros features](#10-conexiones-con-otros-features)
11. [Patrones y trampas conocidas](#11-patrones-y-trampas-conocidas)
12. [Archivos clave de referencia rápida](#12-archivos-clave-de-referencia-rápida)

---

## 1. Visión general

El feature **Profile** es la pantalla del perfil personal del usuario (tab de bottom navigation). Su responsabilidad principal:

1. **Mostrar datos del usuario actual** (foto, nombre, email, ciudad).
2. **Navegar al editor del perfil** (edición de campos personales y de emergencia).
3. **Listar accesos rápidos** a inscripciones, borradores, mantenimientos.
4. **Permitir logout** con confirmación.

No tiene capa de datos propia: depende de `UserRepository` (feature `users`) vía `GetMyProfileUseCase` y comparte `VehicleCubit` / `AuthCubit` (globales) para garage y sesión.

> Importante: el modelo `UserModel` vive en `lib/features/users/domain/model/`, no en este feature. Profile solo agrega presentación + un use case wrapper.

---

## 2. Modelo de dominio

Profile **no define modelos propios**. Consume:

- `UserModel` — `lib/features/users/domain/model/user_model.dart` (ver `users.md` para detalles).
- `DomainException` — `lib/core/exceptions/domain_exception.dart`.
- `ResultState<UserModel>` — `lib/core/domain/result_state.dart`.

---

## 3. Arquitectura por capas

### 3.1 Domain
```
lib/features/profile/domain/
└── use_cases/
    └── get_my_profile_use_case.dart
```

**`GetMyProfileUseCase`** (`@injectable`):
- Depende de `UserRepository` (feature `users`).
- `call() → Future<Either<DomainException, UserModel>>` — delega en `_userRepository.getCurrentUser()`.

> No hay `repository/` propio. La capa de datos para usuarios está en `lib/features/users/data/`.

---

### 3.2 Presentation
```
lib/features/profile/presentation/
├── cubits/
│   └── profile_cubit.dart
├── profile_page.dart
├── edit_profile_page.dart
└── widgets/
    ├── profile_content.dart
    ├── profile_header.dart
    ├── profile_avatar.dart
    ├── profile_edit_avatar.dart
    ├── profile_stats_row.dart
    ├── profile_stat_cell.dart
    ├── profile_stat_divider.dart
    ├── profile_section_label.dart
    ├── profile_form_section_header.dart
    ├── profile_actions_list.dart
    ├── profile_menu_item.dart
    ├── profile_menu_divider.dart
    ├── profile_garage_section.dart
    └── profile_empty_garage_card.dart
```

---

## 4. Cubit y estados

| Cubit | Archivo | DI | Estado | Notas |
|---|---|---|---|---|
| `ProfileCubit` | `presentation/cubits/profile_cubit.dart` | `@lazySingleton` | `ResultState<UserModel>` | Llamado desde `ProfilePage.initState()` y `ProfileActionsList._logout()` (reset) |

**`ProfileCubit`** — métodos públicos:
```dart
Future<void> fetchProfile()   // emite loading → data | error
void reset()                  // emite initial (usado al cerrar sesión)
```

El cubit es **`@lazySingleton`**, no `@injectable`. Esto significa que la misma instancia se reutiliza durante toda la sesión. Importante para que el logout pueda hacer `reset()` desde fuera de la pantalla y la próxima entrada vea estado limpio.

---

## 5. Estructura de la pantalla

### `ProfilePage` (`profile_page.dart`)

- `StatefulWidget`. En `initState()` llama `context.read<ProfileCubit>().fetchProfile()`.
- `PopScope(canPop: false)` con `onPopInvokedWithResult` que hace `context.goNamed(AppRoutes.home)` — intencional para resetear el back-stack del `StatefulShellRoute` (evita acumulación entre tabs).
- `BlocBuilder<ProfileCubit, ResultState<UserModel>>` con `state.when(...)`:
  - `initial` / `loading` → `PageLoadingStateWidget`
  - `data(user)` → `ProfileContent(user: user)`
  - `empty` → `EmptyStateWidget(icon: person_off_outlined, title: l10n.profile_loadingError)`
  - `error(e)` → `PageErrorStateWidget` con botón retry → `fetchProfile()`

### `ProfileContent` (`widgets/profile_content.dart`)

Composición vertical:

1. **`ProfileHeader`** — avatar con iniciales + nombre (22px bold) + email + city + botón "Editar info" (`pushNamed(AppRoutes.editProfile, extra: user)`).
2. **`ProfileStatsRow`** — 3 celdas (`ProfileStatCell`) con separadores: eventos, km, followers. **Hardcoded a `0`** — sin integración real con backend (TODO).
3. **`ProfileSectionLabel`** — etiqueta "AJUSTES".
4. **`ProfileActionsList`** — tarjeta con `ProfileMenuItem`s separados por `ProfileMenuDivider`:
   - Mis inscripciones → `pushNamed(myRegistrations)`
   - Mis borradores → `pushNamed(myDrafts)`
   - Mantenimientos → `pushNamed(maintenances)`
   - Cerrar sesión (color error, sin chevron) → confirma + `_logout()`

> `ProfileGarageSection` y `ProfileEmptyGarageCard` existen en `widgets/` pero **no se renderizan** en `ProfileContent` actualmente. Quedan como piezas listas para reutilizar si se vuelve a mostrar el garage en el perfil.

### `ProfileHeader`

- Avatar 80–88px con iniciales calculadas por `initialsFromName(user.fullName)` (helper en `lib/core/utils/initials.dart`).
- Renderiza nombre solo si `fullName != null && !empty`.
- Renderiza email solo si `email != null && !empty`.
- Renderiza city con icono `location_on_outlined` solo si `residenceCity != null && !empty`.
- Botón "Editar info" navega con `extra: user` (el editor recibe `UserModel`).

### `ProfileStatsRow`

Props: `eventsLabel`, `kmLabel`, `followersLabel`, `eventsCount=0`, `kmCount=0`, `followersCount=0`. **Los valores `Count` no se pasan en `ProfileContent`** → siempre muestra "0". Considerar conectar a un endpoint en el futuro.

---

## 6. Flujo de edición

### `EditProfilePage` (`edit_profile_page.dart`)

`StatefulWidget` que recibe `UserModel user` por constructor (vía `extra` de GoRouter). Estado local:

```dart
final _formKey = GlobalKey<FormBuilderState>();

void _save() {
  if (_formKey.currentState?.saveAndValidate() ?? false) {
    context.pop();   // ← solo cierra; NO persiste
  }
}
```

**Campos del form** (todos `AppTextField` con `initialValue` desde `widget.user`):

| Sección | Campo | name | keyboardType |
|---|---|---|---|
| Personal | Nombre completo | `fullName` | default, required |
| Personal | Teléfono | `phone` | phone |
| Personal | Ciudad | `residenceCity` | default |
| Personal | Tipo de sangre | `bloodType` | default (recibe `user.bloodType?.name` como string) |
| Emergencia | Contacto emergencia | `emergencyContactName` | default |
| Emergencia | Teléfono emergencia | `emergencyContactPhone` | phone |

**Trampa importante:** `_save()` **NO llama a un use case ni a un endpoint**. Solo valida el form y hace pop. **La edición no persiste a backend ni a `UserModel`.** Pendiente de implementar (TODO).

`bloodType` se renderiza como `AppTextField` con `initialValue: user.bloodType?.name` — es decir, el nombre del enum (ej. "oPositive"). No es ideal UX-wise; debería ser un dropdown con los labels (`'O+'`, etc.).

---

## 7. Logout

`ProfileActionsList._logout()`:

```dart
Future<void> _logout(BuildContext context) async {
  context.read<AuthCubit>().signOut();
  context.read<VehicleCubit>().clearVehicles();
  context.read<ProfileCubit>().reset();
  context.goAndClearStack(AppRoutes.login);
}
```

Pasos:
1. `AuthCubit.signOut()` — Firebase signOut + Google signOut + `AuthService._currentUser = null`. Emite `AuthState.unauthenticated()`.
2. `VehicleCubit.clearVehicles()` — vacía cache local de vehículos.
3. `ProfileCubit.reset()` — emite `ResultState.initial()` para que la próxima entrada al tab muestre loading limpio.
4. `context.goAndClearStack(AppRoutes.login)` — extensión que reemplaza toda la pila por `/login` (definida en `lib/core/extensions/go_router.dart`).

Antes del logout se muestra `ConfirmationDialog.show(...)` con `dialogType: warning` y `confirmType: danger`.

---

## 8. Rutas de navegación

| Ruta | Constante | Página | Params |
|---|---|---|---|
| `/profile` | `AppRoutes.profile` | `ProfilePage` | — |
| `/profile/edit` | `AppRoutes.editProfile` | `EditProfilePage` | `extra: UserModel` (required) |

Profile vive dentro del cuarto `StatefulShellBranch` (índice 3) del `StatefulShellRoute.indexedStack` definido en `app_router.dart`. Por eso `PopScope` redirige al `home` en lugar de hacer pop nativo (mantener UX consistente entre tabs).

**Navegaciones salientes:**
- `pushNamed(editProfile, extra: user)` → editor
- `pushNamed(myRegistrations)` → lista de inscripciones
- `pushNamed(myDrafts)` → borradores de eventos
- `pushNamed(maintenances)` → mantenimientos (todos los vehículos)
- `goAndClearStack(login)` → al hacer logout

---

## 9. API endpoints

Profile no llama directamente a la API. Indirectamente, vía `GetMyProfileUseCase`:

| Método | Endpoint | Descripción |
|---|---|---|
| `GET` | `/users/me` | Trae el `UserModel` actual del usuario autenticado |

Definido en `ApiRoutes.me` (`lib/core/http/api_routes.dart`).

---

## 10. Conexiones con otros features

| Feature | Cómo se conecta |
|---|---|
| `users` | Consume `UserModel`, `UserRepository`. `GetMyProfileUseCase` envuelve `UserRepository.getCurrentUser()` |
| `authentication` | `AuthCubit.signOut()` se invoca desde `ProfileActionsList`. `AuthCubit.currentUser` se lee como fallback si el cubit aún no tiene datos |
| `vehicles` | `VehicleCubit.clearVehicles()` al logout. `ProfileGarageSection` (no montado) lee `currentVehicle` del `VehicleCubit` |
| `event_registration` | Menu item navega a `myRegistrations` |
| `events` (drafts) | Menu item navega a `myDrafts` |
| `maintenance` | Menu item navega a `maintenances` (sin `initialVehicleId` → muestra todos) |

---

## 11. Patrones y trampas conocidas

### `EditProfilePage._save()` no persiste cambios
El método valida el form y hace `context.pop()` sin llamar a un use case. **Si el usuario edita su perfil, los cambios se pierden.** TODO: integrar con `UpdateUserUseCase` (que no existe aún en `users/`).

### Stats hardcoded a 0
`ProfileStatsRow` usa los defaults (`eventsCount = 0`, `kmCount = 0`, `followersCount = 0`) en `ProfileContent`. Pendiente conectar a backend.

### `ProfileGarageSection` no montado
Existe en `widgets/` pero no se renderiza en `ProfileContent`. Es una pieza de UI lista para uso futuro (mostrar el vehículo principal en el perfil).

### `bloodType` como TextField libre
En `EditProfilePage`, `bloodType` es un `AppTextField` con `initialValue: user.bloodType?.name`. Esto produce el nombre del enum (ej. `"oPositive"`), no el label (`"O+"`). Cuando se implemente persistencia, conviene reemplazar por `AppDropdown` con `BloodType.values`.

### `PopScope` redirige a `/home` en lugar de hacer pop normal
Es intencional: `ProfilePage` vive dentro de `StatefulShellRoute.indexedStack`, y un pop nativo podría desalinear el índice del shell. La redirección a `/home` resetea la pila del tab al estado inicial.

### `ProfileCubit` es `@lazySingleton`, no `@injectable`
Cambiarlo a `@injectable` rompería el `reset()` desde `ProfileActionsList._logout()` (la siguiente instancia no recordaría el reset). El `@lazySingleton` garantiza que el ciclo de vida del cubit cubra logouts/relogins.

### `BlocBuilder<VehicleCubit, dynamic>` en `ProfileGarageSection`
El builder usa `dynamic` como tipo de estado en lugar del tipo concreto (`ResultState<List<VehicleModel>>`). Es una concesión: el widget no necesita el state, solo lee `vehicleCubit.currentVehicle` directamente. Sigue funcionando, pero deshabilita el chequeo de tipos del `BlocBuilder`.

### Las stats `kmLabel` deberían pluralizarse
Hoy el label es estático. Si los datos llegan, considerar `Intl.plural()` para "0 km" vs "1 km" vs "N km".

---

## 12. Archivos clave de referencia rápida

| Qué buscar | Archivo |
|---|---|
| Use case de carga | `lib/features/profile/domain/use_cases/get_my_profile_use_case.dart` |
| Cubit | `lib/features/profile/presentation/cubits/profile_cubit.dart` |
| Pantalla del perfil | `lib/features/profile/presentation/profile_page.dart` |
| Pantalla de edición | `lib/features/profile/presentation/edit_profile_page.dart` |
| Composición principal | `lib/features/profile/presentation/widgets/profile_content.dart` |
| Header con avatar | `lib/features/profile/presentation/widgets/profile_header.dart` |
| Acciones (incluido logout) | `lib/features/profile/presentation/widgets/profile_actions_list.dart` |
| Iniciales | `lib/core/utils/initials.dart` |
| Modelo de usuario | `lib/features/users/domain/model/user_model.dart` |
| Repositorio de usuario | `lib/features/users/domain/repository/user_repository.dart` |
