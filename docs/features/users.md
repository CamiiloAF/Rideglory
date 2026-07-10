# Documentación del Feature: Users

> Última actualización: 2026-07-04
> Alcance: `lib/features/users/`

---

## Tabla de contenido

1. [Visión general](#1-visión-general)
2. [Modelo de dominio](#2-modelo-de-dominio)
3. [Arquitectura por capas](#3-arquitectura-por-capas)
   - 3.1 [Domain](#31-domain)
   - 3.2 [Data](#32-data)
   - 3.3 [Presentation](#33-presentation)
4. [Cubit y estados](#4-cubit-y-estados)
5. [Persistencia local](#5-persistencia-local)
6. [Rutas de navegación](#6-rutas-de-navegación)
7. [API endpoints](#7-api-endpoints)
8. [Conexiones con otros features](#8-conexiones-con-otros-features)
9. [Patrones y trampas conocidas](#9-patrones-y-trampas-conocidas)
10. [Archivos clave de referencia rápida](#10-archivos-clave-de-referencia-rápida)

---

## 1. Visión general

El feature **Users** define al usuario de la app:

- **`UserModel`** — modelo único compartido por toda la app (authentication, profile, splash, event_registration).
- **`UserRepository`** — contrato para registrar, obtener "me" y obtener cualquier usuario por id.
- **`RiderProfilePage`** — pantalla pública del perfil de **otro rider** (no del propio); usada desde la lista de asistentes.

No tiene cubits para "mi propio perfil"; el feature `profile` se encarga de eso (lee del mismo `UserRepository` via su propio `GetMyProfileUseCase`). Tampoco tiene endpoint de update (la edición del perfil propio aún no persiste, ver `profile.md`).

---

## 2. Modelo de dominio

### `UserModel`
> `lib/features/users/domain/model/user_model.dart`

```
UserModel
  id: String                  (requerido)
  fullName: String?
  email: String?
  identificationNumber: String?
  birthDate: DateTime?
  phone: String?
  residenceCity: String?
  eps: String?
  medicalInsurance: String?
  bloodType: BloodType?       — enum importado del feature event_registration
  emergencyContactName: String?
  emergencyContactPhone: String?
  isDeleted: bool             (default false)
  createdAt: DateTime?
  updatedAt: DateTime?
```

Es un POJO simple: sin getters calculados, sin `copyWith` (no se necesita porque el modelo no se muta en la app — la edición no está integrada al backend aún), sin igualdad personalizada.

### `BloodType` (enum)

Declarado en **`lib/features/event_registration/domain/model/event_registration_model.dart`** (no en `users`):

| Enum | JsonValue | Label |
|---|---|---|
| `aPositive` | `'A_POSITIVE'` | A+ |
| `aNegative` | `'A_NEGATIVE'` | A- |
| `bPositive` | `'B_POSITIVE'` | B+ |
| `bNegative` | `'B_NEGATIVE'` | B- |
| `abPositive` | `'AB_POSITIVE'` | AB+ |
| `abNegative` | `'AB_NEGATIVE'` | AB- |
| `oPositive` | `'O_POSITIVE'` | O+ |
| `oNegative` | `'O_NEGATIVE'` | O- |

`UserModel` lo importa cross-feature. Es deuda técnica menor — debería vivir en `core/domain` o en `users/domain/enums`.

### `AuthenticatedUser`
> `lib/core/services/models/authenticated_user.dart`

Modelo auxiliar que **no** vive en `users` pero combina Firebase + API:
```
firebaseUser: User           (firebase_auth)
user: UserModel?
isNewUser: bool
```
Retornado por `AuthService.signUpWithEmail`, `signInWithGoogle`, etc.

---

## 3. Arquitectura por capas

### 3.1 Domain
```
lib/features/users/domain/
├── model/
│   └── user_model.dart
├── repository/
│   └── user_repository.dart
└── use_cases/
    ├── get_user_by_id_use_case.dart
    └── get_current_user_id_use_case.dart
```

**`UserRepository`** (interface):
```dart
Future<Either<DomainException, UserModel>> registerUser({
  required String fullName,
  required String email,
});

Future<Either<DomainException, UserModel>> getCurrentUser();

Future<Either<DomainException, UserModel>> getUserById(String userId);
```

**Use cases (todos `@injectable`):**

| Use case | Signature | Notas |
|---|---|---|
| `GetUserByIdUseCase` | `call(String userId) → Future<Either<DomainException, UserModel>>` | Delega al repository |
| `GetCurrentUserIdUseCase` | `call() → Future<Either<DomainException, String>>` | Delega a **`AuthService.getCurrentUserId()`**, no al repository |

> `GetCurrentUserIdUseCase` no usa `UserRepository` — usa `AuthService` directamente. Es atípico para el patrón Clean Architecture pero práctico: el id viene del `AuthService` que mantiene el currentUser cacheado.

> **No hay `UpdateUserUseCase` ni `DeleteUserUseCase`**. Si se implementa edición de perfil persistida, hay que agregar el método al repository + use case + endpoint.

---

### 3.2 Data
```
lib/features/users/data/
├── dto/
│   ├── user_dto.dart
│   ├── user_dto.g.dart
│   └── create_user_dto.dart
├── repository/
│   └── user_repository_impl.dart
└── service/
    ├── user_service.dart
    └── user_service.g.dart
```

**`UserDto extends UserModel`** (`@JsonSerializable(converters: apiJsonDateTimeConverters)`):
- Hereda todos los campos del modelo.
- `factory UserDto.fromJson(...)` (generado).
- `factory UserDto.fromModel(UserModel)` — mapea manualmente cada campo.
- `toJson()` — generado.

> Mismo patrón "DTO hereda de Model" que `VehicleDto` y `EventDto`. Útil para evitar `.toModel()` adicional pero acopla el dominio al data layer.

**`CreateUserDto`** — DTO ligero solo para signup:
```dart
class CreateUserDto {
  final String fullName;
  final String email;
  Map<String, dynamic> toJson() => {'fullName': fullName, 'email': email};
}
```
Serialización manual (no `@JsonSerializable`).

**`UserService` (Retrofit)**:
```dart
@POST(ApiRoutes.signUp)               // /users/sign-up
Future<UserDto> signUp(@Body() Map<String, dynamic> request);

@GET(ApiRoutes.me)                    // /users/me
Future<UserDto> getCurrentUser();

@GET('/users/{id}')
Future<UserDto> getUserById(@Path('id') String id);
```

> El path de `getUserById` está hardcoded (`'/users/{id}'`), no usa `ApiRoutes`. Considerar agregar la constante.

**`UserRepositoryImpl`** (`@Injectable(as: UserRepository)`):
- Usa `executeService()` para mapear errores HTTP a `DomainException`.
- `registerUser()` envía `CreateUserDto(fullName, email).toJson()` al endpoint.
- `getCurrentUser()` y `getUserById(id)` delegan directo al service.

---

### 3.3 Presentation
```
lib/features/users/presentation/
├── cubit/
│   └── rider_profile_cubit.dart
├── pages/
│   └── rider_profile_page.dart
└── widgets/
    ├── rider_profile_content.dart
    ├── rider_avatar.dart
    ├── rider_stat_cell.dart
    ├── rider_stats_row.dart
    ├── rider_profile_loading.dart    (shimmer skeleton)
    └── rider_profile_error.dart      (mensaje + retry)
```

---

## 4. Cubit y estados

| Cubit | Archivo | DI | Estado |
|---|---|---|---|
| `RiderProfileCubit` | `cubit/rider_profile_cubit.dart` | `@injectable` | `ResultState<UserModel>` |

**Métodos:**
```dart
Future<void> fetchRiderProfile(String userId) async {
  emit(const ResultState.loading());
  final result = await _getUserByIdUseCase(userId);
  result.fold(
    (error) => emit(ResultState.error(error: error)),
    (user)  => emit(ResultState.data(data: user)),
  );
}
```

Único método público. Se crea por instancia (no singleton), una por `RiderProfilePage`.

### `RiderProfilePage`

`StatelessWidget` que recibe `userId: String` por constructor (vía `extra` de GoRouter).

```dart
return BlocProvider(
  create: (_) => getIt<RiderProfileCubit>()..fetchRiderProfile(userId),
  child: Scaffold(
    appBar: AppAppBar(title: context.l10n.rider_profileTitle),
    body: BlocBuilder<RiderProfileCubit, ResultState<UserModel>>(
      builder: (context, state) {
        return state.when(
          initial:  () => PageLoadingStateWidget(),
          loading:  () => RiderProfileLoading(),
          data:     (user) => RiderProfileContent(user: user),
          empty:    () => RiderProfileLoading(),       // ← cae a loading si vacío
          error:    (error) => RiderProfileError(
            message: error.message,
            onRetry: () => context.read<RiderProfileCubit>().fetchRiderProfile(userId),
          ),
        );
      },
    ),
  ),
);
```

### `RiderProfileContent`

Estructura visual (todo center-aligned):
1. `RiderAvatar(initials)` — círculo 88px con gradient primary y iniciales.
2. `fullName` (22px bold).
3. `email` — **ya NO se muestra en el perfil de otro usuario** (commit `6cbd85c`, "ocultar email en perfil ajeno"). El email solo es visible en el propio perfil (`profile.md`).
4. `residenceCity` con icono `location_on_outlined` — opcional.
5. `RiderStatsRow` — 3 celdas: events, followers, following. **Todas hardcoded a "0"**.
6. Botón "Seguir" — al tocarlo abre un bottom sheet "Próximamente" (commit `6cbd85c`); no realiza ninguna acción de follow/unfollow real.

> El botón "Seguir" no ejecuta una acción de follow real: solo informa al usuario que la funcionalidad llegará más adelante. Sin endpoint de follow/unfollow ni cubit que lo maneje todavía.

---

## 5. Persistencia local

### `UserStorageService`
> `lib/core/services/user_storage_service.dart` (no vive en `users/` pero es parte del flujo)

`@injectable`. Usa **`FlutterSecureStorage`** (keychain en iOS, keystore en Android), no `SharedPreferences`. Key format: `api_user_{firebaseUid}`.

```dart
Future<void> saveUser({required String firebaseUid, required UserModel user}) {
  return _storage.write(
    key: 'api_user_$firebaseUid',
    value: jsonEncode(UserDto.fromModel(user).toJson()),
  );
}

Future<UserModel?> getUser(String firebaseUid) async {
  final rawUser = await _storage.read(key: 'api_user_$firebaseUid');
  if (rawUser == null || rawUser.isEmpty) return null;
  final json = jsonDecode(rawUser);
  if (json is! Map<String, dynamic>) return null;
  return UserDto.fromJson(json);
}
```

**JSON shape persistido:**
```json
{
  "id": "...",
  "fullName": "...",
  "email": "...",
  "identificationNumber": "...",
  "birthDate": "1990-05-15T00:00:00.000Z",
  "phone": "...",
  "residenceCity": "...",
  "eps": "...",
  "medicalInsurance": "...",
  "bloodType": "O_POSITIVE",
  "emergencyContactName": "...",
  "emergencyContactPhone": "...",
  "isDeleted": false,
  "createdAt": "...",
  "updatedAt": "..."
}
```

**Consumido por `AuthService`** (línea 237-255 de `auth_service.dart`):

- `_cacheUser(firebaseUid, user)` — almacena en memoria + storage.
- `_loadStoredUser(firebaseUid)` — lee del storage; si no existe, hace fallback a `_userRepository.getCurrentUser()` y cachea.

Esto evita un GET `/users/me` en cada arranque si el storage tiene cache válido.

---

## 6. Rutas de navegación

| Ruta | Constante | Página | Extra |
|---|---|---|---|
| `/events/attendees/rider-profile` | `AppRoutes.riderProfile` | `RiderProfilePage(userId: extra as String)` | `String` (userId) |

> La ruta vive bajo `/events/attendees/`, no `/users/`, porque el único caso de uso es ver el perfil de un asistente desde un evento.

Otras rutas relacionadas con usuario están en otros features:
- `/profile` y `/profile/edit` → feature `profile` (no este).

---

## 7. API endpoints

| Método | Endpoint | Use case | Body / Response |
|---|---|---|---|
| `POST` | `/users/sign-up` | `AuthService._registerApiUser` | Body: `{fullName, email}` → `UserDto` |
| `GET` | `/users/me` | `UserRepository.getCurrentUser` | → `UserDto` |
| `GET` | `/users/{id}` | `UserRepository.getUserById` | → `UserDto` |
| `DELETE` | `/users/me` | `UserRepository.deleteMyAccount` (`DeleteAccountUseCase`) | Sin body → `204 No Content`. Hard delete irreversible (`eliminacion-cuenta-phase-01`); ver `profile.md` §7.1 para el estado del flujo de UI (bloqueado por diseño). |

Constantes: `ApiRoutes.signUp = '/users/sign-up'`, `ApiRoutes.me = '/users/me'`. El path `/users/{id}` está hardcoded en `UserService`.

---

## 8. Conexiones con otros features

| Feature | Conexión |
|---|---|
| `authentication` | `AuthService` consume `UserRepository.registerUser()` y `getCurrentUser()`. `AuthState.currentUser` retorna `UserModel?` |
| `profile` | `GetMyProfileUseCase` (en `profile/domain/`) envuelve `UserRepository.getCurrentUser()`. Edición de perfil aún no persiste |
| `splash` | `LoadCurrentUserUseCase` → `AuthService.loadCurrentUser()` → `UserStorageService.getUser()` o `UserRepository.getCurrentUser()` |
| `event_registration` | `RegistrationFormCubit._prefillFromAuthenticatedUser` lee de `AuthService.currentUser`. `BloodType` enum se declara aquí |
| `events` (attendees) | Tap en asistente navega a `riderProfile` con `userId` |

---

## 9. Patrones y trampas conocidas

### `BloodType` declarado fuera de `users`
Vive en `lib/features/event_registration/domain/model/event_registration_model.dart`. Cross-feature import. Si refactorizas, considerar moverlo a `core/domain/enums/blood_type.dart` y actualizar imports.

### `UserDto extends UserModel`
Hereda y suma JSON serialization. Mismo patrón que `VehicleDto`/`EventDto`. Útil pero acopla DTO al dominio. Cuidado al separar capas.

### Sin update endpoint ni use case
La edición de perfil propio (en `feature profile`) no persiste a backend porque no existe ni `updateUser` en `UserRepository` ni endpoint `PATCH /users/me`. Pendiente.

### `FlutterSecureStorage` para el usuario
A diferencia de `SharedPreferences`, el storage usa keychain/keystore. **No es plain text**. Las operaciones son async. Si se cambia a SharedPreferences, ajustar `auth_service.dart` y `user_storage_service.dart`.

### Stats hardcoded en UI
`RiderStatsRow` siempre muestra "0/0/0". El modelo no tiene campos para events/followers/following. Si se quiere implementar, agregar al backend + modelo.

### Botón "Seguir" muestra bottom sheet "Próximamente"
No ejecuta follow/unfollow real; abre un bottom sheet informativo. Sin endpoint follow/unfollow. Si se implementa, considerar agregar `FollowCubit` o similar.

### Email oculto en perfil ajeno
`RiderProfileContent` ya no renderiza el `email` del `UserModel` (commit `6cbd85c`). Es una decisión de privacidad: el email solo debe verse en el perfil propio (`profile.md`), nunca en el de otro rider.

### `GetCurrentUserIdUseCase` delega a `AuthService`
Atípico para Clean Architecture, pero práctico. El `AuthService` mantiene el `currentUser` cacheado en memoria. Si se quiere desacoplar, hay que exponerlo via repository.

### `getUserById` hardcoded en service
El path `'/users/{id}'` no usa `ApiRoutes`. Agregar `ApiRoutes.userById(id)` por consistencia.

### `RiderProfileCubit` no maneja `Empty`
`state.when(empty: () => RiderProfileLoading())` reusa el widget de loading. En la práctica, `RiderProfileCubit` nunca emite `empty` (siempre data o error), pero la rama existe por la firma de `state.when`. Considerar `orElse` o un widget dedicado.

### `UserModel` sin `copyWith` ni igualdad
No es freezed. La app no necesita mutar `UserModel` localmente porque la edición no está persistida. Si se agrega edición optimistic, agregar `copyWith` + igualdad.

### `AuthenticatedUser` vive en `core/services/models/`
No en `users/domain/model/`. Es razonable porque envuelve un `User` de Firebase, pero si crece, mover a `users/domain/` para consistencia.

---

## 10. Archivos clave de referencia rápida

| Qué buscar | Archivo |
|---|---|
| Modelo de usuario | `lib/features/users/domain/model/user_model.dart` |
| BloodType enum | `lib/features/event_registration/domain/model/event_registration_model.dart` |
| Repository interface | `lib/features/users/domain/repository/user_repository.dart` |
| Use case getById | `lib/features/users/domain/use_cases/get_user_by_id_use_case.dart` |
| Use case getCurrentUserId | `lib/features/users/domain/use_cases/get_current_user_id_use_case.dart` |
| DTO user | `lib/features/users/data/dto/user_dto.dart` |
| DTO de creación | `lib/features/users/data/dto/create_user_dto.dart` |
| Service Retrofit | `lib/features/users/data/service/user_service.dart` |
| Repository impl | `lib/features/users/data/repository/user_repository_impl.dart` |
| Cubit del perfil de rider | `lib/features/users/presentation/cubit/rider_profile_cubit.dart` |
| Página de rider | `lib/features/users/presentation/pages/rider_profile_page.dart` |
| Contenido (avatar + stats) | `lib/features/users/presentation/widgets/rider_profile_content.dart` |
| Skeleton loading | `lib/features/users/presentation/widgets/rider_profile_loading.dart` |
| AuthService (consume UserRepository) | `lib/core/services/auth_service.dart` |
| Persistencia local segura | `lib/core/services/user_storage_service.dart` |
| AuthenticatedUser model | `lib/core/services/models/authenticated_user.dart` |
| Endpoints API | `lib/core/http/api_routes.dart` (`signUp`, `me`) |
