# Fase 3 — Recorrido de pantallas automático (screen_view)

- Slug: `analytics-crashlytics-cobertura-total`
- Fase: **3** | dependsOn: **[1, 2]**
- Fecha (UTC): 2026-06-04T01:10:57Z
- Sesión: PLANEACIÓN (no se modifica código de la app; este archivo solo describe el trabajo)
- Estado de captura: **sin UI / sin regresión de comportamiento**. Activa en release, **off en debug** (la impl no-op y/o `kDebugMode` no emiten), **no-op en tests** (mock de `AnalyticsService`).

## Objetivo

El analista ve en GA4 (DebugView y reportes) **por qué pantallas pasa cada rider y dónde se queda**, sin instrumentar pantalla por pantalla. Se logra registrando **un único `NavigatorObserver`** en el `GoRouter` raíz que traduce cada transición de navegación a un `screen_view` con **nombre canónico estable, sin ids ni params**, reutilizando el **mapa canónico ruta→nombre** que entrega la fase 2.

La instrumentación cubre dos planos con responsabilidades separadas:
- **Observer raíz** → todas las rutas top-level (pushes/replaces sobre el `_rootNavigatorKey`) y el **push inicial** de cada branch del shell.
- **Listener de índice del shell** → los **cambios de pestaña** del `StatefulShellRoute.indexedStack`, que el observer raíz **no** ve (ver más abajo el porqué).

## Alcance (entra / no entra)

**Entra:**
- Un `NavigatorObserver` (`AnalyticsRouteObserver`) en `lib/shared/router/`.
- Su registro en `GoRouter.observers` del router raíz (`app_router.dart` L63).
- La emisión de `screen_view` para la activación de pestañas del `StatefulShellRoute.indexedStack`, resuelta en el **shell builder** (`MainShell`, observando `navigationShell.currentIndex`), no en el observer.
- Dedupe explícito para que cada activación de tab emita **exactamente un** `screen_view` y `pushReplacement` no genere doble.
- Consumo del mapa canónico de rutas de la fase 2 (precondición verificada en el paso 1).
- Respeto del gating (debug/tests) ya provisto por la fase 1.
- Test unitario del observer y del mecanismo de tabs con mock de `AnalyticsService`.

**No entra:**
- Cambios de UI, de comportamiento de navegación o de orden de rutas.
- Instrumentación de eventos de dominio/embudos por feature (fases 5–9).
- Modificar el contrato del mapa canónico (lo fija la fase 2; aquí solo se consume).
- Cambios en `rideglory-api`, DTOs, migraciones o setup nativo (eso es fase 1/4).
- Logging por ping/WS (fase 8) ni `setUserId`/user properties (fase 5).

## Que se debe hacer (pasos concretos y ordenados)

### Paso 1 — Verificar la precondición del mapa canónico (fase 2)

El observer **no puede asumir una API inexistente**. Antes de implementar, verificar que la fase 2 expone el mapa con esta **forma mínima requerida** (contrato cerrado que esta fase consume):

- Una clase de taxonomía en `lib/core/services/analytics/` (p.ej. `AnalyticsScreenNames`) que ofrece un **resolutor por path**:
  - `String? forPath(String path)` — devuelve el **nombre canónico estable sin id/param** para un `GoRoute.path` (clave = el `path` del `GoRoute`, p.ej. `'/events/detail-by-id'`), o `null` si la ruta no está mapeada.
  - Forma equivalente aceptable: un `Map<String, String>` `path → nombre` expuesto como constante, más una helper que haga el lookup. La regla load-bearing es: **la clave es el `path` del `GoRoute` (estable), nunca la URI concreta con valores**.
- El mapa **debe cubrir las ~37 rutas** declaradas en `app_router.dart` con nombre estable (criterio (d) de la fase 2).

Si la fase 2 aún no fija la firma exacta, esta fase la trata como **precondición bloqueante**: el observer se programa contra `AnalyticsScreenNames.forPath(String) -> String?`. Cualquier desviación se resuelve alineando la fase 2, no inventando lógica de nombres en el observer (un único punto de verdad para los nombres).

### Paso 2 — Resolver el nombre canónico desde un `Route`

El observer recibe `Route<dynamic>` en sus callbacks. La clave estable es `route.settings.name`. En este router `go_router` puebla `settings.name` con el **path del `GoRoute`** que generó la página (no la URI con valores), por lo que `event_detail_by_id` llega como `'/events/detail-by-id'` y NO como `'/events/detail-by-id?id=abc'`. Regla de resolución:

1. Tomar `route.settings.name` (el path del `GoRoute`).
2. `final nombre = AnalyticsScreenNames.forPath(name)`.
3. Si `nombre == null` (ruta no mapeada o `settings.name == null`) → **se omite** (no se emite `screen_view`, no se inventa nombre desde el path crudo para no filtrar segmentos dinámicos). Esto se cubre con la política de fallback cerrada (más abajo).

### Paso 3 — Implementar `AnalyticsRouteObserver`

`AnalyticsRouteObserver extends NavigatorObserver`, con `AnalyticsService` inyectado por constructor (no `getIt` dentro). Implementa:

- `didPush(Route route, Route? previousRoute)` → emite para **`route`** (la pantalla que entra).
- `didReplace({Route? newRoute, Route? oldRoute})` → emite para **`newRoute`** (la pantalla que entra). Cubre `pushReplacement`.
- `didPop(Route route, Route? previousRoute)` → emite para **`previousRoute`** (la pantalla que queda **revelada** al hacer pop), no para `route` (la que se va).

Regla por callback, sin la frase ambigua "el Route resultante":
- **didPush / didReplace** → nombre canónico calculado desde `route` / `newRoute`.
- **didPop** → nombre canónico calculado desde `previousRoute`.

Dedupe: el observer guarda `String? _lastEmittedName` y **no re-emite** si el nombre canónico calculado es igual al último emitido. Esto neutraliza:
- `pushReplacement` que dispara `didReplace` hacia la **misma** pantalla lógica → no duplica.
- Pops sucesivos que revelan la misma pantalla.
- Cualquier doble callback hacia el mismo nombre canónico.

Emisión: `analyticsService.logScreenView(screenName)` (método añadido a la interfaz en la fase 1). El gating vive en la impl (no-op/`setEnabled(false)`/`kDebugMode`), el observer **no** consulta `kDebugMode`.

### Paso 4 — Cubrir el `StatefulShellRoute.indexedStack` (mecanismo REAL)

**Por qué el observer no basta para los tabs.** El `StatefulShellRoute.indexedStack` mantiene **un Navigator vivo por branch** dentro de un `IndexedStack`. Cambiar de pestaña (`navigationShell.goBranch(i)`) **solo cambia el índice del `IndexedStack`**: no hay `push`/`pop`/`replace` en ningún Navigator, por lo que **no se dispara ningún callback del `NavigatorObserver` raíz**. Un test que simule `didPush` para "cambio de tab" sería falso: ese `didPush` no ocurre.

**Dependencia de `route.notifyRootObserver` (go_router 17, `route.dart` L504-507, default `true`).** Este flag es lo único que hace que los observers del router raíz se **reenvíen** a los Navigators de cada branch (vía el `_MergedNavigatorObserver` interno de go_router). Gracias a él, el observer raíz **sí** ve el `didPush` del **push inicial** de la ruta hija de un branch la **primera vez** que ese branch se construye (p.ej. el primer `home` al entrar al shell). No lo cambiamos (se deja en su default `true`); esta fase **verifica** que con `notifyRootObserver == true` el observer raíz recibe ese push inicial. Lo que el flag **no** hace es generar eventos al **re-seleccionar** un branch ya construido (solo cambia el índice): de ahí la necesidad del listener de índice.

**División de responsabilidades (cerrada):**
- **Observer raíz** = rutas top-level + push inicial de cada branch (lo da `notifyRootObserver`).
- **Listener de índice del shell** = activaciones/reactivaciones de pestaña.

**Mecanismo del shell (reescritura del sub-bullet del shell):** detectar el cambio de pestaña observando **`navigationShell.currentIndex`** en el shell builder (`MainShell`, `app_router.dart` L142-147 → widget en `lib/shared/widgets/main_shell.dart`). Implementación:

1. Extraer una pieza dedicada (un widget/clase por archivo, sin métodos que retornen widgets) que recibe el `StatefulNavigationShell` y el `AnalyticsService`, y reacciona a cambios de `currentIndex` (p.ej. comparando el índice contra el último emitido en `didUpdateWidget`/`build` de un `StatefulWidget`). Al activarse el branch `i`:
   - Resolver el `GoRoute.path` de la **ruta hija raíz** del branch `i` mediante un **mapa fijo branch-index → path** declarado junto al shell (índice 0→`/home`, 1→`/garage`, 2→`/events`, 3→`/profile`), y de ahí el nombre canónico vía `AnalyticsScreenNames.forPath`.
   - Emitir `logScreenView` para ese branch **solo si el índice cambió** respecto al último emitido por el shell (dedupe por índice). Re-seleccionar el mismo tab consecutivamente → **0 emisiones**.
2. El dedupe del shell es **independiente** del `_lastEmittedName` del observer, pero comparten el mismo `AnalyticsService`. Para evitar doble-conteo entre "push inicial visto por el observer raíz" y "primera activación vista por el listener" en el arranque del shell, la **fuente única de verdad de los tabs es el listener de índice**; el observer raíz, al ver el push inicial del branch, emitirá el mismo nombre canónico y el dedupe por nombre (`_lastEmittedName`) lo absorbe — el resultado neto es **un solo** `screen_view` por activación. Verificable por test (ver Pruebas, criterio 2).

> Nota de routing real: los índices de branch son `home(0)`, `garage(1)`, `events(2)`, `profile(3)`. El botón "+" de la barra (`_addButtonBarIndex = 2` en `main_shell.dart`) **no** es un branch: hace `pushNamed(createEvent)`, que sí pasa por el observer raíz como ruta top-level. No requiere tratamiento especial en el listener de índice.

### Paso 5 — Registrar el observer en el router

En `app_router.dart`, el `GoRouter` (L63) hoy **no** define `observers`. Añadir `observers: <NavigatorObserver>[ ... ]` con la instancia de `AnalyticsRouteObserver`. Dado que el `GoRouter` es un `static final`, obtener el `AnalyticsService` para el observer (y para el listener del shell) desde el contenedor DI ya inicializado (`getIt<AnalyticsService>()`), de forma análoga a como el router ya usa `getIt.get<AuthCubit>()` (L107). No se introducen Cubits aquí (no aplica la regla anti-singleton de Cubits: esto es un observer/servicio, no un Bloc).

### Paso 6 — Política de fallback cerrada para las ~37 rutas

Regla global, **no diferida al implementador**: el nombre canónico siempre proviene de `AnalyticsScreenNames.forPath(path)`. Comportamiento determinista:

- **Toda ruta con `name`/`path` mapeado en la fase 2 → emite** con su nombre canónico estable sin id.
- **Rutas con parámetros** (`event_detail_by_id` = `/events/detail-by-id?id=...`) → emiten el nombre canónico (p.ej. `event_detail`), **nunca** la URI con `id`.
- **Rutas anidadas** como `editProfile` (`path: 'edit'`, fullPath `/profile/edit`): `settings.name` será el path completo del `GoRoute` anidado (`/profile/edit`). El mapa de la fase 2 **debe** tener entrada para `/profile/edit` → **emite**, con nombre `profile_edit`.
- **Caso `settings.name == null`** (p.ej. un Route interno de overlay/diálogo o una página sin `name`): `forPath` no resuelve → **se omite** (0 `screen_view`). No se cae, no se inventa nombre. En el árbol actual, **todas** las `GoRoute` declaran `name` (verificado en `app_router.dart`), así que la omisión por `name == null` solo aplica a routes no-go_router (diálogos/bottom sheets que empujen sus propias rutas) — y para esos **la política es omitir**, que es lo deseado (no son pantallas del recorrido).
- **Settings/ajustes:** no existe `settings_page` en el árbol (confirmado por la síntesis; el opt-out de la fase 11 vive dentro de `profile`). Por tanto **no hay** entrada de "settings" que mapear: **comportamiento cerrado — no se emite un `screen_view` propio de "settings"**; el recorrido de privacidad se observa vía `profile`/`profile_edit`.

Esta política es **testeable** (ver Pruebas): cada caso anterior tiene su aserción.

#### Cierre por ruta (~37) — emite / nombre canónico / omite

Nombres canónicos ilustrativos (los fija la fase 2; aquí se cierra el **comportamiento**: todas emiten salvo donde se indique).

| `GoRoute.path` (`settings.name`) | Comportamiento | Nombre canónico (de fase 2) |
|---|---|---|
| `/` (splash) | emite | `splash` |
| `/login` | emite | `login` |
| `/signup` | emite | `signup` |
| `/forgot-password` | emite | `forgot_password` |
| `/home` (branch 0) | emite (push inicial + tab) | `home` |
| `/garage` (branch 1) | emite (push inicial + tab) | `garage` |
| `/events` (branch 2) | emite (push inicial + tab) | `events` |
| `/events/mine` | emite | `events_mine` |
| `/profile` (branch 3) | emite (push inicial + tab) | `profile` |
| `/profile/edit` (anidada) | **emite** | `profile_edit` |
| `/vehicles/create` | emite | `vehicle_create` |
| `/vehicles/detail` | emite | `vehicle_detail` |
| `/vehicles/edit` | emite | `vehicle_edit` |
| `/maintenances` | emite | `maintenances` |
| `/maintenances/create` | emite | `maintenance_create` |
| `/maintenances/edit` | emite | `maintenance_edit` |
| `/maintenances/detail` | emite | `maintenance_detail` |
| `/events/drafts` | emite | `events_drafts` |
| `/events/create` | emite | `event_create` |
| `/events/edit` | emite | `event_edit` |
| `/events/detail` | emite | `event_detail` |
| `/events/registration` | emite | `event_registration` |
| `/events/attendees` | emite | `event_attendees` |
| `/events/live-map` | emite | `live_map` |
| `/events/participants` | emite | `participants` |
| `/events/my-registrations` | emite | `my_registrations` |
| `/events/registration-detail` | emite | `registration_detail` |
| `/events/detail-by-id?id=...` | emite (**sin id**) | `event_detail` |
| `/events/attendees/rider-profile` | emite | `rider_profile` |
| `/notifications` | emite | `notifications` |
| `/soat/status` | emite | `soat_status` |
| `/soat/manual-capture` | emite | `soat_manual_capture` |
| Cualquier `Route` con `settings.name == null` (diálogos/bottom sheets) | **omite** (0 eventos) | — |
| "settings" (no existe pantalla) | **omite** (no aplica) | — |

> `/events/detail` y `/events/detail-by-id` pueden mapearse al mismo nombre canónico `event_detail` (ambas muestran el detalle de un evento). Esa decisión la fija la fase 2; el observer solo aplica el mapa.

## Archivos a crear/modificar (rutas reales)

| Archivo | Qué cambia |
|---|---|
| `lib/shared/router/analytics_route_observer.dart` | **Nuevo.** `AnalyticsRouteObserver extends NavigatorObserver`; recibe `AnalyticsService`; implementa `didPush`/`didReplace`/`didPop` con resolución por callback (`route`/`newRoute`/`previousRoute`) y dedupe por `_lastEmittedName`. |
| `lib/shared/router/app_router.dart` | Añade `observers: [AnalyticsRouteObserver(getIt<AnalyticsService>())]` al `GoRouter` (L63). Declara el mapa fijo `branchIndex → path` del shell para el listener. No cambia rutas, orden ni `redirect`. |
| `lib/shared/widgets/shell_screen_view_tracker.dart` | **Nuevo** (o lógica dentro de `MainShell`). `StatefulWidget` que recibe el `StatefulNavigationShell` + `AnalyticsService`; en `didUpdateWidget`/`build` compara `currentIndex` contra el último emitido y dispara `logScreenView` con dedupe por índice. Un widget/clase por archivo; sin métodos que retornen widgets. |
| `lib/shared/widgets/main_shell.dart` | Si el tracker se aloja aquí: envuelve/inserta el `ShellScreenViewTracker` alrededor de `navigationShell` (no cambia layout ni `goBranch`). |
| `lib/core/services/analytics/analytics_service.dart` | (Dependencia de fase 1; ya provee `logScreenView`) se **consume**. Esta fase **no** lo modifica. |
| `lib/core/services/analytics/analytics_screen_names.dart` (o equivalente de fase 2) | (Dependencia de fase 2) se **consume** `forPath(String) -> String?`. Esta fase no lo crea. |

## Contratos / API rideglory-api

**Ninguno.** Toda la instrumentación es client-side. No hay endpoints, DTOs ni cambios de contrato. `notifyRootObserver` es API de `go_router` (paquete), no de la app ni del backend.

## Cambios de datos / migraciones

**Ninguno.** No hay persistencia nueva ni migraciones. (La clave de opt-out es de la fase 11.)

## Criterios de aceptacion (numerados, observables, testeables)

1. **Nombres estables sin id (rutas con params).** Navegar 5 rutas con parámetros (incluida `event_detail_by_id` = `/events/detail-by-id?id=...`) muestra en GA4 DebugView `screen_view` con **nombres canónicos sin id** (p.ej. `event_detail`), nunca la URI con `id`. Testeable: Pruebas T2.

2. **Cambio de pestaña del shell emite un único `screen_view` por activación, vía el mecanismo de índice.** Cambiar de tab en el `StatefulShellRoute.indexedStack` (activar un branch) produce **exactamente un** `logScreenView` con el nombre canónico del branch activado; **re-seleccionar el mismo tab consecutivamente produce 0**. Este criterio se valida simulando el **cambio de `currentIndex` del shell** (no un `didPush` del observer, que **no ocurre** al cambiar de tab). Testeable: Pruebas T4.

3. **`pushReplacement` no duplica.** Una transición vía `pushReplacement` (callback `didReplace`) hacia una pantalla genera **un solo** `screen_view`; si el nombre canónico coincide con el último emitido, el dedupe lo absorbe (0 extra). Testeable: Pruebas T3.

4. **Push inicial de branch visto por el observer raíz (notifyRootObserver).** Con `route.notifyRootObserver == true` (default go_router 17), el observer raíz recibe el `didPush` del **push inicial** de la ruta hija del branch; combinado con el listener de índice, el neto al entrar al shell es **un** `screen_view` para el branch inicial (sin doble-conteo). Testeable: Pruebas T5.

5. **`didPop` reporta la pantalla revelada.** Al hacer pop, el `screen_view` emitido corresponde al nombre canónico de `previousRoute` (la pantalla revelada), no de la que se cierra. Testeable: Pruebas T6.

6. **Fallback cerrado.** (a) `/profile/edit` emite `profile_edit`. (b) Un `Route` con `settings.name == null` o no mapeado **no** emite (0 `screen_view`) y no lanza. (c) No existe `screen_view` de "settings" (no hay tal pantalla). Testeable: Pruebas T7.

7. **Gating / sin regresión.** En tests con no-op + `setEnabled(false)` no se envían eventos reales; en `kDebugMode` no se reporta a GA4. La navegación de la app **no cambia de comportamiento** (orden de rutas, back stack y tabs intactos). `dart analyze` limpio.

## Pruebas (unitarias/widget/integracion)

Todas con **mock de `AnalyticsService`** (no DebugView). Archivos sugeridos: `test/shared/router/analytics_route_observer_test.dart` y `test/shared/widgets/shell_screen_view_tracker_test.dart`.

- **T1 — Resolución de nombre.** `didPush` con un `Route` cuyo `settings.name == '/events/detail-by-id'` → `logScreenView('event_detail')` exactamente 1 vez (mock de `AnalyticsScreenNames.forPath` o el mapa real de fase 2).
- **T2 — 5 rutas con params, sin id (criterio 1).** Simular `didPush` para 5 rutas (incluida una con `?id=`) → 5 `logScreenView` con nombres canónicos; **ninguno** contiene `id`/segmento dinámico.
- **T3 — `pushReplacement` no duplica (criterio 3).** `didReplace(newRoute: X)` hacia el mismo nombre que el último emitido → **0** emisiones extra; hacia un nombre distinto → 1 emisión.
- **T4 — Cambio de pestaña por índice (criterio 2).** Usar un **fake/mock del `StatefulNavigationShell`** (un doble que exponga `currentIndex`) e invocar el **listener de índice** con `currentIndex` 0→1→1→2: se esperan `logScreenView` para `garage` (al pasar a 1), **0** al repetir 1, y `events` (al pasar a 2) → total **2** emisiones, una por activación distinta. **No** se simula `didPush` para esto (no aplica al cambio de tab).
- **T5 — Push inicial de branch sin doble-conteo (criterio 4).** Simular el `didPush` inicial del branch (lo que `notifyRootObserver` reenvía) seguido de la primera activación del listener de índice: verificar **un solo** `logScreenView` neto para el branch inicial (el dedupe por `_lastEmittedName` absorbe el duplicado).
- **T6 — `didPop` revela `previousRoute` (criterio 5).** `didPop(route: B, previousRoute: A)` → `logScreenView(nombre(A))`, no `nombre(B)`.
- **T7 — Fallback cerrado (criterio 6).** (a) `didPush` con `settings.name == '/profile/edit'` → `logScreenView('profile_edit')`. (b) `didPush` con `settings.name == null` → **0** emisiones, sin excepción. (c) `didPush` con un `name` no mapeado → **0** emisiones.
- **T8 — Gating.** Con la impl no-op + `setEnabled(false)`, ninguna llamada del observer produce envío real (verificar que la no-op no toca el SDK); `flutter test` no intenta red.

## Riesgos y mitigaciones

1. **Suponer que el cambio de tab dispara el observer.** Es falso: el `IndexedStack` solo cambia índice. *Mitigación:* tabs cubiertos por listener de `currentIndex` (paso 4); test T4 simula el índice, no un `didPush`.
2. **Doble-conteo en el arranque del shell** (push inicial del branch + primera activación del listener). *Mitigación:* dedupe por `_lastEmittedName` en el observer + dedupe por índice en el listener; verdad única de tabs en el listener; test T5.
3. **Dependencia de `notifyRootObserver`.** Si una versión futura cambiara el default, el observer raíz dejaría de ver el push inicial del branch. *Mitigación:* no lo modificamos (default `true`) y T5 lo verifica; cualquier upgrade de go_router revalida este test.
4. **`settings.name` con valores dinámicos o `null`.** *Mitigación:* resolución solo por `forPath` con clave = path del `GoRoute`; fallback cerrado que omite (paso 6, T7); nunca se emite la URI cruda.
5. **PII / cardinalidad por id en el nombre.** *Mitigación:* nombres canónicos del mapa de fase 2; jamás `?id=`/segmentos dinámicos (criterio 1, T2).
6. **Mapa de fase 2 incompleto o con firma distinta.** *Mitigación:* precondición bloqueante (paso 1) contra `forPath(String) -> String?`; el observer no implementa lógica de nombres propia.
7. **Acoplar gating al observer.** *Mitigación:* el observer nunca consulta `kDebugMode`; el gating vive en la impl de `AnalyticsService` (fase 1).

## Dependencias (fases prerequisito y por que)

- **Fase 1** — provee: (a) la interfaz `AnalyticsService` ampliada con `logScreenView`; (b) la impl no-op + `setEnabled(false)` + handlers gateados en `kDebugMode` que esta fase reutiliza para el gating; (c) el cableado DI que permite `getIt<AnalyticsService>()` en el router. Sin esto, el observer no tiene método que llamar ni gating.
- **Fase 2** — provee el **mapa canónico ruta→nombre estable sin ids** (`AnalyticsScreenNames.forPath` o equivalente `Map<String,String>`) y las reglas de límites GA4. Sin esto, el observer no puede traducir paths a nombres estables sin reinventar la taxonomía (lo cual filtraría ids/params).
