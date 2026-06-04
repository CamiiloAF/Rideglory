# Fase 2 — Taxonomía centralizada, mapa de rutas, límites GA4 y migración soat

> Plan: `analytics-crashlytics-cobertura-total` · Fase id: **2** (de 11) · dependsOn: **[1]**
> Fecha (UTC): 2026-06-04T01:15:09Z
> Sesión de PLANEACIÓN — este documento NO modifica código de la app.
> Insumos: `05-sintesis.md` (filas 2 y 3 de la tabla final), `01-scan.md`, `03-architect-review.md`.

## Objetivo

El analista tiene un **catálogo único, documentado y sin PII** de nombres de eventos y de
parámetros, más el **mapa canónico ruta→nombre estable** (insumo de la fase 3) y las
**reglas de límites GA4**, de modo que toda la instrumentación de las fases 3–9 reutilice
estas constantes en lugar de strings mágicos. Como primera aplicación práctica, los 3
eventos de `soat` que hoy son literales se migran a las constantes y sus params se auditan
contra el checklist no-PII.

Estado de captura (síntesis, fila 2): **sin UI / sin regresión**. Captura activa en release
(soat normalizado, mismos eventos que hoy), off en debug, no-op en tests (mock en el test
del use case de soat).

## Alcance (entra / no entra)

**Entra:**
- Clases de **constantes Dart puras** en `lib/core/services/analytics/`:
  - Nombres de evento (snake_case, prefijo por feature) — incluye los 3 de soat ya existentes.
  - Claves de parámetros reutilizables (snake_case).
  - El **mapa canónico ruta→nombre de pantalla estable** (sin `:id`, sin params), cubriendo
    las rutas nombradas del router.
- La **convención de límites GA4** documentada y codificada como guía (no como validador
  en runtime): nombre de evento ≤40, param key ≤40, value string ≤100, `parameters` de
  tipo `Map<String, Object>`, **sin `bool` → usar `0/1` (int)**.
- **Doc de taxonomía + política no-PII** en `docs/` (catálogo de eventos/params + checklist
  de campos prohibidos).
- **Migración de los 3 eventos soat** (`soat_scan_attempted` / `soat_scan_success` /
  `soat_scan_failed`) en `scan_soat_usecase.dart` a las constantes, y **auditoría no-PII de
  sus params**: el param `insurer_detected` hoy envía el **nombre de la aseguradora**
  (alta cardinalidad / cuasi-PII) → se reemplaza por un booleano-como-0/1 `insurer_detected`
  (1 = aseguradora reconocida, 0 = ninguna), sin el string del nombre.
- Actualización de `docs/features/soat.md` (L378) para reflejar el cambio del param.
- **Test unitario** del use case de soat con **mock de `AnalyticsService`**, verificando que
  emite las **constantes** esperadas (no literales) y los params normalizados.

**No entra:**
- Ampliar la interfaz `AnalyticsService` (`logScreenView`/`setUserId`/`setUserProperty`/
  `setEnabled`) ni `CrashReporter` → eso es de la **fase 1**.
- Registrar el `NavigatorObserver` ni emitir `screen_view` → eso **consume** el mapa de
  rutas pero se implementa en la **fase 3**.
- Instrumentar cualquier otro feature (auth, events, etc.) → fases 5–9.
- Validación en runtime de los límites GA4 (solo convención + doc; el truncado lo hace GA4).
- Cambios en `rideglory-api` o en `GET /me`.

## Que se debe hacer (pasos concretos y ordenados)

1. **Verificar el grep base (estado pre-migración).** Confirmar que hoy
   `grep -rn "logEvent(" lib/ | grep -v "AnalyticsEvents\." | grep -v "lib/core/services/analytics/"`
   devuelve exactamente **3** líneas, todas en `scan_soat_usecase.dart` (líneas 34, 69, 81).
   Esto fija la línea base verificable para el criterio de aceptación 2.
2. **Crear `lib/core/services/analytics/analytics_events.dart`** — clase `AnalyticsEvents`
   con `static const` para cada **nombre de evento** (snake_case, prefijo por feature).
   Incluir como mínimo los 3 de soat: `soatScanAttempted = 'soat_scan_attempted'`,
   `soatScanSuccess = 'soat_scan_success'`, `soatScanFailed = 'soat_scan_failed'`.
   Documentar en doc-comment la convención de naming y el límite de 40 chars por nombre.
3. **Crear `lib/core/services/analytics/analytics_params.dart`** — clase `AnalyticsParams`
   con `static const` para las **claves de parámetros** reutilizables
   (`fieldsExtractedCount = 'fields_extracted_count'`, `insurerDetected = 'insurer_detected'`,
   `hadPdf = 'had_pdf'`, `failureReason = 'failure_reason'`, etc.). Doc-comment con la regla
   de ≤40 chars por key y ≤100 por value string.
4. **Crear `lib/core/services/analytics/analytics_screen_names.dart`** — el **mapa canónico
   ruta→nombre de pantalla estable**. Mapear cada nombre de `AppRoutes`
   (`lib/shared/router/app_routes.dart`) a un nombre de pantalla estable **sin id ni params**
   (p.ej. `event_detail_by_id` → `event_detail`, `vehicle_detail` → `vehicle_detail`). Debe
   cubrir **todas** las rutas nombradas del router. Exponerlo como un `Map<String,String>`
   const o getter puro, consumible por la fase 3.
5. **Codificar la convención de límites GA4** como doc-comments en las clases anteriores y en
   el doc de taxonomía: nombre evento ≤40, param key ≤40, value string ≤100, `parameters`
   siempre `Map<String, Object>`, **prohibido `bool`** (usar `int` 0/1).
6. **Escribir `docs/features/analytics-taxonomy.md`** (o equivalente bajo `docs/`): catálogo
   de eventos+params por feature (arrancando con soat + el mapa de rutas) y la **política
   no-PII** (lista de campos prohibidos: email, nombre, placa, VIN, **nombre de aseguradora**,
   coordenadas lat/lng, ids dinámicos de evento/registro/rider; uid solo hasheado).
7. **Auditar y migrar el param `insurer_detected` de soat.** Hoy
   `scan_soat_usecase.dart` L69-75 envía `'insurer_detected': extraction.insurer ?? 'none'`
   (el **string del nombre de la aseguradora**). Reemplazarlo por un valor agregado
   booleano-como-0/1: `AnalyticsParams.insurerDetected: extraction.insurer != null ? 1 : 0`.
   **`docs/features/soat.md` L378 SÍ documenta `insurer_detected` dentro de
   `soat_scan_success`** → actualizar esa línea para describir el nuevo valor: `insurer_detected`
   pasa a ser **0/1 (aseguradora detectada / no detectada)**, ya no el nombre de la
   aseguradora. (No es condicional: la línea existe y debe editarse.)
8. **Migrar los 3 literales de soat a constantes** en `scan_soat_usecase.dart`:
   `'soat_scan_attempted'` → `AnalyticsEvents.soatScanAttempted`,
   `'soat_scan_success'` → `AnalyticsEvents.soatScanSuccess`,
   `'soat_scan_failed'` → `AnalyticsEvents.soatScanFailed`, y las keys de params a
   `AnalyticsParams.*`. No cambia la firma del use case ni su comportamiento observable
   (mismos nombres de evento en GA4).
9. **Escribir/actualizar el test** `test/features/soat/.../scan_soat_usecase_test.dart` con un
   **mock de `AnalyticsService`**: verificar que `call(...)` emite
   `AnalyticsEvents.soatScanAttempted` al inicio, y en el camino feliz
   `AnalyticsEvents.soatScanSuccess` con `insurerDetected ∈ {0,1}` y `hadPdf ∈ {0,1}`
   (nunca el string de la aseguradora), y en fallo `AnalyticsEvents.soatScanFailed` con
   `failureReason`.
10. **Re-verificar el grep G1 (estado post-migración).** Tras migrar, correr de nuevo
    `grep -rn "logEvent(" lib/ | grep -v "AnalyticsEvents\." | grep -v "lib/core/services/analytics/"`.
    Debe devolver **0 líneas**: los 3 call sites de soat ahora usan `AnalyticsEvents.*` (se
    excluyen por el primer `grep -v`), y la firma de la interfaz + el forwarder de
    `firebase_analytics_service.dart` se excluyen por `grep -v "lib/core/services/analytics/"`.
    (Hoy el comando da 3; tras la migración da 0 — es la prueba de que la migración ocurrió.)
11. Correr `dart run build_runner build --delete-conflicting-outputs` (no hay codegen nuevo
    de DI, pero mantener la suite consistente) y `dart analyze` limpio sobre los archivos
    nuevos/modificados; `flutter test` del use case en verde.

## Archivos a crear/modificar (rutas reales, una linea de "que cambia")

| Ruta | Qué cambia |
|---|---|
| `lib/core/services/analytics/analytics_events.dart` | **Nuevo.** Clase `AnalyticsEvents` con `static const` de nombres de evento (incluye los 3 de soat). |
| `lib/core/services/analytics/analytics_params.dart` | **Nuevo.** Clase `AnalyticsParams` con `static const` de claves de parámetros reutilizables. |
| `lib/core/services/analytics/analytics_screen_names.dart` | **Nuevo.** Mapa canónico ruta→nombre de pantalla estable (sin `:id`), insumo de la fase 3. |
| `lib/features/soat/domain/usecases/scan_soat_usecase.dart` | Reemplaza los 3 literales por `AnalyticsEvents.*` y las keys por `AnalyticsParams.*`; `insurer_detected` pasa de nombre-de-aseguradora a `0/1`. |
| `docs/features/analytics-taxonomy.md` | **Nuevo.** Catálogo de eventos/params por feature + política no-PII + convención de límites GA4. |
| `docs/features/soat.md` (L378) | Actualiza la línea de telemetría: `insurer_detected` ahora es `0/1` (detectada/no detectada), ya no el nombre de la aseguradora. |
| `test/features/soat/domain/usecases/scan_soat_usecase_test.dart` | Crea/actualiza el test con mock de `AnalyticsService` verificando constantes y params normalizados. |

> Nota de ruta: el router declara los nombres en `AppRoutes`
> (`lib/shared/router/app_routes.dart`) y las `GoRoute(name: ...)` en
> `lib/shared/router/app_router.dart`. El mapa de la fase 2 se construye sobre los nombres de
> `AppRoutes` (verificado: el router usa `name: AppRoutes.<x>` en cada ruta, p.ej.
> `eventDetailById` en `app_router.dart`; hay 32 rutas nombradas — el "~37" de la síntesis es
> aproximado e incluye redirecciones/variantes).

## Contratos / API rideglory-api (o "ninguno")

**Ninguno.** Toda la analítica es client-side. Esta fase solo crea constantes, un mapa de
rutas y migra un call site existente. No se tocan endpoints, DTOs ni `GET /me`.

## Cambios de datos / migraciones (o "ninguno")

**Ninguno.** No hay migraciones de BD ni nueva persistencia local. No se serializan modelos
de API (no es Pattern B). El único "cambio de dato" es semántico y de payload de analítica:
`insurer_detected` deja de viajar como string del nombre y viaja como `int` 0/1.

## Criterios de aceptacion (numerados, observables, testeables)

1. **DebugView — eventos soat normalizados.** Tras la migración, ejecutar un escaneo SOAT en
   build con DebugView muestra los **3 eventos** (`soat_scan_attempted`, `soat_scan_success`,
   `soat_scan_failed`) con **los mismos nombres normalizados** que hoy (los nombres de string
   no cambian; solo dejan de ser literales en código).
2. **G1 — grep de `logEvent` con literal = 0 (observable y verificable a 0).** El comando
   `grep -rn "logEvent(" lib/ | grep -v "AnalyticsEvents\." | grep -v "lib/core/services/analytics/"`
   devuelve **exactamente 0 líneas** tras la migración. (Línea base **verificada hoy = 3**,
   los 3 call sites de soat; el `grep -v "AnalyticsEvents\."` excluye los call sites ya
   migrados y el `grep -v "lib/core/services/analytics/"` excluye la firma de la interfaz y el
   forwarder de `firebase_analytics_service.dart`. Así el criterio pasa de 3 → 0 con la
   migración, y NO daría 0 sin ella — es verificable en ambos sentidos.)
3. **Params soat agregados/booleanos, sin campos del documento.** Inspección de
   `soat_scan_success` confirma `fields_extracted_count` (int), `insurer_detected` ∈ **{0,1}**
   y `had_pdf` ∈ {0,1}; **no** aparece el nombre de la aseguradora, ni placa, ni texto del
   documento. `soat_scan_failed` solo lleva `failure_reason` (valor enumerado).
4. **Mapa de rutas completo, estable y sin `:id`.** `analytics_screen_names.dart` mapea
   **todas** las rutas nombradas de `AppRoutes` a un nombre de pantalla estable; ninguna
   entrada contiene `:id`, params ni ids dinámicos (p.ej. `event_detail_by_id` → `event_detail`).
   Verificable comparando las claves del mapa contra los `name:` de `app_router.dart`.
5. **Doc de taxonomía + política no-PII existe y lista los campos prohibidos.**
   `docs/features/analytics-taxonomy.md` contiene el catálogo soat + el mapa de rutas + la
   convención de límites GA4 + la lista explícita de campos prohibidos (email, nombre, placa,
   VIN, nombre de aseguradora, coordenadas, ids dinámicos).
6. **`docs/features/soat.md` L378 actualizado.** La línea de telemetría describe
   `insurer_detected` como `0/1` (detectada/no detectada), sin mencionar que viaje el nombre.
7. **Test verde con mock.** El test del use case de soat usa un mock de `AnalyticsService`,
   verifica que se emiten las **constantes** `AnalyticsEvents.*` (no literales) y que
   `insurer_detected` nunca es un string de nombre. `dart analyze` limpio; `flutter test`
   del archivo en verde.

## Pruebas (unitarias/widget/integracion)

- **Unitaria (obligatoria):** `scan_soat_usecase_test.dart` con mock de `AnalyticsService`
  (p.ej. `mocktail`/`bloc_test` ya disponible). Casos:
  - camino feliz → `soatScanAttempted` + `soatScanSuccess` con `insurerDetected ∈ {0,1}`,
    `hadPdf ∈ {0,1}`, `fieldsExtractedCount` int.
  - fallo (OCR vacío / validación de fechas / baja confianza) → `soatScanAttempted` +
    `soatScanFailed` con `failureReason` enumerado.
  - aserción negativa: ningún `verify` recibe el string de la aseguradora como valor de param.
- **Verificación manual (DebugView):** correr un escaneo y confirmar los 3 eventos con nombres
  normalizados y params sin PII.
- **Verificación estática (grep G1):** correr el comando del criterio 2 y confirmar `0`.
- No se requieren widget/integration tests: la fase no añade UI ni navegación.

## Riesgos y mitigaciones

1. **El mapa de rutas se desincroniza del router.** *Mitigación:* construir el mapa sobre los
   nombres de `AppRoutes` (fuente única) y dejar el criterio 4 que compara claves del mapa
   contra los `name:` del router; documentarlo en el doc de taxonomía.
2. **El grep G1 da falsos positivos/negativos si se reformula mal.** *Mitigación:* usar
   exactamente el comando del criterio 2 (doble `grep -v`), validado contra la línea base de
   3 hoy → 0 post-migración.
3. **Pérdida de señal del nombre de aseguradora al pasar a 0/1.** *Mitigación:* es una decisión
   de privacidad deliberada (cuasi-PII / alta cardinalidad); el equipo de parser ya tiene
   `fields_extracted_count` y `failure_reason` para diagnóstico. Documentado en el doc de
   taxonomía como decisión.
4. **`bool` silenciosamente descartado por GA4.** *Mitigación:* la convención prohíbe `bool`
   y exige `int` 0/1; `had_pdf` e `insurer_detected` ya cumplen.
5. **Regresión accidental en comportamiento de soat al migrar.** *Mitigación:* el test cubre
   ambos caminos; los nombres de evento string no cambian (solo dejan de ser literales).

## Dependencias (fases prerequisito y por que)

- **Fase 1 (prerequisito directo, dependsOn: [1]).** La fase 1 fija la **regla de capa (G0)**
  —`AnalyticsService` es una abstracción pura en `core/` consumible por domain— que legitima
  el call site de soat (domain) sin refactor, y provee la **no-op impl** que el test de esta
  fase usa como gating. Sin esa regla, migrar el call site de soat carecería de la decisión
  arquitectónica que lo respalda; sin la no-op impl, el test no podría correr sin enviar
  eventos reales.
- **Habilita la fase 3:** el `analytics_screen_names.dart` de esta fase es el **insumo
  directo** del `NavigatorObserver` de screen_view (fase 3) y de la convención de límites GA4
  que reutilizan las fases 3–9.
