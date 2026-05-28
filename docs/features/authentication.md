# Documentación del Feature: Authentication

> Última actualización: 2026-05-28  
> Alcance: `lib/features/authentication/`

---

## Tabla de contenido

1. [Visión general](#1-visión-general)
2. [Modelo de dominio](#2-modelo-de-dominio)
3. [Arquitectura por capas](#3-arquitectura-por-capas)
   - 3.1 [Application — AuthCubit / AuthState](#31-application--authcubit--authstate)
   - 3.2 [Constants](#32-constants)
   - 3.3 [Login](#33-login)
   - 3.4 [Signup](#34-signup)
   - 3.5 [Widgets compartidos](#35-widgets-compartidos)
4. [Cubit y estados](#4-cubit-y-estados)
5. [Flujo de login](#5-flujo-de-login)
6. [Flujo de signup](#6-flujo-de-signup)
7. [Flujo de password reset](#7-flujo-de-password-reset)
8. [Validaciones](#8-validaciones)
9. [Rutas de navegación](#9-rutas-de-navegación)
10. [Conexiones con otros features](#10-conexiones-con-otros-features)
11. [Patrones y trampas conocidas](#11-patrones-y-trampas-conocidas)
12. [Archivos clave de referencia rápida](#12-archivos-clave-de-referencia-rápida)

---

## 1. Visión general

El feature **Authentication** gestiona el ingreso a la app:

- **Login** con email/password, Google, o Apple.
- **Signup** con email/password (con validaciones fuertes de contraseña).
- **Password reset** vía correo electrónico de Firebase.
- **Sign-out** y limpieza de sesión.
- **Estado global** de autenticación (`AuthCubit` `@singleton` consumido por toda la app).

El feature **no tiene capa `data/`** propia: delega en `AuthService` (`lib/core/services/auth_service.dart`) que es quien habla con Firebase Auth, `UserRepository` (feature `users`) y `UserStorageService`. La estructura es atípica (no sigue `domain/data/presentation`); usa `application/` para el cubit + estado, más `login/`, `signup/` y `presentation/` con widgets.

> Apple sign-in está **stub**: `AuthService.signInWithApple()` retorna `Left(DomainException('Apple sign-in no está disponible en esta versión'))`. El botón existe en UI pero falla inmediatamente.

---

## 2. Modelo de dominio

Authentication no define modelos de dominio propios. Consume:

- `UserModel` — `lib/features/users/domain/model/user_model.dart` (resultado de signup/login).
- `AuthenticatedUser` — `lib/core/services/models/authenticated_user.dart` (envuelve `User` de Firebase + `UserModel`).
- `DomainException` — `lib/core/exceptions/domain_exception.dart`.
- `AuthException` — `lib/core/exceptions/auth_exception.dart` (capturada en `signOut`).

---

## 3. Arquitectura por capas

### 3.1 Application — AuthCubit / AuthState
```
lib/features/authentication/application/
├── auth_cubit.dart
└── auth_state.dart       (part of auth_cubit.dart)
```

`AuthCubit` es `@singleton` y se inyecta globalmente en `main.dart` (root `MultiBlocProvider`). `AuthState` es **sealed class manual**, no freezed: el archivo declara 6 fábricas y 6 implementaciones internas (`_Initial`, `_Loading`, `_Authenticated`, `_Unauthenticated`, `_Error`, `_PasswordResetEmailSent`).

### 3.2 Constants
```
lib/features/authentication/constants/
└── auth_form_fields.dart    (clase no instanciable con 5 constantes)
```

### 3.3 Login
```
lib/features/authentication/login/presentation/
├── login_view.dart
├── forgot_password_view.dart
└── widgets/
    ├── login_brand_header.dart
    ├── login_heading.dart
    ├── login_form.dart
    ├── login_divider.dart
    ├── login_social_section.dart
    ├── login_social_button.dart
    ├── login_register_row.dart
    ├── forgot_password_form.dart
    ├── forgot_password_heading.dart
    ├── forgot_password_back_button.dart
    ├── forgot_password_email_field.dart
    ├── forgot_password_send_button.dart
    ├── forgot_password_back_to_login_link.dart
    ├── forgot_password_email_sent_content.dart
    └── forgot_password_email_sent_icon.dart
```

### 3.4 Signup
```
lib/features/authentication/signup/presentation/
├── signup_view.dart
└── widgets/
    ├── signup_heading.dart
    ├── signup_top_bar.dart
    ├── signup_form.dart
    ├── signup_sign_in_row.dart
    ├── signup_terms_checkbox.dart
    └── signup_terms_text.dart
```

### 3.5 Widgets compartidos
```
lib/features/authentication/presentation/widgets/
├── signup_header.dart            (no usado en árbol actual)
├── login_email_form.dart         (alternativa a login_form, no usado en LoginView)
├── signup_email_form.dart        (alternativa a signup_form, no usado en SignupView)
├── social_login_button.dart      (versión genérica, no usada en LoginView/SignupView)
├── signup_social_buttons.dart    (Column de 3 SocialLoginButton)
├── divider_with_text.dart
└── auth_text_with_link.dart
```

> Hay **dos generaciones** de widgets de login/signup: las que están en `login/widgets/` y `signup/widgets/` se usan actualmente; las de `presentation/widgets/` son alternativas que quedaron en el repo. Verificar antes de modificar para no editar el archivo equivocado.

---

## 4. Cubit y estados

| Cubit | Archivo | DI | Estado base |
|---|---|---|---|
| `AuthCubit` | `application/auth_cubit.dart` | `@singleton` | `AuthState` (sealed class manual) |

**`AuthState`** — 6 casos:

```dart
sealed class AuthState {
  const factory AuthState.initial()                  = _Initial;
  const factory AuthState.loading()                  = _Loading;
  const factory AuthState.authenticated(UserModel? user) = _Authenticated;
  const factory AuthState.unauthenticated()          = _Unauthenticated;
  const factory AuthState.error(String message)      = _Error;
  const factory AuthState.passwordResetEmailSent()   = _PasswordResetEmailSent;

  bool get isAuthenticated;
  bool get isLoading;
  bool get hasError;
  bool get isPasswordResetEmailSent;
  String? get errorMessage;
  UserModel? get currentUser;     // null si no es _Authenticated
}
```

**Métodos públicos del cubit** (todos emiten `loading` → resultado, salvo `checkAuthState` y `signOut`):

| Método | Signature | Inicializa FCM al éxito |
|---|---|---|
| `checkAuthState()` | `void` | sí (si autenticado) |
| `signUpWithEmail({fullName, email, password})` | `Future<void>` | sí |
| `signInWithEmail({email, password})` | `Future<void>` | sí |
| `signInWithGoogle()` | `Future<void>` | sí |
| `signInWithApple()` | `Future<void>` | sí (pero stub falla siempre) |
| `signOut()` | `Future<void>` | — |
| `sendPasswordResetEmail(String email)` | `Future<void>` | — |

**Token debug en consola:** `_printFirebaseToken(User)` se invoca solo en `kDebugMode` y solo en `signUpWithEmail`, `signInWithEmail`, `signInWithGoogle` (no en Apple). Logea el `idToken` con `dart:developer log()`.

**Inyecciones:**
- `AuthService` — wrapper de Firebase Auth + Google Sign-In.
- `FcmService` — registra el token FCM tras autenticarse (`.initialize().ignore()`, fire-and-forget).

---

## 5. Flujo de login

### `LoginView` (`login/presentation/login_view.dart`)

`StatefulWidget` con `_formKey: GlobalKey<FormBuilderState>` y flag local `_emailLoading: bool`.

**Estructura visual (top → bottom):**
1. Top padding 48px.
2. `LoginBrandHeader` — texto "RIDEGLORY" + tagline "Connect. Ride. Explore.".
3. `LoginHeading` — título + subtítulo.
4. `LoginForm` — campos + botón.
5. `LoginDivider` — divisor con "o continúa con".
6. `LoginSocialSection` — Google + Apple.
7. `LoginRegisterRow` — "¿No tienes cuenta? Regístrate".

**Listener:**
```dart
BlocListener<AuthCubit, AuthState>(
  listener: (context, state) {
    if (state.isAuthenticated) context.pushReplacementNamed(AppRoutes.home);
    if (state.hasError) ScaffoldMessenger.of(context).showSnackBar(...);
  },
)
```

**Back físico:** `PopScope(canPop: false, onPopInvokedWithResult: ...)` muestra diálogo "¿Salir de la app?" con `SystemNavigator.pop()` al confirmar — login es la pantalla inicial autenticada, atrás cierra app.

### `LoginForm` (`login/presentation/widgets/login_form.dart`)

- **Email**: `AppTextField(name: AuthFormFields.email)` con validadores `[required, email]`.
- **Password**: `AppPasswordTextField(name: AuthFormFields.password)` con `[required, minLength(6)]`.
- **Forgot password**: `AppTextButton` que hace `pushNamed(AppRoutes.forgotPassword)`.
- **Botón principal**: `AppButton` con `isLoading: state.isLoading`. Al pulsar, valida y llama `context.read<AuthCubit>().signInWithEmail(...)`.

### `LoginSocialSection`

`StatefulWidget` con `_loadingProvider: LoginAuthProvider?` (enum `{google, apple}`). Cuando un proveedor está cargando, deshabilita el otro. Cada botón es un `LoginSocialButton` con su `backgroundColor`, `textColor` e icono propios:

| Proveedor | Color fondo | Color texto | Icono | Cubit call |
|---|---|---|---|---|
| Google | blanco | negro | `Icons.g_mobiledata_rounded` | `signInWithGoogle()` |
| Apple | negro | blanco | `Icons.apple` | `signInWithApple()` (stub) |

---

## 6. Flujo de signup

### `SignupView` (`signup/presentation/signup_view.dart`)

`StatefulWidget`. Estructura:

1. Top padding 24px.
2. `SignupTopBar` — `AppCircleIconButton.back(hasBorder: true)` → `pop()`.
3. `SignupHeading`.
4. `SignupForm`.
5. `SignupSignInRow` — "¿Ya tienes cuenta? Inicia sesión" → `pop()`.

**Listener:** igual que login — al autenticarse → `pushReplacementNamed(home)`; al error → snackbar.

### `SignupForm` (`signup/presentation/widgets/signup_form.dart`)

`StatefulWidget` con 4 `FocusNode` (fullName, email, password, confirmPassword) y estado local `_termsAccepted: bool`.

**Campos:**

| Campo | Validators | KB type | Action |
|---|---|---|---|
| `fullName` | `[required, minLength(3)]` | text | next |
| `email` | `[required, email]` | email | next |
| `password` | `[required, minLength(8), match(/[A-Z]/), match(/[0-9]/)]` | text | next |
| `confirmPassword` | `[required, custom: match password value]` | text | done → submit |

**Términos:** `SignupTermsCheckbox` (no es un `FormBuilderField`, es estado local `_termsAccepted`). Si no aceptado al submit, snackbar rojo con error.

**Botón submit:** `AppButton` con `isLoading: state.isLoading`. Llama `context.read<AuthCubit>().signUpWithEmail(...)`.

### Validación de password — asimetría intencional

| Pantalla | Política |
|---|---|
| Login | min 6 caracteres |
| Signup | min 8 + al menos 1 mayúscula + al menos 1 número |

Es intencional: en login no se rebaja la barrera para usuarios con passwords legacy.

---

## 7. Flujo de password reset

### `ForgotPasswordView` (`login/presentation/forgot_password_view.dart`)

`StatefulWidget` con dos pantallas alternas:

- Si `!_sent`: renderiza `ForgotPasswordForm` (campo email + botón "Enviar").
- Si `_sent`: renderiza `ForgotPasswordEmailSentContent` con el email guardado + botón "Volver al inicio" y "Reenviar".

**Listener:**
```dart
BlocListener<AuthCubit, AuthState>(
  listener: (context, state) {
    if (state.isPasswordResetEmailSent) setState(() { _sent = true; _sentEmail = ...; });
    if (state.hasError) ScaffoldMessenger.showSnackBar(...);
  },
)
```

**Flujo:**
1. `ForgotPasswordEmailField` (validators `[required, email]`).
2. `ForgotPasswordSendButton` (`BlocBuilder` para `isLoading`).
3. Submit → `context.read<AuthCubit>().sendPasswordResetEmail(email)`.
4. Backend Firebase envía el correo. AuthCubit emite `passwordResetEmailSent`.
5. UI cambia a `ForgotPasswordEmailSentContent` mostrando el email enviado y opción de reenviar.

---

## 8. Validaciones

Toda la validación usa `form_builder_validators` excepto la confirmación de password (validator custom):

```dart
FormBuilderValidators.required(errorText: ...)
FormBuilderValidators.email(errorText: ...)
FormBuilderValidators.minLength(N, errorText: ...)
FormBuilderValidators.match(RegExp('[A-Z]'), errorText: ...)   // signup
FormBuilderValidators.match(RegExp('[0-9]'), errorText: ...)   // signup
```

**Confirm password validator** (`signup_form.dart`):
```dart
(value) {
  final passwordValue = widget.formKey.currentState
      ?.fields[AuthFormFields.password]
      ?.value as String?;
  if (value != passwordValue) return context.l10n.auth_passwordsDoNotMatch;
  return null;
}
```

**Manejo de errores en UI:**
- `AppTextField`/`AppPasswordTextField` muestran `errorText` inline debajo del input.
- `AuthState.error(message)` se traduce en `ScaffoldMessenger.showSnackBar` con `backgroundColor: AppColors.error`. El texto sale de `state.errorMessage` o fallback `context.l10n.errorOccurred`.

---

## 9. Rutas de navegación

| Ruta | Constante | Página | Params |
|---|---|---|---|
| `/login` | `AppRoutes.login` | `LoginView` | — |
| `/signup` | `AppRoutes.signup` | `SignupView` | — |
| `/forgot-password` | `AppRoutes.forgotPassword` | `ForgotPasswordView` | — |

Las tres son **rutas públicas** según el guard `redirect` de `AppRouter` (`lib/shared/router/app_router.dart`): se permiten sin sesión.

**Navegaciones salientes:**
- Login OK / Signup OK → `pushReplacementNamed(AppRoutes.home)`
- Login → "Regístrate" → `pushNamed(signup)`
- Login → "¿Olvidaste tu contraseña?" → `pushNamed(forgotPassword)`
- Signup back / Sign-in row → `pop()`
- ForgotPassword back / "Volver al inicio" → `pop()`

---

## 10. Conexiones con otros features

| Feature | Conexión |
|---|---|
| `core/services/auth_service` | El cubit delega TODO a `AuthService` (Firebase Auth + Google Sign-In + cache local de `UserModel`) |
| `core/services/fcm_service` | Se inicializa post-autenticación (excepto en `signOut` y `sendPasswordResetEmail`) |
| `users` | `AuthService` consume `UserRepository.registerUser()` y `UserRepository.getCurrentUser()`; `UserStorageService` persiste `UserModel` |
| `splash` | `LoadCurrentUserUseCase` invoca `AuthService.loadCurrentUser()` al arrancar |
| `profile` | `ProfileActionsList._logout()` llama `AuthCubit.signOut()` |
| `notifications` | El `FcmService.initialize()` post-login obtiene/registra el token FCM (consume `RegisterFcmTokenUseCase`) |

---

## 11. Patrones y trampas conocidas

### `AuthState` es **sealed class manual**, no freezed
Las otras features usan `@freezed` o `ResultState<T>`. Aquí se prefiere control manual para evitar el `part 'auth_state.freezed.dart'`. Si se agregan estados, mantener el patrón: declarar la fábrica, su implementación interna `_NombreEstado` y el getter `is...` correspondiente.

### Apple sign-in es **stub**
`AuthService.signInWithApple()` retorna `Left(DomainException('Apple sign-in no está disponible en esta versión'))`. El cubit lo recibe y emite `AuthState.error(message)`. La UI muestra snackbar inmediatamente. Si se implementa de verdad, hay que ajustar también `_printFirebaseToken` (hoy no se llama en este flujo).

### Inconsistencia `_printFirebaseToken` solo en 3 de 4 sign-ins
Se invoca en `signUpWithEmail`, `signInWithEmail`, `signInWithGoogle` pero **no** en `signInWithApple` (línea 117–126 de `auth_cubit.dart`). No afecta producción (solo `kDebugMode`), pero si Apple llega a funcionar, considerar agregarlo.

### `AuthCubit` es `@singleton`
Vive durante toda la app y se inyecta en el root `MultiBlocProvider` de `main.dart`. Lo consume el guard `redirect` de GoRouter y casi todas las pantallas. **No** crear instancias ad-hoc.

### `_termsAccepted` es estado local, no FormField
En `signup_form.dart`, los términos se guardan en `setState()` del widget, no como `FormBuilderField`. Si se reusa el form fuera de `SignupView`, hay que pasar la validación de términos manualmente.

### Tokens debug en logs
`_printFirebaseToken` escribe el `idToken` completo con `dart:developer log()`. Solo se ejecuta en `kDebugMode`, pero conviene **no compartir logs de debug públicamente** porque exponen el token.

### Dos generaciones de widgets en `presentation/widgets/`
Archivos como `login_email_form.dart`, `signup_email_form.dart`, `social_login_button.dart`, `signup_social_buttons.dart` y `signup_header.dart` parecen alternativas no usadas. **Antes de editar widgets de auth, confirmar cuál se monta**: las pantallas vivas usan `login/widgets/...` y `signup/widgets/...`.

### `_emailLoading` en `LoginView` no se usa para gating
La variable existe pero el botón principal lee directo `state.isLoading` de `AuthCubit`. Si se quiere distinguir "estoy esperando este botón vs otro", habría que conectar `_emailLoading` con la UI.

### `RidegloryL10n.current` para mensaje de logout
`signOut()` cae al `RidegloryL10n.current.auth_failedToSignOut` en `catch (e)` genérico. Es el único lugar de `AuthCubit` que usa el helper global de l10n; el resto está hardcoded o se construye desde `DomainException.message`. Sí, los textos están mezclados (algunos español, otros inglés).

### Validación de password asimétrica
Login: minLength 6. Signup: minLength 8 + mayúscula + número. Si las políticas cambian, ajustar **ambos** archivos para mantener la asimetría coherente (o eliminarla).

### `BlocListener` vs `BlocBuilder`
Las views (login/signup/forgot) usan `BlocListener` para side effects (navigation + snackbar) y `BlocBuilder` solo dentro de botones para reaccionar a `isLoading`. No envolver toda la pantalla en `BlocBuilder` — perdería el listener y duplicaría rebuilds.

### Forgot Password tiene **su propio formKey** (en `ForgotPasswordEmailField`)
A diferencia de Login y Signup donde el form se levanta en la View, el campo de forgot password crea internamente su `GlobalKey<FormBuilderState>`. Si se refactoriza, considerar moverlo a la view para consistencia.

---

## 12. Archivos clave de referencia rápida

| Qué buscar | Archivo |
|---|---|
| Cubit + estado | `lib/features/authentication/application/auth_cubit.dart` |
| AuthService (Firebase + Google) | `lib/core/services/auth_service.dart` |
| AuthenticatedUser model | `lib/core/services/models/authenticated_user.dart` |
| Form field constants | `lib/features/authentication/constants/auth_form_fields.dart` |
| LoginView | `lib/features/authentication/login/presentation/login_view.dart` |
| LoginForm con validators | `lib/features/authentication/login/presentation/widgets/login_form.dart` |
| Botones Google/Apple | `lib/features/authentication/login/presentation/widgets/login_social_section.dart` |
| SignupView | `lib/features/authentication/signup/presentation/signup_view.dart` |
| SignupForm + validators custom | `lib/features/authentication/signup/presentation/widgets/signup_form.dart` |
| Términos checkbox | `lib/features/authentication/signup/presentation/widgets/signup_terms_checkbox.dart` |
| Texto rich de términos | `lib/features/authentication/signup/presentation/widgets/signup_terms_text.dart` |
| Forgot password view | `lib/features/authentication/login/presentation/forgot_password_view.dart` |
| Form de forgot password | `lib/features/authentication/login/presentation/widgets/forgot_password_form.dart` |
| Email enviado screen | `lib/features/authentication/login/presentation/widgets/forgot_password_email_sent_content.dart` |
| FCM service | `lib/core/services/fcm_service.dart` |
| Guard del router | `lib/shared/router/app_router.dart` (`redirect`) |
