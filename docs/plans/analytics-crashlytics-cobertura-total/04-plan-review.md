# 04 — Plan Review (UX móvil + calidad / Clean Architecture)

- Slug: `analytics-crashlytics-cobertura-total`
- Fecha (UTC): 2026-06-04T00:54:30Z
- Rol: Plan Reviewer (UX móvil 375px + calidad/Clean Architecture + rideglory-coding-standards)
- Insumos: `00-intake.md`, `01-scan.md`, `02-po-proposal.md`. Verificación de código: `lib/core/services/analytics/analytics_service.dart`, `lib/features/soat/domain/usecases/scan_soat_usecase.dart`, `lib/features/profile/presentation/widgets/profile_content.dart` + `profile_actions_list.dart`, `lib/shared/widgets/form/app_switch_tile.dart`.
- Veredicto: **ok_con_ajustes**.

## Resumen ejecutivo

La descomposición en 10 fases es sólida, bien ordenada (palancas baratas primero: F3 screen_view, F4 no-fatales; taxonomía F2 antes de instrumentar) y honesta sobre que F1-F9 **no tienen UX visible**. El único punto con superficie de UI real es **F10 (opt-out)**, y ahí la propuesta arrastra un supuesto incorrecto que hay que corregir antes de implementar: el opt-out **no** cae en un formulario, así que `AppSwitchTile` (que exige `FormBuilder`) no encaja tal cual. El resto de los ajustes son gates de calidad para que instrumentar 11 features no degrade la arquitectura ni filtre PII.

## UX por fase

**Principio transversal:** F1-F9 son cero-UI (criterio de éxito #7 del PO: sin regresión de comportamiento). Para esas fases el "estado" relevante no es idle/loading/empty/error de pantalla, sino **estado de la captura** (activa / desactivada por gating / no-op en tests). Eso debe quedar explícito por fase para que QA no busque pantallas que no existen.

| Fase | ¿UI visible? | Verificación UX / observabilidad | Estados a cubrir |
|---|---|---|---|
| F1 Fundaciones + crashes | No | App idéntica al usuario; crash de prueba en staging aparece simbolizado | Captura: activa(release) / off(debug) / no-op(tests). Verificar que un fallo de init Crashlytics **no** rompa el arranque (degradar silencioso, no pantalla en blanco) |
| F2 Taxonomía + migración soat | No | DebugView: 3 eventos soat siguen llegando con nombres normalizados | n/a |
| F3 screen_view auto | No | DebugView: secuencia de pantallas al navegar las ~37 rutas | Cubrir rutas con params (detail by id) → nombre estable sin id; rutas de shell/tabs no deben emitir doble screen_view |
| F4 no-fatales red | No | Provocar timeout/5xx → no-fatal categorizado en consola | Distinguir error-de-usuario (offline, 401 esperado) de error-accionable; lo primero no debe contar como no-fatal |
| F5 Auth/onboarding | No (no añade pantallas) | DebugView: embudo splash→login/signup→home | Marcar inicio/método/éxito/fallo/**abandono** (back, app a background sin completar) |
| F6 Núcleo eventos | No | DebugView: embudos crear-evento y registrarse/aprobar completos | Estados de embudo: inicio→avance→éxito vs abandono en cada paso multistep |
| F7 Tracking/SOS | No | Iniciar sesión tracking + SOS de prueba → eventos | **Solo hitos** (inicio/fin/SOS), nunca cada ping de ubicación (volumen/costo) |
| F8 Garaje/mant/SOAT | No | Agregar vehículo+mantenimiento → eventos | Embudos de form multistep (vehículo): paso alcanzado vs abandono |
| F9 Perfil/users/notif | No | Abrir notificación + editar perfil → eventos | Notificación: distinguir recibida vs abierta (engagement real) |
| **F10 Opt-out + verificación** | **Sí (única UI)** | Alternar opt-out → la colección se detiene/reanuda | **idle** (switch on/off según preferencia persistida) · **loading** (al persistir, si aplica) · **error** (si falla persistir SharedPreferences → revertir el switch y avisar) · **sin empty** |

**Detalle F10 — la única pantalla nueva (revisión 375px):**

1. **Ubicación.** El opt-out debe vivir en la sección **"Ajustes"** del perfil (`ProfileSectionLabel(profile_settings)` → `ProfileActionsList`), no en una pantalla nueva. Verificado: esa sección hoy es una **`Container`/`Column` de `ProfileMenuItem`** (icono + label + chevron + `ProfileMenuDivider`), **NO un `FormBuilder`**.
2. **Constraint crítico de widget.** `AppSwitchTile` (verificado en `lib/shared/widgets/form/app_switch_tile.dart`) es un **`FormBuilderField<bool>` y requiere un `FormBuilder` ancestro**; insertarlo dentro de `ProfileActionsList` sin envolverlo crashea o no persiste. La memoria del proyecto manda usar `AppSwitch`/`AppSwitchTile` y prohíbe Material/Cupertino switch, pero **no obliga al tile bound-a-form** en un contexto sin formulario. El plan debe decidir explícitamente entre: (a) usar el átomo **`AppSwitch`** (pill `value`/`onChanged`, sin form) dentro de una fila propia consistente con `ProfileMenuItem`; o (b) envolver un mini-`FormBuilder` solo para el tile. Recomendación: opción (a) — más simple, sin dependencia de form, respeta "un switch en toda la app".
3. **Texto oscuro sobre primario.** El knob del switch en estado "on" va **oscuro** (`darkBgPrimary`/`onPrimary`), nunca blanco. `AppSwitch` ya cumple; el plan solo debe prohibir explícitamente overrides.
4. **Touch target.** La fila completa (label + subtítulo + switch) debe ser tappable con alto ≥44px (el patrón `ProfileMenuItem` y el `GestureDetector` opaque de `AppSwitchTile` ya lo dan; replicarlo si se va por opción (a)).
5. **Copy ES** en `app_es.arb` con prefijo `profile_`/`privacy_`: label ("Compartir datos de uso anónimos" o similar), subtítulo explicando que es anónimo/sin datos personales, y mensaje de error si falla persistir. Sentence case.
6. **Default opt-in/opt-out** sigue siendo pregunta abierta #4 → el plan de F10 debe fijarlo (afecta el estado inicial del switch y la `privacy-policy.html`). No dejarlo "a confirmar en implementación".

## Gates de calidad (bloqueantes por fase)

**G0 — Regla de capa (resolver en F1, aplica a F2-F9).** Hoy `AnalyticsService` se inyecta en un **use case de domain** (`scan_soat_usecase.dart`, verificado: import de `core/services/analytics/...`, campo `_analytics`, 3 `logEvent`). El tech_lead bloquea imports de Flutter/HTTP/`BuildContext` en domain, pero la abstracción analítica es Dart puro, así que **es defendible que domain dependa de ella**. F1 DEBE fijar la regla por escrito (una sola): la abstracción vive en `core` (Dart puro, sin Flutter), y **domain/presentación consumen siempre la abstracción, nunca el SDK Firebase**. Sin esa decisión, instrumentar 11 features replica/propaga la ambigüedad. Gate: el reviewer de arquitectura valida que ningún call site importe `package:firebase_analytics`/`firebase_crashlytics` fuera de `core/services/.../firebase_*`.

**G1 — Cero strings mágicos (F2+).** Después de F2, todo nombre de evento/parámetro proviene de constantes centralizadas. Gate de F2: `grep` de `logEvent(` con string literal directo = 0 (los 3 de soat migrados). Cada fase posterior añade sus constantes a la taxonomía, no strings inline.

**G2 — Cero PII (F2 diseño + F10 auditoría, vigilado por fase).** Ningún nombre, parámetro, mensaje de error o custom key lleva email, placa, nombre, teléfono, coordenadas. Riesgo concreto verificado: el evento `soat_scan_success` ya manda parámetros — F2 debe auditar que sean agregados/booleanos, no campos del documento. F4 (no-fatales) es el mayor riesgo: los mensajes de `DioException`/`DomainException` pueden contener URLs con ids o cuerpos → sanitizar antes de `recordError`. Gate por fase: lista de eventos+params nuevos revisada contra checklist no-PII.

**G3 — Gating debug/tests + no-op (F1, reusado).** Un único mecanismo (decidido en F1) desactiva colección en debug y provee **no-op impl para tests**. Gate transversal: `flutter test` y `dart analyze` pasan sin intentar enviar eventos ni flakiness; cada fase que añade call sites añade su test con mock del `AnalyticsService`/`CrashReporter` (resuelve pregunta #8 — exigir test unitario de call site con mock, no solo DebugView manual).

**G4 — rideglory-coding-standards en F10 (única fase con widgets).** Un widget por archivo; sin métodos que retornan widgets; el opt-out es su propia clase widget en su propio archivo (no un `_buildOptOut()` dentro de `ProfileActionsList`); `AppSwitch`/`AppSwitchTile` (no Material/Cupertino/`FormBuilderSwitch`); knob oscuro sobre primario; strings en `app_es.arb`. Navegación: si el opt-out abre sub-pantalla, `context.pushNamed`.

**G5 — Sin doble-conteo (F4).** Un único punto de verdad por categoría de error: o `executeService` o cubits, no ambos para la misma categoría. Gate: documentar la matriz "categoría → único sitio que reporta".

**G6 — No romper arranque (F1).** El cableado `runZonedGuarded`/`FlutterError.onError`/`PlatformDispatcher.onError` y la init de Crashlytics no deben poder tumbar el `runApp`. Gate: fallo de init degrada silencioso.

## Riesgos de scope

1. **F6 sobredimensionada.** Agrupa `home` + todo `events` (listar/detalle/crear/publicar/borradores) + todo `event_registration` (registrar + workflow aprobar/rechazar/cancelar/ready-for-edit + mis-registros). Es la mayor superficie del repo (scan: "events es la mayor superficie"). Riesgo de fase que no cierra. **Ajuste:** considerar partir en 6a (home + events lectura: listar/detalle) y 6b (events escritura: crear/publicar/borradores + registration/aprobación), o al menos fijar un alcance mínimo verificable y mover lo demás a "nice-to-have de la fase".
2. **F10 mezcla tres cosas heterogéneas** (auditoría no-PII transversal + UI opt-out + doc de QA/checklist). La auditoría no-PII depende de que F2-F9 ya estén instrumentadas → bien que sea última, pero el esfuerzo de auditar 11 features + construir UI + escribir QA doc puede desbordar. **Ajuste:** que el plan de F10 separe claramente los 3 entregables y permita que la UI de opt-out se cierre aunque la auditoría tenga hallazgos pendientes (registrados como tareas, no bloqueando el opt-out).
3. **F7 volumen/costo del tracking en vivo.** Ya señalado por el PO; el riesgo real es que se instrumente por ping. **Ajuste:** el plan de F7 debe prohibir explícitamente loguear cada update de ubicación y enumerar los hitos exactos (start session, stop session, snapshot, SOS activado/confirmado/cerrado).
4. **F3 nombres de ruta inestables.** 37 rutas, varias con params (`detail_by_id`). Si el nombre de screen_view incluye el id se fragmenta la analítica y se filtra PII (id de evento). **Ajuste:** mapa de rutas → nombre legible **estable y sin params** centralizado junto a la taxonomía (F2 o inicio de F3); rutas de shell/tabs no deben duplicar screen_view.
5. **F1 setup nativo frágil** (Gradle plugin Android, dSYM iOS). Sin esto los crashes llegan sin símbolos y la fase "parece" hecha. **Ajuste:** criterio de aceptación de F1 = crash de prueba **simbolizado** en consola, no solo "el paquete compila".
6. **Anomalía de capa propagada (G0).** Si F1 no fija la regla, cada una de F5-F9 puede introducir su propia variante. Ya cubierto por G0; lo marco como riesgo de scope porque su no-resolución multiplica el costo de revisión en 5 fases.

## Ajustes

1. **F10 / UI opt-out:** no usar `AppSwitchTile` (bound a `FormBuilder`) dentro de `ProfileActionsList` —que NO es un form—. Usar el átomo `AppSwitch` en una fila propia (clase widget propia, archivo propio) consistente con `ProfileMenuItem`, o envolver un `FormBuilder` dedicado. Recomendado: `AppSwitch` sin form. Knob "on" oscuro, nunca blanco.
2. **F10:** fijar el **default opt-in vs opt-out** (pregunta #4) dentro del plan de F10, no diferirlo a implementación; alinear `docs/privacy-policy.html`. Definir estado **error** (fallo al persistir preferencia → revertir switch + aviso ES).
3. **F1 (G0):** escribir la **regla de capa única** (abstracción `core` Dart-puro consumible por domain+presentación; SDK Firebase solo en `core/services/.../firebase_*`) y normalizar el call site de soat a ella. Esta regla es prerequisito de F5-F9.
4. **F1 criterio de aceptación:** crash de prueba **simbolizado** en staging (Android + iOS), y verificación de que un fallo de init de Crashlytics no rompe `runApp` (degradar silencioso).
5. **F2:** auditar los params actuales de `soat_scan_success`/`soat_scan_failed` contra checklist no-PII al migrarlos (no asumir que ya son limpios). Gate G1: cero `logEvent('literal'...)` tras F2.
6. **F3:** mapa ruta→nombre estable **sin ids/params**, centralizado; evitar doble screen_view en shell/tabs. Criterio: navegar 5 rutas con params y ver nombres estables sin PII en DebugView.
7. **F4:** publicar la **matriz "categoría de error → único punto que reporta"** (G5) y la **política de severidad** (qué es accionable vs ruido); sanitizar mensajes/URLs antes de `recordError` (G2).
8. **F6:** partir en lectura vs escritura (6a/6b) o fijar alcance mínimo verificable explícito; es la fase con mayor superficie y mayor riesgo de no cerrar.
9. **F7:** enumerar los hitos exactos a instrumentar y prohibir por escrito loguear cada ping de ubicación.
10. **Transversal (G3 + pregunta #8):** cada fase que añade call sites añade su **test unitario con mock** del `AnalyticsService`/`CrashReporter`; no aceptar solo verificación manual en DebugView. No-op impl provista en F1.
11. **F10:** separar los 3 entregables (auditoría no-PII / UI opt-out / doc QA) de modo que el opt-out pueda cerrarse aunque queden hallazgos de auditoría como tareas.
12. **Por fase (todas F1-F9):** declarar explícitamente "sin UI / sin regresión de comportamiento" y describir el estado de captura (activa/off/no-op) para que QA no busque pantallas inexistentes.
