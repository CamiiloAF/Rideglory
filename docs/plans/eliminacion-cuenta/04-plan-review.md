# Plan review — Eliminación de cuenta

_Generado: 2026-07-07T15:54:17Z_

**Revisor:** Plan Reviewer (UX móvil + calidad/Clean Architecture)
**Insumos:** `01-scan.md`, `02-po-proposal.md`, `.claude/agents/design.md`, `.claude/agents/tech_lead.md`,
`docs/design/html-mockups/` (solo `iter-2`/`iter-3`, sin relación con esta feature),
`lib/features/profile/presentation/widgets/profile_actions_list.dart` (patrón `_logout` de referencia).

**Veredicto global:** `ok_con_ajustes` — las 4 fases están bien delimitadas por valor y por
dependencia técnica, pero la fase 1 subestima la superficie de UI real (doble confirmación +
copy de "qué se borra" necesita más que reusar `ConfirmationDialog` tal cual), y la fase 4 mezcla
dos preocupaciones de tamaño distinto (manejo de error/retry vs. estado "app cerrada a mitad de
proceso") que conviene acotar explícitamente para que sea verificable.

---

## UX por fase

### Fase 1 — núcleo de identidad

- **Punto de entrada**: ítem "Eliminar cuenta" en `ProfileActionsList`, mismo patrón visual que
  "Cerrar sesión" (`ProfileMenuItem` con `iconColor`/`labelColor` de error, `showChevron: false`).
  Correcto reusar el componente — **pero la doble confirmación no cabe en un solo
  `ConfirmationDialog.show()`** como el de logout: son dos pasos con dos textos distintos
  (uno explicando qué se borra, otro confirmando "entiendo que es irreversible"). Definir si es
  (a) dos `ConfirmationDialog` encadenados, o (b) una pantalla dedicada tipo
  `DeleteAccountConfirmationPage` con lista de qué se elimina + un `AppSwitch`/checkbox "Entiendo
  que esta acción es irreversible" que habilita el `AppButton` de confirmar. La opción (b) es más
  clara a 375px (más espacio para el listado de datos afectados) y es el patrón recomendado — dos
  `AppDialog` seguidos uno del otro es una anti-patrón de navegación (el usuario no distingue por
  qué hay dos popups iguales en fila) y viola la heurística de "visibilidad del estado del
  sistema": no queda claro cuál confirmación es la "de verdad".
- **Estados a diseñar en esta fase** (actualmente el scan/PO no los enumera y hay que exigirlos
  al Design agent): `idle` (ítem visible en el menú) → `confirming` (paso 1: qué se borra) →
  `confirming2` (paso 2: checkbox/texto irreversible + botón confirmar deshabilitado hasta marcar)
  → `loading` (llamada en curso; el botón de confirmar debe mostrar spinner y **deshabilitar
  doble-tap** — la fase 4 no debe ser la única responsable de esto, es P0 de fase 1) → `error`
  (mensaje accionable + botón "reintentar", sin salir de la pantalla) → `success` (logout +
  `goAndClearStack(AppRoutes.login)`).
- **Touch targets**: `ProfileMenuItem` ya cumple 44px (heredado del patrón logout) — sin ajuste.
  El checkbox de confirmación de la fase 2 del flujo debe usar `AppSwitchTile`, nunca un
  `Checkbox`/`FormBuilderCheckbox` (no hay componente de checkbox unificado documentado en
  CLAUDE.md; usar el switch existente como el más cercano, o confirmar con Design si hace falta
  un átomo nuevo de checkbox — **si se crea, debe ir a `lib/design_system/atoms/` y no ad-hoc en
  el feature**).
- **Riesgo de scope UX**: el PO describe la fase 1 como "el mismo patrón visual de logout"; el
  scan confirma que no hay pantalla dedicada hoy. Si Design intenta resolver la doble confirmación
  con dos `ConfirmationDialog.show()` anidados para ahorrar tiempo, el resultado violará el
  estándar de "un widget por archivo / sin diálogos apilados sin justificación" y confundirá al
  usuario. **Ajuste**: exigir explícitamente en la fase 1 una pantalla dedicada (mockup en Pencil,
  no HTML — ver Gates de calidad) para el flujo de confirmación doble.

### Fase 2 — vehículos y documentos

- Correctamente marcada como "sin cambios visibles nuevos" — es 100% backend/orquestación. Único
  punto de UX: el copy del paso 1 de la fase 1 (qué se borra) debe listar explícitamente motos,
  fotos, mantenimientos y documentos — **la fase 2 depende del copy definido en fase 1**, así que
  si fase 1 ya se implementó y aprobó sin ese detalle, hay que volver a tocar la UI de fase 1 en
  fase 2 (retrabajo). Ajuste: el copy completo de "qué se borra" (con los ítems de fase 2 y 3
  incluidos) debe diseñarse una sola vez en fase 1, aunque la funcionalidad de borrado real se
  entregue incrementalmente. Evita que la pantalla de confirmación mienta por omisión en un
  release intermedio (p. ej. dice "se borran tus motos" antes de que el backend de fase 2 exista).
- No requiere estados adicionales de loading/error distintos a los de fase 1 (mismo botón, mismo
  flujo) — bien dimensionada si se sigue el ajuste anterior.

### Fase 3 — historial de eventos y organizadores activos

- **Caso nuevo de UX real**: el bloqueo por eventos activos como organizador. Debe fallar *antes*
  de que el usuario pase por la doble confirmación de fase 1, o el usuario invierte esfuerzo en
  confirmar dos veces solo para toparse con un bloqueo — mala UX (viola "prevención de errores"
  de Nielsen). **Ajuste concreto**: la app debe consultar/validar la condición de "organizador
  con eventos activos" en el primer tap del ítem "Eliminar cuenta" (antes de mostrar el primer
  diálogo/pantalla de confirmación), no al final de la doble confirmación. Si el backend no puede
  dar una respuesta rápida sin pasar por el endpoint de borrado real, considerar un
  `GET /users/me/deletion-eligibility` o similar — a decidir en fase de arquitectura, pero debe
  quedar explícito en esta fase de plan como requisito de UX, no como detalle de implementación
  libre.
- **Mensaje de bloqueo**: debe ser un estado dedicado (no un `ConfirmationDialog` de error) con
  acción clara: botón/link a "Mis eventos" o a la lista de eventos activos como organizador, no
  solo texto explicativo. Ajuste: usar `EmptyStateWidget` o un estado tipo error con CTA hacia
  `context.pushNamed` a la gestión de eventos, siguiendo componentes compartidos existentes.
- El "historial anonimizado" no tiene superficie visible nueva en la app del rider que se borra
  (ocurre server-side) — correcto que no se le asigne mockup propio. Pero si otros usuarios ven el
  registro de participación del rider eliminado en un evento pasado (p.ej. lista de asistentes),
  el nombre debe mostrarse anonimizado ("Usuario eliminado" o similar) — **falta esta pantalla en
  el scan**: verificar `event_registration`/detalle de evento, lista de asistentes, para confirmar
  si hay una superficie visible de terceros que requiere UI (aunque sea un string ya existente
  como fallback). Ajuste: agregar esta verificación explícita a la fase 3.

### Fase 4 — fallas y estados intermedios

- Bien acotada en alcance ("no agrega superficie visible nueva"), pero el título mezcla dos
  problemas de tamaño distinto:
  1. **Error/retry durante el flujo activo** (el usuario ve la pantalla, la llamada falla) — esto
     es trivial de verificar (estado `error` con botón reintentar, ya cubierto en fase 1 como
     estado base) y NO debería requerir una fase completa aparte; es una extensión menor de los
     estados de fase 1.
  2. **Cierre de la app / reapertura con borrado a medias en backend** — esto es genuinamente
     nuevo y complejo (requiere decidir si hay estado persistente client-side, o si basta con que
     el interceptor de auth ya existente detecte token inválido tras hard-delete y fuerce logout).
  Ajuste: **dividir el criterio de aceptación de fase 4** para que el "reintento simple" se declare
  ya cubierto por los estados base de fase 1 (evitando que fase 4 reimplemente lo mismo), y que la
  fase 4 se enfoque exclusivamente en el caso "app cerrada / reabierta a mitad de proceso" +
  idempotencia del backend (reintentar sin duplicar efectos). Esto hace la fase verificable con un
  criterio único y no ambiguo, en vez de "estados de error en general" que ya deberían existir.
- **Estado a verificar explícitamente**: usuario reabre la app con sesión que "parece válida"
  (token cacheado) pero cuenta ya borrada en backend — el interceptor de Firebase Auth existente
  debería forzar logout en el primer request fallido (401/403). Ajuste: el criterio de aceptación
  de fase 4 debe decir explícitamente "verificar que el interceptor ya existente maneja este caso
  sin código nuevo, o documentar qué código nuevo hace falta" — el scan ya apunta a esto pero el
  PO proposal no lo convierte en criterio verificable.

---

## Gates de calidad

- **Regla de diseño en Pencil (obligatoria, del memory del proyecto)**: cualquier pantalla nueva
  (la de confirmación doble de fase 1, el estado de bloqueo de organizador de fase 3) debe
  diseñarse en el `rideglory.pen` existente, **no** como mockup HTML nuevo — el scan nota
  correctamente que no hay artefactos Pencil para esta feature, y `docs/design/html-mockups/`
  contiene solo iteraciones previas no relacionadas. La fase de ejecución debe bloquear si Design
  intenta producir HTML mockups en lugar de tocar Pencil, y debe detenerse (no inventar) si el MCP
  de Pencil está caído, según la regla de feedback existente.
- **Un widget por archivo / sin métodos que retornan widgets**: la pantalla de confirmación doble
  y el estado de bloqueo de organizador son candidatos naturales a violar esto si se implementan
  rápido dentro de `profile_actions_list.dart` — deben ser archivos/widgets propios (p. ej.
  `delete_account_page.dart`, `delete_account_confirm_step.dart`,
  `delete_account_blocked_organizer_view.dart`), no métodos privados agregados al archivo actual.
- **Reuso de componentes compartidos**: verificar antes de implementar
  `lib/shared/widgets/form/` y `lib/shared/widgets/modals/` — `AppButton` para el CTA final
  (deshabilitado hasta marcar el entendimiento de irreversibilidad), `ConfirmationDialog` solo
  para el primer paso simple (si se opta por diálogos) o descartarlo en favor de página dedicada,
  `AppSwitchTile` para el checkbox de "entiendo que es irreversible" (nunca `Checkbox`/
  `FormBuilderCheckbox` sin antes confirmar si existe un átomo de checkbox — si no existe, es
  una decisión de Design a marcar explícitamente, no una improvisación de Frontend).
- **Texto oscuro sobre primario**: si el botón de confirmar final usa `AppColors.error` (no
  primario), no aplica esta regla; pero si en algún estado se usa el naranja de acento (p. ej.
  CTA "Cancelar eventos" en el bloqueo de organizador, que podría ser primario en vez de error),
  el texto/ícono debe ir oscuro — anotar en el mockup de Design.
- **Clean Architecture**: fase 1-2 introducen un nuevo endpoint (`DELETE /users/me`) y su
  correspondiente `DeleteAccountRepository`/`UseCase` en `domain/` — debe seguir Pattern B si hay
  un DTO de request/response; si la respuesta es solo un 204/200 sin cuerpo relevante, documentar
  la excepción de "request-only DTO" según `.claude/rules/rideglory-coding-standards.mdc`. El
  cubit de eliminación de cuenta debe ser `@injectable` (no `@singleton`/`getIt`, según feedback
  del proyecto), montado en el árbol de widgets del flujo de eliminación, no como cubit global de
  `main.dart`.
- **ResultState<T>**: el flujo de borrado debe modelarse con `ResultState<void>` (o similar) — sin
  banderas booleanas de `isDeleting`/`hasError`. El estado de "bloqueado por eventos activos" de
  fase 3 debe representarse como un caso propio (p. ej. `ResultState.error` con un
  `DomainException` específico tipado, no un string genérico) para que la UI pueda distinguirlo de
  un error de red genuino y mostrar el CTA correcto.
- **Localización**: todo el copy nuevo (títulos, checkbox, mensajes de bloqueo, mensajes de
  error/retry) va en `app_es.arb` con prefijo `profile_deleteAccount_*` o similar — cero strings
  hardcodeados, incluida la lista de "qué se borra" si se implementa como lista estática de
  textos.
- **Tests**: cada fase necesita al menos un cubit test cubriendo sus estados (`idle/loading/error/
  success/blocked`) y un widget test de la pantalla de confirmación; fase 3 necesita test del
  camino de bloqueo por organizador; fase 4 necesita test simulando fallo parcial (mock del
  repositorio devolviendo error a mitad de la orquestación, si la orquestación se refleja de algún
  modo observable en el cliente) — a coordinar con QA para no depender solo de test manual.

---

## Riesgos de scope

- **Fase 1 subestima el esfuerzo de UI**: "mismo patrón que logout" no es preciso para una doble
  confirmación con copy extenso — riesgo de que Frontend intente resolverlo con dos
  `ConfirmationDialog` anidados por rapidez, violando el ajuste de arriba. Mitigar exigiendo el
  mockup de Pencil como entregable bloqueante antes de implementar (ya es regla del proyecto, pero
  conviene reforzarlo explícitamente en el plan de fase 1 dado que el scan confirma "cero
  artefactos Pencil existentes" para esta feature).
- **Acoplamiento fase 1 ↔ fase 2/3 vía copy**: si el copy de "qué se borra" se escribe fase por
  fase, cada fase requiere retocar la misma pantalla — retrabajo evitable si se diseña completo
  desde fase 1 (ver ajuste en Fase 2 arriba).
- **Orden de validación en fase 3** (bloqueo de organizador antes vs. después de la doble
  confirmación) no está resuelto en el PO proposal ni en el scan — si se deja para la fase de
  arquitectura sin marcarlo como requisito de UX, es fácil que se implemente "primero confirmar,
  luego fallar", generando la mala experiencia ya señalada.
- **Fase 4 corre riesgo de ser una fase "vacía" o redundante** si no se acota su criterio de
  aceptación al caso de cierre de app / idempotencia (ver ajuste arriba) — de lo contrario duplica
  trabajo ya cubierto por los estados base de fase 1, dificultando verificarla como una unidad de
  valor propia (QA no podría distinguir qué prueba pertenece a fase 1 vs. fase 4).
- **Dependencia cruzada con `rideglory-api`**: las 4 fases de Flutter dependen de que la
  orquestación cross-MS del backend (fuera de este scan de app, pero mencionado en `01-scan.md`)
  esté resuelta en el mismo orden — si el backend decide bloquear por organizador *después* de ya
  haber borrado vehículos/documentos (orden inverso al ideal), la fase 3 de UI no podría prevenir
  el problema con una validación previa. Este plan debe coordinarse explícitamente con el plan de
  backend para fijar el orden de operaciones (validar organizador → confirmar UI → borrar en
  cascada), no asumirlo solo del lado de la app.
- **Sin usuario/dato de prueba con todos los tipos de datos simultáneos** (ya señalado por el PO)
  — riesgo de que el video de demostración para Apple (fuera de estas fases) no pueda grabarse
  hasta que QA prepare ese escenario; no bloquea el plan, pero debe quedar como dependencia
  explícita para la fase de QA/release, no asumida.

---

## Ajustes

1. Fase 1: reemplazar "dos `ConfirmationDialog` reutilizando el patrón de logout" por una pantalla
   dedicada de confirmación (a diseñar en Pencil) con lista de qué se borra + checkbox/switch de
   entendimiento que habilita el botón final — no apilar dos popups iguales.
2. Fase 1: el copy completo de "qué se borra" debe incluir desde el inicio los ítems de fase 2
   (motos, fotos, mantenimientos, documentos) y fase 3 (historial de eventos anonimizado), aunque
   el borrado real de esos datos se entregue incrementalmente — evita retrabajo de UI y evita que
   el copy mienta por omisión en un release intermedio.
3. Fase 1: exigir explícitamente un estado `loading` con botón deshabilitado/spinner y prevención
   de doble-tap como parte del criterio de aceptación base (no delegarlo íntegro a fase 4).
4. Fase 3: la validación de "organizador con eventos activos" debe ocurrir en el primer tap del
   ítem "Eliminar cuenta", antes de mostrar cualquier paso de confirmación — agregar como criterio
   de aceptación explícito, y coordinar con el plan de backend para que exista un chequeo rápido
   sin ejecutar el borrado real.
5. Fase 3: el mensaje de bloqueo por organizador debe ser un estado dedicado con CTA accionable
   (navegación a gestión de eventos), no un diálogo de error genérico.
6. Fase 3: agregar verificación explícita de si la vista de "lista de asistentes"/detalle de
   evento (visible para terceros) necesita mostrar un placeholder tipo "Usuario eliminado" para
   participantes con cuenta borrada — confirmar con el scan de `event_registration` si aplica.
7. Fase 4: acotar el criterio de aceptación a "cierre de app / reapertura con borrado a medias" e
   idempotencia de reintento — sacar de esta fase el manejo de error/retry simple del flujo activo
   (eso ya es criterio base de fase 1) para que ambas fases sean verificables sin solaparse.
8. Todas las fases: recordar explícitamente en el plan que cualquier pantalla nueva pasa por
   Pencil (`rideglory.pen`) según la regla del proyecto, y que la ejecución debe detenerse (no
   improvisar HTML/mockups) si el MCP de Pencil no está disponible.
9. Backend/UX conjunto: fijar y documentar el orden de operaciones esperado (validar elegibilidad
   organizador → doble confirmación UI → borrado en cascada) como contrato entre el plan de
   Flutter y el de `rideglory-api`, para que la fase 3 de UI pueda prevenir el bloqueo antes de
   que el usuario invierta esfuerzo confirmando.
