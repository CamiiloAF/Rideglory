> Slim handoff — read this before handoffs/architect.md

# Architect → Frontend (eliminacion-cuenta-phase-01)

## Bloqueo de diseño (léelo primero, sigue vigente)

`delete_account_confirmation_page.dart` y sus 4 widgets hijos **no se implementan hasta que Design
entregue la pantalla en `rideglory.pen` y el usuario la apruebe explícitamente**. Verificado en
`handoffs/design.md`: 3 intentos hoy de abrir `rideglory.pen` vía Pencil MCP, los 3 fallaron
(`MCP error -32603: Failed to access file`). Si llegas a esta fase sin aprobación de diseño,
detente y avisa — no inventes el layout ni generes un mockup HTML alternativo.

## Ya implementado — NO reimplementar (verificado de nuevo en este run)

- `lib/features/users/data/service/user_service.dart` — `@DELETE(ApiRoutes.me) Future<void> deleteMyAccount();` ya existe.
- `lib/features/users/domain/repository/user_repository.dart` +
  `lib/features/users/data/repository/user_repository_impl.dart` — `deleteMyAccount()` ya existe,
  vía `executeService`.
- `lib/features/users/domain/use_cases/delete_account_use_case.dart` — ya existe, patrón
  `DeleteMaintenanceUseCase`.
- `lib/features/profile/presentation/cubits/delete_account_cubit.dart` — ya existe:

  ```dart
  @injectable
  class DeleteAccountCubit extends Cubit<ResultState<Nothing>> {
    DeleteAccountCubit(this._useCase) : super(const ResultState.initial());
    final DeleteAccountUseCase _useCase;

    Future<void> deleteAccount() async {
      if (state is Loading<Nothing>) return; // guard doble-tap — AC4, ya cubierto por test
      emit(const ResultState.loading());
      final result = await _useCase();
      result.fold(
        (error) => emit(ResultState.error(error: error)),
        (nothing) => emit(ResultState.data(data: nothing)),
      );
    }
  }
  ```
- `lib/shared/router/app_routes.dart` — `deleteAccount = '/profile/delete-account'` ya existe.
- `lib/l10n/app_es.arb` — 13 claves `profile_deleteAccount_*` ya existen con copy en español.
- `lib/core/services/analytics/analytics_events.dart` — `accountDeletionStarted/Confirmed/Failed`
  ya declarados (sin PII, ≤40 chars).
- Tests ya existentes y en verde: `test/features/users/domain/use_cases/delete_account_use_case_test.dart`,
  `test/features/users/data/repository/user_repository_impl_delete_account_test.dart`,
  `test/features/profile/presentation/cubit/delete_account_cubit_test.dart`.

## Pendiente (una vez exista diseño aprobado)

- `lib/features/profile/presentation/delete_account_confirmation_page.dart` — provee
  `BlocProvider<DeleteAccountCubit>` **local** (no root `MultiBlocProvider`, mismo criterio que
  `EditProfileCubit`/`AnalyticsConsentCubit`). Mapea `ResultState<Nothing>` a
  `idle/confirming/loading/error/success` (`initial→idle`, `loading→loading`, `error→error`,
  `data→success`). En éxito, replica el bloque de `ProfileActionsList._logout` (no lo extraigas a
  helper compartido salvo que decidas que vale la pena): `AuthCubit.signOut()` +
  `VehicleCubit.clearVehicles()` + `ProfileCubit.reset()` + `context.goAndClearStack(AppRoutes.login)`.
- 4 widgets hijos, uno por archivo, sin métodos `_buildX()`:
  - `delete_account_warning_list.dart` — lista de qué se borra, **incluye ítems de fases 2/3 sin
    badge "próximamente"** (ADR-8 — se muestran igual que los ítems que sí se borran hoy).
  - `delete_account_irreversible_switch.dart` — envuelve `AppSwitchTile` (único switch permitido
    en el proyecto; nunca Material/`FormBuilderSwitch`).
  - `delete_account_confirm_button.dart` — `AppButton`, deshabilitado si el switch está off o
    `state is Loading`.
  - `delete_account_error_banner.dart` — mensaje + retry manual (un tap = una llamada, sin loop
    automático).
- `lib/features/profile/presentation/widgets/profile_actions_list.dart` — nuevo `ProfileMenuItem`
  "Eliminar cuenta" (mismo patrón visual destructivo que "Cerrar sesión": `iconColor`/`labelColor:
  AppColors.error`), pero navega con `context.pushNamed(AppRoutes.deleteAccount)` — **no** abre
  `ConfirmationDialog.show` (a diferencia de logout; AC1 lo exige explícitamente).
- `lib/shared/router/app_router.dart` — `GoRoute` hija de `AppRoutes.profile`, mismo patrón que
  `editProfile` (`parentNavigatorKey: _rootNavigatorKey`; a diferencia de `editProfile`, esta
  página no requiere `extra`).
- `docs/features/profile.md` — reemplazar la sección §7.1 "EN PROGRESO" existente por la versión
  final: estructura de la pantalla, rutas de navegación actualizadas.

> Full detail: handoffs/architect.md
