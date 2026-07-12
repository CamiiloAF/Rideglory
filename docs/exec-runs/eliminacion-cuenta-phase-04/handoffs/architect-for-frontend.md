> Slim handoff — read this before handoffs/architect.md

# Architect → Frontend — eliminacion-cuenta-phase-04

Repo: `/Users/cami/Developer/Personal/Rideglory` (este repo).

## Corrección clave vs. el PRD

El archivo `lib/features/profile/data/repository/account_repository_impl.dart` **no existe**. El
repositorio real de borrado de cuenta es
`lib/features/users/data/repository/user_repository_impl.dart` (método `deleteMyAccount()`, línea
42), usado por `DeleteAccountUseCase` → `DeleteAccountCubit`. El comentario de conclusión de
timeout (ver abajo) va ahí.

## Qué tocar (exactamente esto, nada más)

1. **`lib/core/http/firebase_auth_interceptor.dart`** — único cambio de código real. Hoy, en
   `onError`, si `statusCode == 401`, intenta un refresh forzado de token
   (`_firebaseAuth.currentUser?.getIdToken(true)`) y si eso falla, el `catch (_) {}` lo traga en
   silencio. Cambio: capturar específicamente `FirebaseAuthException` del refresh forzado; si su
   `.code` está en `{'user-not-found', 'user-disabled', 'user-token-expired'}` (exactamente esa
   lista, **nunca** `network-request-failed` u otros códigos de conectividad):
   - Obtener `AuthCubit` con el patrón defensivo ya usado en `_crashReporter()`
     (`lib/core/http/rest_client_functions.dart` líneas 23-29):
     `try { GetIt.instance<AuthCubit>() } catch (_) { return null; }`.
   - Si se obtiene, llamar `.signOut()` (método ya existente en `AuthCubit`, hace
     `_authService.signOut()` + `emit(AuthState.unauthenticated())`).
   - Mostrar el snackbar vía `AppRouter.scaffoldMessengerKey.currentState?.showSnackBar(...)` —
     mismo patrón que ya usa
     `lib/features/events/presentation/form/widgets/event_form_view.dart:56`.
   - Dejar que `handler.next(err)` siga propagando el 401 original — no resolverlo como éxito.
   - **No se necesita tocar `app_router.dart`.** El redirect a login ya es automático: el router
     usa `refreshListenable: GoRouterRefreshStream(getIt.get<AuthCubit>().stream)` y su callback
     `redirect` ya comprueba `FirebaseAuth.instance.currentUser != null` — al llamar
     `signOut()`, ese chequeo se dispara solo.
2. **`lib/l10n/app_es.arb`** — nueva key `auth_sessionEndedSnackbar`: **"Tu sesión terminó, inicia
   sesión de nuevo."** (copy neutral obligatorio del guardrail — nunca decir que la cuenta fue
   eliminada). Regenerar `app_localizations.dart`/`app_localizations_es.dart` con
   `dart run build_runner build --delete-conflicting-outputs` o `flutter gen-l10n`.
3. **`lib/features/users/data/repository/user_repository_impl.dart`** — agregar un comentario
   (sin cambio funcional) documentando: `receiveTimeout` global de `AppDio` es 60s (ver
   `lib/core/http/app_dio.dart` línea 20), mayor al estimado de 30-45s de la orquestación de 8
   pasos del backend — no se necesita override de timeout para esta llamada.
4. **`test/core/http/firebase_auth_interceptor_test.dart`** (nuevo, carpeta no existe aún —
   crearla) — casos mínimos:
   - 401 con refresh de token exitoso → retry normal, sin logout, sin snackbar.
   - 401 con refresh que lanza `FirebaseAuthException(code: 'user-not-found' | 'user-disabled' |
     'user-token-expired')` → `AuthCubit.signOut()` llamado, snackbar mostrado, error original
     propagado.
   - 401 con refresh que lanza `FirebaseAuthException(code: 'network-request-failed')` → **no**
     logout, error original propagado sin más.
   - Usar `mocktail` (convención del repo) para mockear `FirebaseAuth`/`User` y `AuthCubit`.

## Qué NO tocar

- `DeleteAccountConfirmationPage` y sus widgets (`delete_account_*`) — cero cambios de UI, ya
  cubierto por fase 1.
- `app_router.dart` — el redirect ya funciona sin cambios.
- El timeout global de `AppDio` — no subir, solo documentar la conclusión.
- No introducir un segundo mecanismo de logout (BlocListener global, guard nuevo, etc.) — el
  interceptor + `AuthCubit.signOut()` + router ya cierran el ciclo completo.

> Full detail: handoffs/architect.md
