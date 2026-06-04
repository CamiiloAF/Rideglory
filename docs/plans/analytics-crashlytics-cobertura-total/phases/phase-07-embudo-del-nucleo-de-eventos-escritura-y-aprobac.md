# Fase 7 — Embudo del núcleo de eventos — ESCRITURA y aprobación

- Slug: `analytics-crashlytics-cobertura-total`
- Fase ID: 7 (legacy F6, segunda mitad del split)
- Fecha (UTC): 2026-06-04T01:11:04Z
- dependsOn: 1, 2, 6
- Sesión: PLANEACIÓN (no se modifica código de la app en esta corrida)
- Estado de captura: sin UI nueva · activa en release · off en `kDebugMode` · no-op en tests
- Insumos: `05-sintesis.md` (fila 7), `03-architect-review.md` (F6), `01-scan.md`

## Objetivo

El analista entiende dónde se cae la conversión al **crear/publicar** eventos y en el
**workflow de aprobación** de registros. Se instrumentan los flujos de escritura del feature
`events` y todo el ciclo de vida de `event_registration` como embudos
`inicio → avance → éxito/abandono`, con parámetros agregados y sin PII (sin id de evento,
registro o rider como valor de alta cardinalidad). Es la segunda mitad del split del núcleo de
eventos: la fase 6 cubrió la **lectura** (home + descubrir/ver); esta cubre **escritura y
aprobación**.

## Alcance (entra / no entra)

### Entra
- **Crear/editar evento** (`EventFormCubit`): inicio del formulario, guardar borrador, publicar
  (éxito/fallo). Si el formulario expone secciones discretas instrumentables, avance entre ellas.
- **Eliminar evento** (`EventDeleteCubit`): intento y resultado (éxito/fallo).
- **Registro a evento — wizard multistep** (`RegistrationFormCubit` +
  `RegistrationWizardController`): inicio del wizard, avance/retroceso por paso (embudo
  inicio→pasos→envío), envío exitoso/fallido, abandono.
- **Workflow de aprobación** (`AttendeesCubit`): aprobar, rechazar, marcar "listo para editar"
  (`readyForEdit`), con resultado por acción.
- **Mis registros** (`MyRegistrationsCubit`): consulta del listado de registros propios y
  acciones disponibles ahí (p. ej. cancelar, si existe).
- Test unitario con **mock** de `AnalyticsService` por cada cubit con call sites nuevos.

### No entra
- Lectura/descubrimiento de eventos (home, list, detail) → **fase 6**.
- Tracking en vivo / SOS → **fase 8**.
- `screen_view` automático → ya provisto por **fase 3** (no se instrumenta pantalla por pantalla).
- Constantes/taxonomía nuevas fuera del prefijo `events_`/`registration_` → definidas en **fase 2**.
- Cualquier cambio de UI, contrato de API o comportamiento funcional.
- Logging de cada keystroke o cambio de campo del formulario (solo hitos de embudo).

## Que se debe hacer (pasos concretos y ordenados)

1. **Reutilizar la fundación.** Inyectar la abstracción `AnalyticsService` (core, Dart-puro,
   fase 1) en cada cubit instrumentado. No se importa el SDK Firebase en presentation. Para los
   cubits `@injectable` la dependencia se cablea por DI; para `AttendeesCubit` (no `@injectable`)
   se pasa manualmente (paso 6).

2. **Definir/consumir las constantes de taxonomía** (declaradas en fase 2, prefijo por feature):
   - Crear evento: `events_create_started`, `events_draft_saved`, `events_published`,
     `events_publish_failed`, y **condicional** `events_create_step_advanced`
     (param `step_name`/`step_index`) — solo si el formulario expone secciones discretas
     navegables (ver paso 3 y criterios 1 y 4).
   - Eliminar evento: `events_delete_attempted`, `events_delete_succeeded`,
     `events_delete_failed`.
   - Registro wizard: `registration_started`, `registration_step_advanced`,
     `registration_step_back`, `registration_submitted`, `registration_submit_failed`,
     `registration_abandoned`.
   - Aprobación: `registration_approved`, `registration_rejected`, `registration_ready_for_edit`,
     y resultado fallido `registration_approval_failed` (param `action`).
   - Mis registros: `registration_my_list_viewed` (+ acción de cancelar si existe en el cubit).
   - **Regla G1**: ningún `logEvent(` con literal directo; todo vía constante (verificable por grep).

3. **Instrumentar `EventFormCubit`**
   (`lib/features/events/presentation/form/cubit/event_form_cubit.dart`):
   - Emitir `events_create_started` cuando el cubit entra al flujo de creación (constructor /
     primer estado del formulario de un evento nuevo, distinguiendo crear vs editar con un param
     `mode`).
   - En **`saveDraft()` (L409)** emitir `events_draft_saved` al confirmar el guardado exitoso.
   - En el camino de publicar (dentro de `saveEvent()` L162, o donde se confirma publicación)
     emitir `events_published` al éxito y `events_publish_failed` al fallo, con param de razón
     **categorizada** (no el mensaje crudo).
   - **`events_create_step_advanced` es CONDICIONAL/OPCIONAL**: hoy `EventFormCubit` NO expone
     pasos discretos (es un formulario de secciones en una sola página, no un wizard por pasos).
     Solo se añade este evento si/ cuando el formulario exponga secciones discretas navegables;
     de lo contrario el embudo verificable de creación es
     `events_create_started → events_draft_saved / events_published` (sin paso intermedio).

4. **Instrumentar `EventDeleteCubit`**
   (`lib/features/events/presentation/delete/cubit/event_delete_cubit.dart`): emitir
   `events_delete_attempted` al iniciar y `events_delete_succeeded`/`events_delete_failed` según
   el `ResultState` resultante. Param de razón categorizada en el fallo, sin id de evento.

5. **Instrumentar el wizard de registro multistep.** El controlador `RegistrationWizardController`
   se acciona desde `RegistrationFormContent`
   (`lib/features/event_registration/presentation/registration_form_content.dart`), NO desde el
   navigation bar: `RegistrationWizardNavigationBar` solo expone callbacks `onNext`/`onBack`
   (L24-26) que la vista enlaza a `_onNext`/`_onBack` (content L220-221). Los call sites reales
   de avance/retroceso de paso son:
   - **`_onNext()` → `_wizard.next()` en content L116**: junto a esa llamada, invocar
     `context.read<RegistrationFormCubit>().onStepAdvanced(index, name)` (emite
     `registration_step_advanced` con `step_index`/`step_name` agregados).
   - **`_onBack()` → `_wizard.previous()` en content L123**: junto a esa llamada, invocar
     `cubit.onStepBack(index, name)` (emite `registration_step_back`).
   - `registration_started` se emite al construir/abrir el wizard (initState de
     `_RegistrationFormContentState` o constructor del `RegistrationFormCubit`).
   - `registration_submitted`/`registration_submit_failed` en `RegistrationFormCubit`
     (`lib/features/event_registration/presentation/cubit/registration_form_cubit.dart`) según el
     `ResultState` del envío (método de submit invocado desde `_submitRegistration` L127).
   - `registration_abandoned` opcional: en `dispose` si el wizard se cierra sin envío (mejor
     esfuerzo; no bloquea el criterio si no es fiable).
   - La lógica de analítica vive en métodos del **cubit** (`onStepAdvanced`/`onStepBack`); la vista
     solo invoca esos métodos junto a las llamadas del wizard (L116/L123). No se inyecta
     `AnalyticsService` directamente en el widget.

6. **Instrumentar el workflow de aprobación en `AttendeesCubit`**
   (`lib/features/events/presentation/attendees/attendees_cubit.dart`): en
   `approveRegistration()` (L119), `rejectRegistration()` (L127) y `setReadyForEdit()` (L135)
   emitir `registration_approved` / `registration_rejected` / `registration_ready_for_edit` al
   éxito, y `registration_approval_failed` (param `action`) al fallo. Sin id de registro ni de
   rider como valor.
   - **Cableado manual (importante):** `AttendeesCubit` **NO es `@injectable`** (la clase en L14 no
     tiene anotación); se instancia a mano en `AttendeesPage`
     (`lib/features/events/presentation/attendees/attendees_page.dart`, L20-26) vía `getIt<...>()`
     dentro del `BlocProvider.create`. Por tanto, añadir el parámetro `AnalyticsService` al
     constructor de `AttendeesCubit` y pasar `getIt<AnalyticsService>()` en ese `create` (junto a
     los use cases ya resueltos). **Para este cubit `build_runner` NO cablea la dependencia** (no
     hay anotación que regenerar); el cableado es manual en `attendees_page.dart`.

7. **Instrumentar `MyRegistrationsCubit`**
   (`lib/features/event_registration/presentation/my_registrations_cubit.dart`): emitir
   `registration_my_list_viewed` en `fetchMyRegistrations()`, y el evento de cancelar si ese cubit
   ya expone la acción. Es `@injectable` (L11) **y** singleton del root provider, resuelto por
   `getIt.get<MyRegistrationsCubit>()` en `main.dart` (L69). Como `@injectable`, `build_runner`
   inyecta la nueva dependencia automáticamente; **verificar en `main.dart` L69** que la
   resolución por `getIt` siga compilando sin cambios manuales (ahí no se construye con argumentos
   posicionales, así que no debería requerir ajuste; confirmarlo tras regenerar).

8. **Regenerar DI solo para los cubits `@injectable`:**
   `dart run build_runner build --delete-conflicting-outputs`. Esto recablea
   `EventFormCubit`, `EventDeleteCubit`, `RegistrationFormCubit` y `MyRegistrationsCubit` (los
   cuatro `@injectable`). **No** aplica a `AttendeesCubit` (cableado manual del paso 6).

9. **Verificar gating y limpieza:** handlers no reportan en `kDebugMode`; no-op impl en tests;
   `dart analyze` limpio; `dart format`.

## Archivos a crear/modificar (rutas reales, una línea de "que cambia")

| Ruta | Qué cambia |
|---|---|
| `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | `@injectable` (L36); añade `AnalyticsService` al constructor (recableado por build_runner); emite `events_create_started`, `events_draft_saved` (en `saveDraft` L409), `events_published`/`events_publish_failed` (en `saveEvent` L162); `events_create_step_advanced` solo si hay secciones discretas. |
| `lib/features/events/presentation/delete/cubit/event_delete_cubit.dart` | `@injectable` (L6); añade `AnalyticsService` (recableado por build_runner); emite `events_delete_attempted/succeeded/failed`. |
| `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart` | `@injectable` (L15); añade `AnalyticsService` (recableado por build_runner); métodos `onStepAdvanced`/`onStepBack`, `registration_started`, `registration_submitted`/`_submit_failed`. |
| `lib/features/event_registration/presentation/registration_form_content.dart` | Invoca `cubit.onStepAdvanced(...)` junto a `_wizard.next()` (L116) y `cubit.onStepBack(...)` junto a `_wizard.previous()` (L123); emite `registration_started` en `initState`. Sin lógica de analítica directa en el widget. |
| `lib/features/events/presentation/attendees/attendees_cubit.dart` | **NO `@injectable`** (L14); añade `AnalyticsService` al constructor; emite `registration_approved/rejected/ready_for_edit` y `_approval_failed` en `approveRegistration` (L119), `rejectRegistration` (L127), `setReadyForEdit` (L135). |
| `lib/features/events/presentation/attendees/attendees_page.dart` | Pasa `getIt<AnalyticsService>()` al constructor manual de `AttendeesCubit` dentro de `BlocProvider.create` (L20-26). **Cableado manual**: build_runner no lo toca. |
| `lib/features/event_registration/presentation/my_registrations_cubit.dart` | `@injectable` (L11); añade `AnalyticsService` (recableado por build_runner); emite `registration_my_list_viewed` en `fetchMyRegistrations` + cancelar si existe. |
| `lib/core/services/analytics/<constants>.dart` (fase 2) | Añade las constantes `events_*` y `registration_*` de esta fase si no existen aún (extensión de la taxonomía de fase 2). |
| `lib/core/di/injection.config.dart` (generado) | Regenerado por build_runner para inyectar `AnalyticsService` en los 4 cubits `@injectable`. No editar a mano. |
| `lib/main.dart` (verificación, sin cambio esperado) | Confirmar que `getIt.get<MyRegistrationsCubit>()` (L69) sigue compilando tras regenerar; solo ajustar si la resolución cambia (no esperado: no usa args posicionales ahí). |
| `test/features/events/.../event_form_cubit_test.dart`, `event_delete_cubit_test.dart`, `attendees_cubit_test.dart`, `test/features/event_registration/.../registration_form_cubit_test.dart`, `my_registrations_cubit_test.dart` | Tests nuevos/ampliados con mock de `AnalyticsService` que verifican los call sites. |

## Contratos / API rideglory-api (o "ninguno")

**Ninguno.** Toda la instrumentación es client-side. No se toca ningún endpoint de
`event_registration` ni de `events`; los use cases existentes (`ApproveRegistrationUseCase`,
`RejectRegistrationUseCase`, `SetRegistrationReadyForEditUseCase`, `GetEventRegistrationsUseCase`,
etc.) se invocan sin cambios. `GET /me` no se toca.

## Cambios de datos / migraciones (o "ninguno")

**Ninguno.** No hay migración de BD ni nueva persistencia local. El único "recableado" es de DI:
build_runner regenera la inyección de `AnalyticsService` para los **cuatro cubits `@injectable`**
(`EventFormCubit`, `EventDeleteCubit`, `RegistrationFormCubit`, `MyRegistrationsCubit`).
`AttendeesCubit` **no** participa de esa regeneración: su dependencia se inyecta a mano en
`attendees_page.dart` (L20-26) porque la clase no está anotada `@injectable`. Se verifica que la
resolución de `MyRegistrationsCubit` por `getIt` en `main.dart` L69 siga válida tras regenerar.

## Criterios de aceptación (numerados, observables, testeables)

1. **DebugView — embudo crear-evento.** Abrir el formulario de creación, guardar borrador y
   publicar emiten `events_create_started → events_draft_saved → events_published` con nombres de
   la taxonomía. **`events_create_step_advanced` solo aplica si/ cuando el formulario expone
   secciones discretas navegables**; mientras `EventFormCubit` no tenga pasos discretos, el embudo
   verificable es `events_create_started → events_draft_saved/events_published` (sin paso
   intermedio), y la ausencia de `events_create_step_advanced` NO se considera fallo (de lo
   contrario el criterio sería inverificable por diseño).
2. **DebugView — embudo registro.** Recorrer el wizard de registro emite `registration_started`,
   un `registration_step_advanced` por avance de paso (y `registration_step_back` por retroceso),
   y `registration_submitted` al envío exitoso; un fallo emite `registration_submit_failed`.
3. **DebugView — workflow de aprobación.** Aprobar/rechazar/marcar "listo para editar" un registro
   emite `registration_approved` / `registration_rejected` / `registration_ready_for_edit`
   respectivamente; un fallo emite `registration_approval_failed` con `action`.
4. **Estados de embudo por paso multistep (condicional para creación).** Para el **registro**
   (wizard real con `RegistrationWizardController`), cada avance/retroceso emite su evento
   distinguible (avance vs abandono), verificable con mock contando llamadas. Para **creación**,
   los estados por paso solo son verificables si el formulario expone secciones discretas; de no
   ser así, este criterio se cumple con el embudo `started → draft_saved/published` y
   `events_create_step_advanced` queda **inverificable por diseño** (no exigible).
5. **Sin PII / sin alta cardinalidad.** Ningún param lleva id de evento, id de registro ni id/uid
   de rider como valor; razones de fallo van **categorizadas**, no el mensaje crudo. Verificable
   por inspección de params en DebugView y por grep en los call sites.
6. **G1 — cero literales.** `grep -rn "logEvent(" lib/features/events/presentation lib/features/event_registration` no muestra literales directos; todo vía constante de taxonomía.
7. **Cableado correcto de `AttendeesCubit`.** `attendees_page.dart` pasa `getIt<AnalyticsService>()`
   al constructor; `AttendeesCubit` sigue sin anotación `@injectable` y el approval funciona.
   `dart analyze` limpio.
8. **Tests con mock.** Al menos un test por cubit instrumentado verifica el call site:
   `EventFormCubit` (draft/publish), `EventDeleteCubit`, `RegistrationFormCubit`
   (step advance + submit), `AttendeesCubit` (**aprobar un registro dispara
   `registration_approved`**), `MyRegistrationsCubit`. Todos con no-op/mock de `AnalyticsService`.
9. **Sin UI / sin regresión.** No se añade ni cambia ninguna pantalla, navegación ni
   comportamiento funcional de crear/publicar/registrar/aprobar. `flutter test` y `dart analyze`
   verdes; captura off en `kDebugMode`, no-op en tests.

## Pruebas (unitarias/widget/integración)

- **Unitarias (foco principal):**
  - `event_form_cubit_test.dart`: con mock de `AnalyticsService`, `saveDraft()` dispara
    `events_draft_saved`; publicar exitoso dispara `events_published`; fallo dispara
    `events_publish_failed`.
  - `event_delete_cubit_test.dart`: borrado exitoso/fallido dispara los eventos correspondientes.
  - `registration_form_cubit_test.dart`: `onStepAdvanced` dispara `registration_step_advanced` con
    `step_index`; envío exitoso dispara `registration_submitted`.
  - `attendees_cubit_test.dart`: **aprobar un registro (mock de use case OK) dispara exactamente un
    `registration_approved`** y ningún param con id de registro/rider como valor; rechazo y
    ready-for-edit análogos; fallo del use case dispara `registration_approval_failed`.
  - `my_registrations_cubit_test.dart`: `fetchMyRegistrations()` dispara
    `registration_my_list_viewed`.
- **Widget (mínimo):** smoke test de `RegistrationFormContent` que verifique que `_onNext` (L116)
  invoca `onStepAdvanced` en el cubit (mock), sin romper la navegación del wizard. Opcional si la
  cobertura unitaria del cubit ya es suficiente.
- **Integración:** no requerida; la verificación e2e es manual vía DebugView (criterios 1-3) más
  la auditoría no-PII transversal de la fase 10.
- **Gating:** todos los tests usan la no-op impl (fase 1) + `setEnabled(false)`; ningún test envía
  eventos reales.

## Riesgos y mitigaciones

1. **`EventFormCubit` no tiene pasos discretos.** El embudo "por pasos" de creación no es
   verificable hoy. *Mitigación:* `events_create_step_advanced` declarado **condicional**; el
   embudo de creación se reduce a `started → draft_saved/published` (criterios 1 y 4 lo reflejan).
2. **`AttendeesCubit` no es `@injectable` (cableado manual).** Si se añade el parámetro al
   constructor pero no se actualiza `attendees_page.dart`, no compila. *Mitigación:* el paso 6 y la
   tabla de archivos fijan explícitamente el cambio en `attendees_page.dart` L20-26 con
   `getIt<AnalyticsService>()`; build_runner no aplica aquí.
3. **Doble-conteo de errores.** Fallos de red de approve/publish ya se reportan como no-fatales en
   `handlerExceptionHttp` (fase 4). *Mitigación:* en estos cubits se emiten **eventos GA4 de
   embudo** (`*_failed`), no no-fatales de Crashlytics; los cubits no re-reportan errores de red.
4. **PII / alta cardinalidad.** Ids de evento/registro/rider, nombres, placas. *Mitigación:* regla
   "nunca el valor dinámico"; params agregados/categóricos; auditoría transversal fase 10
   (criterio 5).
5. **Referencias de línea desfasadas.** Si el código evoluciona, los L116/L123/L409/L162/L20-26
   pueden moverse. *Mitigación:* las citas anclan a métodos nombrados (`saveDraft`, `_onNext`,
   `_onBack`, `approveRegistration`, `BlocProvider.create`), no solo al número de línea.
6. **`registration_abandoned` poco fiable** (dispose puede no ejecutarse en todos los cierres).
   *Mitigación:* declarado "mejor esfuerzo"; no bloquea criterios.
7. **Regeneración DI rompe `main.dart`.** *Mitigación:* paso 7 + tabla verifican que
   `getIt.get<MyRegistrationsCubit>()` (L69) compile tras `build_runner`; no usa args posicionales
   ahí, así que no se espera ajuste manual.

## Dependencias (fases prerequisito y por qué)

- **Fase 1 (fundaciones):** provee la abstracción `AnalyticsService` ampliada, la no-op impl para
  tests, el gating (`setEnabled(false)` / no-report en `kDebugMode`) y la regla de capa. Sin ella
  no hay dónde emitir ni cómo testear sin enviar eventos reales.
- **Fase 2 (taxonomía + límites GA4):** provee las constantes `events_*`/`registration_*` y la
  convención de límites (≤40/≤40/≤100, `Object`, sin `bool`). Esta fase **consume** y, de ser
  necesario, extiende ese catálogo; sin él se violaría G1 (cero literales).
- **Fase 6 (núcleo de eventos — lectura):** es la primera mitad del split; comparte taxonomía y
  patrón de instrumentación del feature `events`. Hacer 6 antes evita duplicar/colisionar
  constantes y mantiene fases comparables y revisables (la 7 escribe sobre lo que 6 ya estableció
  para el dominio de eventos).
