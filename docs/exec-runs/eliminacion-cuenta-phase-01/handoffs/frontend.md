# Frontend → (eliminacion-cuenta-phase-01)

**Fecha:** 2026-07-10T15:47:48Z (última actualización: ver "Noveno intento" abajo)
**Estado:** PARCIAL — bloqueado por diseño (ver `handoffs/design.md`)

## Noveno intento (MODO FIX, Tech Lead) — sigue bloqueado

Se relanzó este agente en MODO FIX para corregir dos hallazgos del Tech Lead:

1. **UI de eliminación de cuenta ausente (AC1, AC2, AC3, AC5, AC9 sin código).** Antes de tocar
   cualquier archivo verifiqué el bloqueo de Pencil directamente, otra vez:
   `mcp__pencil__get_editor_state({ include_schema: false })` →
   `MCP error -32603: Failed to access file . A file needs to be open in the editor to perform
   this action.` — mismo error exacto que en los 8 intentos anteriores (Design x6, Frontend x2).
   Confirmé también por `git status --short` que ninguno de los archivos de UI existe todavía:
   `delete_account_confirmation_page.dart`, sus 4 widgets hijos, el `GoRoute` en `app_router.dart`
   y el ítem destructivo en `profile_actions_list.dart` siguen sin crear/modificar. Por la regla
   cero-tolerancia (`feedback_pencil_mcp_block.md`), **no implementé** ninguno de esos archivos ni
   inventé un mockup HTML alternativo. Este hallazgo **no se pudo corregir** en esta corrida; sigue
   bloqueado por el mismo motivo externo documentado desde el intento 1.

2. **Working tree mezcla ~80 archivos ajenos a esta fase (incluyendo interleaving en
   `analytics_events.dart` y `app_es.arb` con la eliminación de las claves `eventsDraftSaved`/
   `event_saveDraft` de otra fase).** Las HARD RULES de esta corrida prohíben explícitamente
   `git add`/`commit`/`restore`/`reset`/cualquier operación de git más allá de lectura, así que
   este agente Frontend **no puede** separar el working tree por sí mismo — esa es una acción de
   git, no de código. Lo que sí puedo aportar (y ya estaba documentado en `SUMMARY.md`, sección
   "Fuera del alcance de esta fase" y "Mensaje de commit sugerido") es la lista explícita y
   completa de los archivos que pertenecen a esta fase para que el humano los stagee uno por uno
   —repetida aquí para que quede también en el handoff de Frontend, no solo en el del Tech Lead—:

   ```
   lib/features/users/data/service/user_service.dart
   lib/features/users/domain/repository/user_repository.dart
   lib/features/users/data/repository/user_repository_impl.dart
   lib/features/users/domain/use_cases/delete_account_use_case.dart          (nuevo)
   lib/features/profile/presentation/cubits/delete_account_cubit.dart        (nuevo)
   lib/shared/router/app_routes.dart
   lib/l10n/app_es.arb (+ app_localizations.dart / app_localizations_es.dart generados)
   lib/core/services/analytics/analytics_events.dart
   docs/features/profile.md
   docs/features/users.md
   test/features/users/domain/use_cases/delete_account_use_case_test.dart          (nuevo)
   test/features/users/data/repository/user_repository_impl_delete_account_test.dart (nuevo)
   test/features/profile/presentation/cubit/delete_account_cubit_test.dart          (nuevo)
   ```

   Advertencia explícita: `lib/core/services/analytics/analytics_events.dart` y
   `lib/l10n/app_es.arb` tienen en su diff actual **tanto** las adiciones legítimas de esta fase
   **como** la eliminación de `eventsDraftSaved`/`event_saveDraft` de la fase de borradores de
   eventos (no relacionada). Un `git add <archivo completo>` sobre esos dos archivos arrastraría
   ambos cambios en el mismo commit. Si se quiere mantener el historial estrictamente limpio, el
   humano debe hacer un staging parcial (`git add -p`) sobre esos dos archivos específicos para
   incluir solo los hunks de las 3 claves de analytics y las 14 claves de l10n de esta fase,
   excluyendo los hunks de borrado de `eventsDraftSaved`/`event_saveDraft`. Este agente no puede
   ejecutar ese `git add -p` (prohibido por las HARD RULES), solo documentarlo.

Reconfirmé el baseline: `flutter test` → **1382 tests, All tests passed** — mismo número que el
cierre del intento anterior, sin regresiones. No se tocó ningún archivo de código en esta pasada
(ambos hallazgos son, en esta corrida, no corregibles desde el rol Frontend: el primero por
bloqueo externo de Pencil, el segundo por prohibición explícita de operaciones de git).

**Conclusión de esta corrida:** la fase sigue sin poder cerrarse como `done`. Se requiere
intervención humana en dos frentes independientes antes de relanzar: (a) abrir `rideglory.pen` en
la app de escritorio de Pencil y confirmarlo como editor activo, y (b) hacer el staging explícito
(incluyendo `git add -p` para los dos archivos con interleaving) al momento de commitear.

## Octavo intento — sigue bloqueado (esta corrida)

Se relanzó este agente Frontend en "MODO CORRECCION" con el change map completo de la pieza de UI
(página + 4 widgets hijos + `GoRoute` + item destructivo en `ProfileActionsList` + wiring de
analytics + tests de widget) y la instrucción explícita de "desbloquear Pencil (humano abre
rideglory.pen y confirma editor activo) y diseñar la pantalla". Antes de tocar cualquier archivo
de código verifiqué el estado del bloqueo directamente:

```
mcp__pencil__get_editor_state({ include_schema: false })
→ MCP error -32603: Failed to access file . A file needs to be open in the editor to perform this action.
```

Mismo error exacto que en los 7 intentos anteriores (Design x6, Frontend x1). `ps aux | grep -i
pencil` muestra la app de escritorio corriendo (PID 62372) y un renderer con
`fileURI":"file:///Users/cami/Developer/Personal/Rideglory/rideglory.pen"` (PID 62481,
`connectedAgents: []`) — idéntico a los intentos previos; no hay evidencia nueva de que el archivo
esté abierto como pestaña activa para el MCP server de esta sesión.

Por la regla cero-tolerancia del proyecto (`feedback_pencil_mcp_block.md`, citada en el propio
prompt de esta corrida: "nunca inventes el layout ni generes un mockup HTML alternativo"), **no
implementé** `delete_account_confirmation_page.dart`, sus 4 widgets hijos, el `GoRoute`, el item
destructivo en `profile_actions_list.dart`, los call sites de analytics en la página, ni sus
tests de widget. Ninguno de esos archivos existe todavía; no se tocó ningún archivo de código en
esta pasada.

Baseline reconfirmado: `flutter test` → **1382 tests, All tests passed** — mismo número que el
cierre del intento anterior, sin regresiones.

Sobre el punto del prompt "Separar del working tree los cambios ajenos a esta fase (events/drafts,
tracking ws, tecnomecanica, home, etc.)": las HARD RULES de esta corrida prohíben explícitamente
`git restore`/`git reset`/cualquier operación de git más allá de lectura, así que este agente no
puede ejecutar esa separación — queda documentada aquí para que el humano la haga antes de
commitear la fase (coincide con lo que ya señaló el Auditor en `audit_frontend.md`, sección "Nota
de higiene del working tree").

## Séptimo intento — sigue bloqueado

Se relanzó este agente Frontend con un change map que vuelve a pedir la pieza de UI completa
(`delete_account_confirmation_page.dart`, 4 widgets hijos, `GoRoute`, item destructivo en
`ProfileActionsList`, tests de widget). Antes de tocar código verifiqué el bloqueo directamente:
`mcp__pencil__get_editor_state({ include_schema: false })` →
`MCP error -32603: Failed to access file . A file needs to be open in the editor to perform this
action.` — mismo error exacto que documentaron Design (sexto intento) y Frontend (intento de
corrección anterior). No hay ninguna herramienta `open_document` disponible en esta sesión.

Por la regla cero-tolerancia del proyecto (`feedback_pencil_mcp_block.md`, citada también en el
prompt de esta corrida: "nunca inventar mockups HTML ni specs como alternativa"), **no implementé**
`delete_account_confirmation_page.dart`, sus 4 widgets hijos, el `GoRoute`, el item destructivo en
`profile_actions_list.dart`, ni sus tests. Ninguno de esos archivos existe todavía. No se tocó
ningún archivo de código en esta pasada.

Reconfirmé el baseline (`flutter test`): **1382 tests, All tests passed** — mismo número que al
cierre de la corrida anterior, sin regresiones.

El resto de esta fase (domain/data/cubit/router-constant/l10n/analytics scaffolding, listado abajo
en "Archivos cambiados") ya estaba en el working tree de una corrida previa de este mismo agente y
sigue intacto; no requirió retrabajo.

Se necesita, antes de relanzar de nuevo: confirmación humana visual (no solo `ps aux`) de que
`rideglory.pen` es la pestaña activa y enfocada del editor de escritorio de Pencil.

## Intento de corrección (Auditor Opus) — sigue bloqueado

El Auditor Opus pidió aplicar la pieza de UI completa (página + 4 widgets hijos + `GoRoute` +
item en `ProfileActionsList` + wiring de analytics + tests de widget). Antes de tocar código
verifiqué si el bloqueo de Pencil seguía vigente, invocando `mcp__pencil__get_editor_state`
directamente en esta sesión: **el servidor Pencil MCP se desconectó inmediatamente** ("The
following MCP servers have disconnected: pencil"), reproduciendo el mismo bloqueo que documentó
Design (`MCP error -32603: Failed to access file — A file needs to be open in the editor`).

Por la regla cero-tolerancia del proyecto (`feedback_pencil_mcp_block.md`, citada también en el
propio prompt de esta corrección: "no las violes... nunca inventar mockups HTML ni specs como
alternativa"), **no implementé** `delete_account_confirmation_page.dart`, sus 4 widgets hijos, el
`GoRoute`, el item destructivo en `profile_actions_list.dart`, ni los call sites de analytics que
dependen de esa página. Ninguno de esos archivos existe todavía. El resto de la corrección
solicitada por el Auditor (todo lo que depende de la UI bloqueada) sigue sin poder aplicarse por
la misma razón.

Reconfirmé el baseline (`flutter test`): **1382 tests, All tests passed** — mismo número que al
cierre de la corrida anterior, sin regresiones ni cambios de código en esta pasada (no se tocó
ningún archivo).

Este intento se detiene aquí. Ver "Siguiente paso recomendado" al final: se necesita que un humano
abra `rideglory.pen` en la app de escritorio de Pencil y confirme que el archivo queda con un
editor activo antes de relanzar Design → UX Review → Frontend.

## Bloqueo heredado (léelo primero)

`delete_account_confirmation_page.dart` y sus 4 widgets hijos, el `GoRoute` correspondiente en
`app_router.dart`, y el item destructivo "Eliminar cuenta" en `ProfileActionsList` **NO se
implementaron** en esta corrida. El handoff de Architect es explícito: esa pieza de UI está
bloqueada hasta que Design entregue la pantalla en `rideglory.pen` y el usuario la apruebe. El
handoff de Design confirma que el Pencil MCP no pudo acceder al archivo (`rideglory.pen` no
estaba abierto en la app de escritorio) y no se generó ningún mockup HTML alternativo, conforme
a la regla cero-tolerancia del proyecto (`feedback_pencil_mcp_block.md`).

Se avanzó **todo lo que el propio handoff de Architect autorizó en paralelo**: "domain, data,
cubit lógico, router (constante), l10n scaffolding" — sin tocar el layout visual.

## Baseline

`flutter test` (corrida completa, antes de tocar nada): **1375 tests, All tests passed.**

## Archivos cambiados

### Domain/Data (`lib/features/users/`)

- `lib/features/users/data/service/user_service.dart` (modify) — nuevo
  `@DELETE(ApiRoutes.me) Future<void> deleteMyAccount();`.
- `lib/features/users/domain/repository/user_repository.dart` (modify) — nuevo
  `Future<Either<DomainException, Nothing>> deleteMyAccount();`.
- `lib/features/users/data/repository/user_repository_impl.dart` (modify) — implementa
  `deleteMyAccount()` vía `executeService` + `UserService.deleteMyAccount()`, retorna `Nothing`.
- `lib/features/users/domain/use_cases/delete_account_use_case.dart` (create) — `@injectable`,
  copia exacta del patrón `DeleteMaintenanceUseCase`.

### Cubit (`lib/features/profile/`)

- `lib/features/profile/presentation/cubits/delete_account_cubit.dart` (create) —
  `Cubit<ResultState<Nothing>>` `@injectable`, cubit de una sola pantalla (BlocProvider local
  cuando exista la página), con guard de doble-tap (`if (state is Loading<Nothing>) return;`).

### Router

- `lib/shared/router/app_routes.dart` (modify) — nueva constante
  `static const String deleteAccount = '/profile/delete-account';`. **Sin `GoRoute`
  correspondiente todavía** (requiere la página bloqueada por diseño).

### l10n

- `lib/l10n/app_es.arb` (modify) — 14 claves nuevas `profile_deleteAccount*` (título, subtítulo,
  lista de qué se borra incluyendo ítems de fases 2/3, switch, botón, banner de error, retry).
  Copy sugerido por Design/Architect, **no final** hasta que exista el diseño visual aprobado.
  Regenerado con `dart run build_runner build --delete-conflicting-outputs`
  (`app_localizations.dart` / `app_localizations_es.dart` actualizados automáticamente).

### Analytics

- `lib/core/services/analytics/analytics_events.dart` (modify) — 3 eventos nuevos sin PII:
  `accountDeletionStarted`, `accountDeletionConfirmed`, `accountDeletionFailed`. Declarados con
  su comentario de longitud GA4; **sin call sites todavía** (se conectan cuando exista la
  pantalla). Verificado contra `analytics_taxonomy_no_pii_test.dart`.

### Docs

- `docs/features/profile.md` (modify) — nueva sección §7.1 "Eliminación de cuenta (en progreso)"
  documentando qué se implementó y qué falta, más entrada en la tabla de contenido.
- `docs/features/users.md` (modify) — fila nueva en la tabla de API endpoints (§7) para
  `DELETE /users/me`.

### Regeneración de código

- `dart run build_runner build --delete-conflicting-outputs` — necesario tras agregar el método
  a `UserService` (retrofit) y `DeleteAccountUseCase`/`DeleteAccountCubit` (injectable). Se
  regeneraron `user_service.g.dart`, `injection.config.dart` (vía
  `injection.freezed.dart`/config builder) y los archivos de l10n.

## No tocado (explícitamente fuera de alcance por el bloqueo)

- `lib/features/profile/presentation/delete_account_confirmation_page.dart` — no existe.
- `lib/features/profile/presentation/widgets/delete_account_warning_list.dart` — no existe.
- `lib/features/profile/presentation/widgets/delete_account_irreversible_switch.dart` — no existe.
- `lib/features/profile/presentation/widgets/delete_account_confirm_button.dart` — no existe.
- `lib/features/profile/presentation/widgets/delete_account_error_banner.dart` — no existe.
- `lib/features/profile/presentation/widgets/profile_actions_list.dart` — **sin cambios**; no se
  agregó el item "Eliminar cuenta" (dependía de la página existente para navegar).
- `lib/shared/router/app_router.dart` — **sin cambios**; no se agregó el `GoRoute` (dependía de
  la página).

## Pruebas nuevas

- `test/features/users/domain/use_cases/delete_account_use_case_test.dart` — camino feliz
  (`Right(Nothing)`, delega al repositorio) + camino de error (propaga `DomainException`).
- `test/features/users/data/repository/user_repository_impl_delete_account_test.dart` — camino
  feliz (`Right(Nothing)`) + camino de error (`DioException` → `Left`), mockeando `UserService`.
- `test/features/profile/presentation/cubit/delete_account_cubit_test.dart` — máquina de estados
  (`loading → data(Nothing)`, `loading → error`) vía `blocTest`, más un test explícito del guard
  de doble-tap: dos llamadas concurrentes a `deleteAccount()` mientras la primera está `loading`
  solo invocan el use case una vez.

Total: 7 tests nuevos, todos verdes.

## Resultado final

```
flutter test → 1382 tests, All tests passed
  (1375 baseline + 7 nuevos de esta fase)
dart analyze → 15 issues preexistentes (curly_braces_in_flow_control_structures, info-level),
  ninguno introducido por esta corrida; 0 issues en los archivos tocados
  (lib/features/users, lib/features/profile/presentation/cubits,
  lib/shared/router/app_routes.dart, lib/core/services/analytics/analytics_events.dart)
```

## Verificación manual

No se levantó la app (no hay pantalla que ejercitar todavía — el flujo completo requiere la UI
bloqueada). Lo que sí se verificó:
- `dart run build_runner build --delete-conflicting-outputs` corre limpio y regenera
  `user_service.g.dart` con el nuevo método `deleteMyAccount()`.
- `flutter test test/core/services/analytics/analytics_taxonomy_no_pii_test.dart` en verde con
  los 3 eventos nuevos (sin substrings PII prohibidos, snake_case, ≤40 chars).
- El contrato HTTP (`DELETE /users/me`, sin body, 204 en éxito) coincide con lo que documentó
  Backend en `handoffs/backend.md`.

## Notas para QA

- **Esta fase no es demostrable end-to-end en la app todavía** — no hay ningún punto de entrada
  visible en la UI (ProfileActionsList no tiene el item, no hay ruta registrada). QA no debería
  intentar ejercitar el flujo de eliminación de cuenta desde la app hasta que exista una fase de
  seguimiento que desbloquee el diseño e implemente la página.
- Lo que sí es verificable ahora mismo vía tests automatizados: `DeleteAccountUseCase`,
  `UserRepositoryImpl.deleteMyAccount()`, `DeleteAccountCubit` (incluyendo el guard de doble-tap).
- Cuando se desbloquee Pencil y se implemente la página en una fase siguiente, el criterio AC7 más
  importante (según Backend) es que el error en el hard-delete del usuario en `users-ms` nunca
  debe dejar a Firebase Auth borrado con el usuario aún vivo en la BD, ni viceversa parcialmente
  silencioso — eso ya está cubierto en el backend (`account-deletion.service.spec.ts`); del lado
  Frontend, cuando exista la página, verificar que el estado `error` de `DeleteAccountCubit` no
  navegue a ningún lado (debe quedarse en la pantalla con el banner + retry manual).
- Los 3 eventos de analytics (`account_deletion_started/confirmed/failed`) están declarados pero
  sin uso — no aparecerán en Firebase Analytics hasta que se conecten en la página futura.

## Siguiente paso recomendado

Requiere que un humano abra `rideglory.pen` en la app de escritorio de Pencil y confirme que el
archivo queda con un editor activo, luego relanzar Design → UX Review → Frontend (solo la pieza de
UI: página, 4 widgets, `GoRoute`, item en `ProfileActionsList`, wiring de analytics en la página).
El resto de esta fase (domain/data/cubit/l10n/analytics scaffolding) queda completo y no requiere
retrabajo.
