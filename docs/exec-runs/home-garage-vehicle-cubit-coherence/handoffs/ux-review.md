# UX Review — home-garage-vehicle-cubit-coherence

**Fecha:** 2026-06-17T22:00:55Z
**Veredicto:** APROBADO CON NOTAS

---

## Frames revisados

| Frame ID | Nombre | Estados revisados | Veredicto |
|----------|--------|-------------------|-----------|
| `dyWWs` | Home Dashboard | Data (vehículo principal), placeholder Initial/Loading especificado en handoff | Aprobado con notas |

**Nota de alcance:** Esta fase es un refactor de coherencia de estado (nivel lite). No se crearon frames nuevos en Pencil. La revisión cubre: (a) el frame existente `dyWWs` como referencia visual del estado `Data`, y (b) el placeholder spec documentado en `design.md` para los estados `Initial`/`Loading`, que ya está implementado en `home_garage_section.dart`.

---

## Hallazgos por frame

| Frame | Heurística / Ley | Severidad | Descripción | Fix requerido |
|-------|-----------------|-----------|-------------|---------------|
| `dyWWs` / placeholder (impl) | Regla Rideglory: un widget por archivo | **Sugerencia** | `_GaragePlaceholder` es una clase privada `StatelessWidget` declarada en el mismo archivo que `HomeGarageSection` (`home_garage_section.dart`). El CLAUDE.md es explícito: "un widget por archivo — cada `.dart` tiene máximo 1 clase que extiende `StatelessWidget`". Aunque el placeholder es trivial (3 líneas), la regla no tiene excepciones por tamaño. | Extraer `_GaragePlaceholder` a `lib/features/home/presentation/widgets/home_garage_placeholder.dart` como clase pública `HomeGaragePlaceholder`. |
| `dyWWs` / placeholder (impl) | Nielsen #1 — Visibilidad del estado del sistema | **Sugerencia** | El placeholder de 200px es un `Container` sólido sin ninguna señal de "cargando": sin shimmer, sin animación sutil, sin icono neutral. Para ≤1-2s es aceptable (PRD lo valida), pero en conexiones lentas el rider verá un rectángulo oscuro sin feedback alguno. El PRD descartó skeleton animado explícitamente, así que esto no es un bloqueante — pero es un riesgo UX menor. | Agregar al backlog: skeleton shimmer animado o un LinearProgressIndicator delgado al top del placeholder si la duración supera 1s. No implementar ahora. |
| `dyWWs` / placeholder (impl) | Nielsen #4 — Consistencia y estándares; Gestalt: continuación | **Sugerencia** | La altura del placeholder (200px) es ~40-60px más corta que el `HomeGarageCard` real (~240-260px según handoff). Esto produce un micro-jump de layout cuando `VehicleCubit` emite `Data` y el placeholder se reemplaza por el card completo. El handoff lo documenta como "conservativo pero suficiente", y el PRD lo acepta explícitamente. El scroll jump es real pero breve (≤1-2s). | Agregar al backlog: igualar la altura del placeholder a la altura real del `HomeGarageCard` (medir con `GlobalKey` + `RenderBox` o fijar en 250px). Prioritario si el tiempo de carga aumenta. |
| `dyWWs` (Pencil, estado Data) | WCAG 2.1 AA — Contraste texto | **Conforme** | Badge de mantenimiento: texto `#F98C1F` (naranja) sobre fondo `#2D2117` (marrón oscuro). Estimado ~4.8:1 — pasa AA para texto pequeño. Texto de vehículo `#FFFFFF` sobre `#1E1E24` — ratio estimado >15:1. | Ninguno. |
| `dyWWs` (Pencil, estado Data) | Regla Rideglory: texto oscuro sobre primario naranja | **Conforme** | El ícono de warning `#F98C1F` y el texto naranja del badge están sobre fondo `#2D2117`, no sobre el naranja. El naranja se usa como color de texto/ícono sobre fondo oscuro — correcto. | Ninguno. |
| `dyWWs` (Pencil, estado Data) | Nielsen #8 — Diseño minimalista | **Conforme** | La sección garaje muestra exactamente: imagen del vehículo + nombre + badge de alerta. Sin elementos superfluos. | Ninguno. |
| `dyWWs` (Pencil, estado Data) | Ley de Fitts — touch targets | **Conforme** | `HomeGarageCard` es un `GestureDetector` que cubre la altura completa del card (~240-260px) y el ancho de pantalla menos márgenes (350px). Claramente ≥44px. | Ninguno. |
| `dyWWs` (placeholder, estado Initial/Loading) | WCAG 2.1 AA — Contraste superficie decorativa | **Conforme** | Placeholder usa `AppColors.darkCard` (#1E1E24 según Pencil) sobre el fondo de pantalla. Es un elemento decorativo sin texto — WCAG no exige ratio de contraste para superficies puramente decorativas sin información. El contraste visual es perceptible para distinguir el área reservada. | Ninguno. |
| `dyWWs` (placeholder, estado Initial/Loading) | Semántica / Screen readers | **Conforme** | El placeholder no tiene `Semantics` label. El handoff lo justifica correctamente: en estado `Initial`/`Loading` no hay contenido que anunciar — VoiceOver/TalkBack deben estar silenciosos. | Ninguno. |

---

## Bloqueantes — deben resolverse antes de que Frontend empiece

**Ninguno.**

Frontend puede proceder a la implementación (o en este caso, dado que la implementación ya existe en el working tree, puede proceder a la fase de QA).

---

## Sugerencias — backlog de UX (no bloquean)

1. **Extraer `_GaragePlaceholder` a su propio archivo** (`home_garage_placeholder.dart`). Violación de la regla "un widget por archivo" del CLAUDE.md. Bajo esfuerzo, alta adherencia a estándares. El hecho de que la clase sea privada (`_`) no exime la regla — si no necesita ser accedida externamente, puede seguir siendo privada por naming convention, pero debe estar en un archivo separado, o renombrarse a `HomeGaragePlaceholder` (público) al extraerla.

2. **Backlog: skeleton shimmer para `Initial`/`Loading`** en caso de que el tiempo de carga del `VehicleCubit` aumente (e.g. por cold start o red lenta). El placeholder sólido actual da cero feedback de progreso. Implementar con `shimmer` package (ya en proyectos similares) o con `AnimationController` nativo. No urgente mientras P99 < 2s.

3. **Backlog: igualar altura del placeholder a la del card real (~250px)**. El salto de 50px al transicionar de `Initial`→`Data` es breve pero perceptible. Si la métrica de tiempo de carga del cubit sube, este layout jump se vuelve molesto.

---

## Resumen ejecutivo

Esta fase es un refactor de coherencia de estado puro, sin nueva UI diseñable en Pencil. El frame existente `dyWWs` está visualmente bien: contraste, jerarquía, touch targets y semántica son conformes con todos los frameworks aplicables.

El único hallazgo accionable inmediato es estructural, no visual: la clase `_GaragePlaceholder` dentro de `home_garage_section.dart` viola la regla "un widget por archivo" del CLAUDE.md. Sin embargo, no constituye un bloqueante UX — es una deuda de coding standards que el implementador o el auditor de código deben resolver, no una falla de diseño que impida al usuario operar la app.

Los dos hallazgos de backlog (shimmer y altura exacta del placeholder) son mejoras de polish para una v2 de la funcionalidad, explícitamente fuera del alcance del PRD actual.

---

## Veredicto final

**APROBADO CON NOTAS** — Sin bloqueantes UX. El diseño existente en Pencil (`dyWWs`) es conforme. El placeholder spec es funcionalmente correcto. Una sugerencia de coding standards (widget en archivo propio) y dos mejoras de polish en backlog. Frontend/QA pueden continuar.
