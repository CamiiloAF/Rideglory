# Fase 11 — Privacidad: opt-out en perfil y alineación de la política

- Slug del plan: `analytics-crashlytics-cobertura-total`
- ID de fase: 11
- Depende de: 1, 10
- Sesión: PLANEACIÓN (este archivo no modifica código de la app)
- Estado de captura: **Sí hay UI nueva**. Release: colección activa hasta opt-out;
  `setEnabled(false)` al desactivar. Debug: off (gating de fase 1). Tests: no-op impl.

## Objetivo

El rider controla su privacidad con un **opt-out funcional, anónimo y sin PII**, alineado
con la política publicada. Un switch en la sección "Ajustes" del perfil activa/desactiva la
colección de analítica (Firebase Analytics + Crashlytics) vía `AnalyticsService.setEnabled`,
la preferencia persiste entre arranques, y `docs/privacy-policy.html` describe explícitamente
qué se recoge (analítica anónima + Crashlytics) y cómo desactivarlo.

## Alcance (entra / no entra)

**Entra**
- Una **fila de opt-out** como widget propio (clase y archivo propios), consistente con
  `ProfileMenuItem`, que usa el átomo `AppSwitch` (`value`/`onChanged`).
- Un **cubit de consentimiento** (`AnalyticsConsentCubit`, `@injectable`) que lee/escribe la
  preferencia en `UserStorageService` y llama `AnalyticsService.setEnabled`.
- Provisión del cubit por `BlocProvider` en el árbol de perfil (sitio exacto: ver paso 3).
- Persistencia de la preferencia (default **opt-in**) y aplicación del estado al iniciar.
- Estado de **error al persistir**: revertir el switch + aviso ES sentence-case.
- Strings ES en `lib/l10n/app_es.arb` (sentence-case).
- Alineación de `docs/privacy-policy.html` (analítica anónima + Crashlytics + cómo desactivar).
- Test unitario del cubit (mock de `AnalyticsService`) + test de widget de la fila.

**No entra**
- Auditoría no-PII transversal ni el doc de QA de analítica (eso es la **fase 10**).
- Cambios en `rideglory-api` (analítica 100% client-side; `GET /me` intacto).
- Migrar `UserStorageService` a `SharedPreferences` (hoy usa `FlutterSecureStorage`; se
  reutiliza tal cual; ver nota en "Cambios de datos").
- Cualquier pantalla nueva de ajustes (no existe `settings_page`; el opt-out vive en perfil).
- Convertir `ProfileActionsList` en un form ni introducir `FormBuilder`/`AppSwitchTile`.

## Que se debe hacer (pasos concretos y ordenados)

1. **Extender la persistencia (`UserStorageService`).** Añadir a
   `lib/core/services/user_storage_service.dart` un par lectura/escritura para el flag de
   consentimiento, p.ej. `Future<bool> getAnalyticsEnabled()` (default `true` = opt-in si la
   clave no existe) y `Future<void> setAnalyticsEnabled(bool enabled)`, con una clave estable
   (p.ej. `analytics_enabled`). No es un dato por-usuario: es preferencia de dispositivo, así
   que la clave **no** lleva el prefijo `api_user_<uid>`. Nota: este servicio hoy escribe en
   `FlutterSecureStorage`, no en `SharedPreferences`; se reutiliza el mismo backend (no se
   añade dependencia nueva). El criterio "persiste entre arranques" se cumple igual.

2. **Crear el cubit de consentimiento.** Nuevo
   `lib/features/profile/presentation/cubits/analytics_consent_cubit.dart`,
   `Cubit<ResultState<bool>>` (`bool` = "colección habilitada"), marcado `@injectable`.
   Responsabilidades:
   - `load()`: lee `UserStorageService.getAnalyticsEnabled()` (default `true`), aplica el
     estado real con `AnalyticsService.setEnabled(enabled)` y emite `ResultState.data(enabled)`.
   - `toggle(bool enabled)`: emite optimista `data(enabled)`, persiste vía
     `UserStorageService.setAnalyticsEnabled(enabled)` y llama `AnalyticsService.setEnabled`.
     Si la persistencia falla → **revertir** (re-emitir `data(!enabled)`) y emitir/exponer un
     `ResultState.error` o señal para que la UI muestre el aviso ES. No usa flags booleanos de
     loading/error sueltos: el estado es `ResultState<bool>`.
   - Depende por constructor de `UserStorageService` y `AnalyticsService` (ambos `core`,
     abstracción pura — respeta la regla de capa G0 de la fase 1; `setEnabled` lo provee la
     fase 1). El cubit es `@injectable` + `BlocProvider` (no `@singleton`/`getIt` global).

3. **Proveer el cubit en el árbol de perfil (sitio exacto).** Envolver la instancia de
   `ProfileActionsList` con `BlocProvider<AnalyticsConsentCubit>(create: (_) =>
   getIt<AnalyticsConsentCubit>()..load())`. El sitio recomendado es
   **`lib/features/profile/presentation/widgets/profile_content.dart`**, justo alrededor del
   `ProfileActionsList` en `children` (hoy en L30 como `const ProfileActionsList()`); como
   alternativa equivalente puede colocarse más arriba en
   **`lib/features/profile/presentation/profile_page.dart`** envolviendo `ProfileContent`.
   Al introducir el `BlocProvider` (un descendiente no-const) **hay que ELIMINAR el `const`**
   de la instancia de `ProfileActionsList` (deja de ser una constante de compilación porque
   pasa a estar bajo un `BlocProvider` con `create`, y porque su fila opt-out consumirá el
   cubit con `context.watch/read`).

4. **Insertar la fila de opt-out (ubicación correcta de la etiqueta "Ajustes").** Importante:
   la etiqueta "Ajustes" (`context.l10n.profile_settings`, renderizada por
   `ProfileSectionLabel`) **NO está dentro de `ProfileActionsList`**: la pinta
   `profile_content.dart` como **hermano que precede** a `ProfileActionsList` (hoy L28:
   `ProfileSectionLabel(label: context.l10n.profile_settings)`, seguido de
   `AppSpacing.gapMd` y luego el `ProfileActionsList` en L30). Por tanto **no** se añade un
   `FormSectionHeader`/encabezado nuevo dentro de `ProfileActionsList`: la sección "Ajustes"
   ya existe a nivel de `profile_content.dart`. La nueva fila de opt-out se inserta como un
   ítem más **dentro del `Column` de `ProfileActionsList`** (junto a los `ProfileMenuItem`),
   separada por `ProfileMenuDivider`, coherente con el resto de la lista. (Evitar la redacción
   "sección Ajustes dentro de ProfileActionsList": la etiqueta vive en `profile_content.dart`,
   no en la lista.)

5. **Crear el widget de la fila opt-out (un widget por archivo).** Nuevo
   `lib/features/profile/presentation/widgets/profile_analytics_optout_tile.dart`,
   `StatelessWidget` que:
   - Replica el layout de `ProfileMenuItem` (icono + label `Expanded`), pero a la derecha
     coloca `AppSwitch(value: enabled, onChanged: ...)` en lugar del chevron.
   - `value` = estado del `AnalyticsConsentCubit`; `onChanged` llama `cubit.toggle(value)`.
     El switch "on" usa el knob **oscuro** del propio `AppSwitch` (`darkBgPrimary`), nunca
     blanco (ya garantizado por el átomo).
   - Toda la fila respeta touch target ≥44 px (la fila supera 44 px por el padding
     `vertical: 14` heredado del estilo de `ProfileMenuItem`; el `AppSwitch` mide 44x26 e
     incluye su propio `GestureDetector`). Sin `Material Switch`/`SwitchListTile`/
     `CupertinoSwitch`/`AppSwitchTile`/`FormBuilderSwitch`.
   - Strings vía `context.l10n` (label del opt-out, p.ej. `profile_analyticsOptOutLabel`).

6. **Estado de error → revertir switch + aviso ES.** Cuando `toggle` falla al persistir, el
   cubit revierte (`data(!enabled)`) y la fila escucha (vía `BlocListener`/`BlocConsumer`) el
   `ResultState.error` para mostrar un `SnackBar`/aviso ES sentence-case (string nuevo, p.ej.
   `profile_analyticsOptOutSaveError`). El switch vuelve visualmente a su valor previo.

7. **Strings ES en `app_es.arb`.** Añadir (sentence-case, prefijo `profile_`):
   - `profile_analyticsOptOutLabel` (texto de la fila, p.ej. "Compartir datos de uso anónimos").
   - `profile_analyticsOptOutSaveError` (aviso de fallo al guardar, p.ej. "No pudimos guardar
     tu preferencia. Inténtalo de nuevo.").
   - Tras editar el `.arb`, regenerar (`dart run build_runner build --delete-conflicting-outputs`).

8. **Alinear `docs/privacy-policy.html`.** Ampliar la sección de servicios/datos para
   mencionar explícitamente: (a) analítica **anónima** (Firebase Analytics, sin PII),
   (b) **Firebase Crashlytics** (reportes de errores/crashes anonimizados) como una fila/punto
   nuevo, y (c) **cómo desactivarla** desde Perfil → Ajustes (el opt-out). La fila existente
   de "Firebase Analytics" (L342) se complementa con Crashlytics y con la nota de opt-out.

9. **Pruebas.** Test unitario del `AnalyticsConsentCubit` con mock de `AnalyticsService` y
   fake/mock de `UserStorageService` (toggle on/off llama `setEnabled`; persistencia falla →
   revierte). Test de widget de la fila (render + tap dispara `toggle`; knob oscuro). `dart
   analyze` limpio y `flutter test` verde.

## Archivos a crear/modificar (rutas reales, una linea de "que cambia")

| Ruta | Qué cambia |
|---|---|
| `lib/core/services/user_storage_service.dart` | Añade `getAnalyticsEnabled()` (default true=opt-in) y `setAnalyticsEnabled(bool)` con clave de dispositivo (sin prefijo por-uid). |
| `lib/features/profile/presentation/cubits/analytics_consent_cubit.dart` | **Nuevo.** `Cubit<ResultState<bool>>` `@injectable`: `load()`/`toggle()`, persiste y llama `AnalyticsService.setEnabled`; revierte ante fallo. |
| `lib/features/profile/presentation/widgets/profile_analytics_optout_tile.dart` | **Nuevo.** Fila propia (un widget/archivo) estilo `ProfileMenuItem` con `AppSwitch` (knob oscuro), ≥44px; lee/escribe el cubit. |
| `lib/features/profile/presentation/widgets/profile_content.dart` | Envuelve `ProfileActionsList` con `BlocProvider<AnalyticsConsentCubit>` y **elimina el `const`** de `ProfileActionsList` (L30). La etiqueta "Ajustes" (L28) sigue aquí como hermano previo a la lista. |
| `lib/features/profile/presentation/widgets/profile_actions_list.dart` | Inserta `ProfileAnalyticsOptOutTile` como ítem del `Column` (con `ProfileMenuDivider`); deja de ser `const` al consumir el cubit. |
| `lib/features/profile/presentation/profile_page.dart` | (Alternativa al `BlocProvider`) sitio equivalente para envolver `ProfileContent` si se prefiere no tocar `profile_content.dart`. Ruta real confirmada (no existe `presentation/pages/`). |
| `lib/l10n/app_es.arb` | Añade `profile_analyticsOptOutLabel` y `profile_analyticsOptOutSaveError` (ES sentence-case). |
| `docs/privacy-policy.html` | Menciona analítica anónima + Crashlytics + cómo desactivar (Perfil → Ajustes). |
| `test/.../analytics_consent_cubit_test.dart` | **Nuevo.** Verifica toggle→setEnabled, persistencia y reversión ante fallo (mocks). |
| `test/.../profile_analytics_optout_tile_test.dart` | **Nuevo.** Render + tap dispara toggle; knob oscuro. |

Nota: las rutas de `lib/features/profile/presentation/` confirmadas con `ls` — **no existe**
subdir `pages/`; la página vive en `lib/features/profile/presentation/profile_page.dart`.

## Contratos / API rideglory-api (o "ninguno")

Ninguno. Analítica 100% client-side; el opt-out solo toca SDK Firebase (vía abstracción
`core`) y almacenamiento local. `GET /me` y cualquier endpoint quedan intactos.

## Cambios de datos / migraciones (o "ninguno")

Sin migración de backend. Localmente se añade **una clave** de preferencia
(`analytics_enabled`) en `UserStorageService` (backend actual: `FlutterSecureStorage`).
Ausencia de la clave ⇒ default `true` (opt-in). No se borra ni migra ninguna clave existente.

## Criterios de aceptacion (numerados, observables, testeables)

1. Alternar el opt-out a **off** llama `AnalyticsService.setEnabled(false)` y **detiene** la
   colección (verificable en GA4 DebugView: dejan de llegar eventos); volver a **on** la
   reanuda (`setEnabled(true)`).
2. La preferencia **persiste entre arranques**: tras desactivar y reiniciar la app, el switch
   sigue en off y `setEnabled(false)` se reaplica en `load()`.
3. **Default opt-in**: en una instalación limpia (clave ausente) el switch arranca en on y la
   colección está activa.
4. Si la **persistencia falla**, el switch **revierte** a su valor anterior y aparece un aviso
   ES sentence-case (`profile_analyticsOptOutSaveError`).
5. La fila es **un widget en su propio archivo** (`profile_analytics_optout_tile.dart`), usa
   `AppSwitch` con knob "on" **oscuro** (nunca blanco) y touch target ≥44px; no usa
   `AppSwitchTile`, `Material Switch`/`SwitchListTile`, `CupertinoSwitch` ni `FormBuilderSwitch`.
6. La etiqueta "Ajustes" se renderiza **a nivel de `profile_content.dart`** (hermano previo a
   `ProfileActionsList`, L28), no como header nuevo dentro de `ProfileActionsList`.
7. `ProfileActionsList` **deja de ser `const`** y queda bajo un `BlocProvider<AnalyticsConsentCubit>`
   (sitio: `profile_content.dart` o `profile_page.dart`).
8. `docs/privacy-policy.html` menciona explícitamente analítica **anónima**, **Crashlytics** y
   **cómo desactivar** desde Perfil → Ajustes.
9. `dart analyze` limpio; `flutter test` verde con los nuevos tests.

## Pruebas (unitarias/widget/integracion)

- **Unitaria — `AnalyticsConsentCubit`** (mock `AnalyticsService` + fake `UserStorageService`):
  - `load()` con clave ausente ⇒ `data(true)` y `setEnabled(true)`.
  - `toggle(false)` ⇒ persiste false, `setEnabled(false)`, estado `data(false)`.
  - `toggle(false)` con persistencia que lanza ⇒ estado revierte a `data(true)` + señal de
    error; `setEnabled` no queda en un estado inconsistente.
- **Widget — `ProfileAnalyticsOptOutTile`**:
  - Render muestra label + `AppSwitch` en el valor del cubit.
  - Tap en el switch invoca `toggle` con el valor negado.
  - (Opcional) verificación de que el knob "on" usa `darkBgPrimary` (no blanco).
- **Integración ligera (opcional)**: pumpea `ProfileContent` con un `AnalyticsConsentCubit`
  mockeado y comprueba que la fila aparece bajo la etiqueta "Ajustes" y que `ProfileActionsList`
  ya no es `const`.

## Riesgos y mitigaciones

1. **Widget equivocado.** `AppSwitchTile` exige `FormBuilder` y `ProfileActionsList` no es
   form. *Mitigación*: usar el átomo `AppSwitch` (`value`/`onChanged`) en fila/clase/archivo
   propios; knob oscuro garantizado por el átomo.
2. **`const` olvidado.** Si no se elimina `const` de `ProfileActionsList` al inyectar el
   provider/consumidor, no compila o no recibe el cubit. *Mitigación*: paso 3 lo exige
   explícitamente; el criterio 7 lo verifica.
3. **Ruta inexistente.** No hay `presentation/pages/`. *Mitigación*: rutas confirmadas con
   `ls`; la página es `presentation/profile_page.dart`.
4. **Estado de error silencioso.** Un fallo de persistencia que no revierte deja la UI
   mintiendo. *Mitigación*: cubit revierte + aviso ES (criterio 4) con test dedicado.
5. **`setEnabled` ausente.** Depende de que la fase 1 amplíe `AnalyticsService` con
   `setEnabled`. *Mitigación*: dependencia declarada (fase 1); si no existe, bloquea esta fase.
6. **Backend de storage.** El plan menciona "SharedPreferences" pero el servicio usa
   `FlutterSecureStorage`. *Mitigación*: reutilizar el backend actual; el requisito real
   ("persiste entre arranques + default opt-in") se cumple sin añadir dependencia.

## Dependencias (fases prerequisito y por que)

- **Fase 1** — provee la abstracción `AnalyticsService.setEnabled` (y `CrashReporter`/gating)
  que el opt-out invoca; sin ella no hay palanca que activar/desactivar.
- **Fase 10** — la auditoría no-PII y el doc de QA garantizan que lo que el opt-out
  desactiva es analítica **anónima sin PII**, alineada con la política; el opt-out cierra la
  superficie de privacidad sobre datos ya auditados. (La fase 10 no bloquea la implementación
  de UI: sus hallazgos pendientes quedan como tareas, pero la política y el default opt-in se
  apoyan en su veredicto.)
