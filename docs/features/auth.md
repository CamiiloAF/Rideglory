# Auth

> Reescrito para v2 (F4). Reemplaza `authentication.md` de la v1.

## Problema que resuelve

Bloque 0 de `docs/product/ALCANCE-V2.md`: "Auth de Supabase (Google y Apple) decide si los usuarios existentes se recuperan o hay que pedirles crear cuenta. Bloquea la migración". No hay recuperación de las cuentas Firebase de la v1 — los pocos usuarios existentes crean cuenta de nuevo el día del corte (decisión D8 de `docs/plans/refactor-v2-plan.md`).

## Flujos

- **Bienvenida (L2)**: `WelcomePage` ofrece Google, Apple y correo en la misma pantalla, con propósito explicado (decisión D3: L2 reemplaza al L1 de la v1, que no explicaba para qué sirve la app).
- **Correo**: `EmailAuthPage` cubre login y registro (parámetro `isRegister`) contra `supabase.auth.signInWithPassword` / `signUp` (metadata `full_name`).
- **Google / Apple**: `signInWithIdToken` de Supabase Auth con el SDK nativo de cada proveedor (Google Sign-In, `sign_in_with_apple` con nonce).
- **Recuperar contraseña**: `ForgotPasswordPage` → `supabase.auth.resetPasswordForEmail`.
- **Sesión observada, nunca expuesta**: `AuthRepository` (`lib/features/auth/domain/auth_repository.dart`) dispara las acciones pero nunca expone `Session`/`User` de Supabase hacia `presentation`; `AuthCubit` en `lib/core/auth/` observa `onAuthStateChange` y decide la ruta. **`AuthCubit` es la única excepción documentada en CLAUDE.md** a "cubits `@injectable` con `BlocProvider`, nunca accedidos con `getIt`" — la necesita el router para decidir la ruta inicial antes de que exista un árbol de widgets bajo el que colgar un provider normal.
- **Token FCM**: al establecerse la sesión, `AuthCubit` registra el token de push en `device_tokens`, tolerante a Firebase sin configurar.

## Pantallas (Pencil)

| Pantalla | Archivo | Pencil |
|---|---|---|
| Bienvenida | `lib/features/auth/presentation/pages/welcome_page.dart` | `tp9oS` |
| Login/registro por correo | `lib/features/auth/presentation/pages/email_auth_page.dart` | `ROAHx` (login), `xTYYm` (error) |
| Recuperar contraseña | `lib/features/auth/presentation/pages/forgot_password_page.dart` | `CBfOH` |

## Datos

Sin tablas propias ni DTOs: auth habla directo contra el SDK de Supabase Auth (`signInWithPassword`, `signUp`, `signInWithIdToken`, `resetPasswordForEmail`, `signOut`). No hay RPCs ni Edge Functions en esta feature.

## Estados

- `WelcomeCubit`, `EmailAuthCubit`, `ForgotPasswordCubit`: los tres `Cubit<ResultState<Unit>>` (`initial/loading/data/empty/error`).
- Errores mapeados a `AuthErrorCode` (`invalidCredentials`, `emailAlreadyRegistered`, `weakPassword`, `userNotFound`, `providerCancelled`, `offline`, `unknown`) en `lib/features/auth/data/auth_error_mapper.dart`, y traducidos a español en `auth_error_translator.dart` — **cero mensajes de red/auth incrustados en Dart**, todo vía `.arb`.

## Pendientes

- `social_auth_button.dart` documenta que el `.pen` todavía no tiene el nodo de logo terminado (comentario "Logo (pendiente)").
- Recuperación de cuentas de la v1 (Firebase) descartada por decisión de producto, no por falta de tiempo.
