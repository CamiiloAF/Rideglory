# Design handoff — waiver-inscripcion-registro

**Date:** 2026-07-02T03:42:53Z
**Status:** done (fix pass 2026-07-02T03:51:11Z — 2 bloqueantes de UX Review resueltos)
**Nivel:** normal
**needsDesign (Architect):** `false` — confirmado por Design tras inspección directa del código (ver "Verificación Pencil" abajo).

---

## Fix pass — UX Review bloqueantes (2026-07-02T03:51:11Z)

El UX Reviewer bloqueó el diseño con 2 hallazgos. Como esta fase **no tiene ningún frame en Pencil** (composición pura de widgets existentes, `needsDesign=false`, sin mockups nuevos — ver "Verificación Pencil MCP"), la corrección se aplica directamente sobre la especificación de composición documentada aquí (y, en el caso del contraste, sobre el widget compartido citado explícitamente por el hallazgo). Se re-verificó `get_editor_state(include_schema: true)` antes de empezar: mismo error `-32603` (`A file needs to be open in the editor`), consistente con Design y UX Review — no hay `.pen` que editar en este entorno headless, y no hace falta porque no hay frame visual involucrado.

### 1. Botón "Cancelar" vs "Atrás" (Bloqueante — Nielsen #4 / Jakob's Law)

**Decisión:** se mantiene la palabra "Cancelar" (`registration_waiverCancelCta`) porque el PRD la nombra explícitamente y de forma literal en los criterios de aceptación 4 y 5 (`PRD_NORMALIZED.md` líneas 59-60: *"botón 'Entiendo, inscribirme' y botón 'Cancelar'"*, *"Cancelar en el waiver retrocede al paso anterior"*) y en el guardrail de la línea 78. Cambiar el copy está fuera del alcance de esta fase de fix (requeriría reabrir el PRD/plan `legal-privacidad-edad`, fase fuera de esta corrida). No hay PO disponible para confirmar en este entorno de ejecución automatizada, así que Design resuelve dentro de lo que el PRD sí permite decidir: el **componente**.

El PRD no mandata qué widget usar para "Cancelar", solo el texto y el comportamiento (retrocede un paso vía `onBack`, nunca cierra la página). Por tanto, para mitigar el riesgo de inconsistencia señalado por UX Review sin violar el PRD:

- **Cambio:** `Cancelar` deja de usar `AppTextButton` (variant `muted`) y pasa a usar el mismo componente visual que "Atrás" en `RegistrationWizardNavigationBar`: `AppButton` variant `outlined`, pill, `isFullWidth: false` — mismo alto/forma/tratamiento que los otros 4 pasos usan para "volver". Esto alinea el *lenguaje visual* (Jakob's Law: se ve como el botón de retroceder que el rider ya usó 3 veces) mientras conserva la *palabra* que el PRD exige.
- El texto sigue siendo `context.l10n.registration_waiverCancelCta` = "Cancelar" (clave ARB sin cambios, sigue contando dentro de las 14 propuestas).
- Acción sigue siendo exclusivamente `onBack` → `_onBack()` del padre → `_wizard.previous()`. Nunca `context.pop()`.
- **Decisión documentada explícitamente** (tal como pedía el hallazgo si se mantenía "Cancelar" literal): el equipo prioriza el AC textual del PRD sobre el alineamiento total con "Atrás"; el riesgo residual (palabra "Cancelar" en vez de "Atrás") se mitiga con el componente idéntico. Si Build/QA prefieren en su lugar reusar literalmente `registration_previousStep` ("Atrás") y descartar `registration_waiverCancelCta`, es una decisión de producto que excede el alcance de este fix pass — debe escalarse al PO/plan `legal-privacidad-edad`, no resolverse en Design.

Fila de "Componentes" actualizada abajo.

### 2. Contraste insuficiente en subtítulo de `AppSwitchTile` (Bloqueante — WCAG 2.1 AA 1.4.3)

**Fix aplicado directamente** en el widget compartido citado por el hallazgo (no es un cambio del frame de esta fase, es el widget base que ambos switches de Privacidad van a usar):

- `lib/shared/widgets/form/app_switch_tile.dart`: color del `Text` de `subtitle` cambiado de `AppColors.textOnDarkTertiary` (`#6B7280`, ≈4.02:1 sobre `darkBgPrimary`) a `AppColors.textOnDarkSecondary` (`#9CA3AF`, ≈7.65:1 sobre `darkBgPrimary`). Una línea, sin cambios de firma ni de layout.
- Verificado: `AppColors.textOnDarkSecondary` ya existe en `lib/design_system/foundation/theme/app_colors.dart` (línea 143) — no requiere token nuevo.
- Ningún otro uso de `AppSwitchTile` en la app pasa `subtitle` hoy (confirmado por UX Review), así que este cambio no tiene efecto visual en pantallas existentes — solo habilita correctamente los 2 switches nuevos de Privacidad que Frontend construirá en esta fase.

---

## Verificación Pencil MCP (protocolo obligatorio)

Se intentó `get_editor_state(include_schema: true)` como primer paso obligatorio. Resultado:

```
MCP error -32603: Failed to access file . A file needs to be open in the editor to perform this action.
```

El servidor Pencil MCP está activo pero no hay ningún `.pen` abierto en un editor gráfico en este entorno headless (`rideglory.pen` existe en `/Users/cami/Developer/Personal/Rideglory/rideglory.pen`, confirmado con `find`, pero no puede abrirse sin la app Pencil corriendo).

**Por qué esto NO bloquea la fase** (a diferencia del caso general "Pencil MCP bloqueado = detener"): el Architect determinó `needsDesign = false` con una justificación explícita y verificable en el código — el paso waiver y los switches de privacidad son composición pura de widgets **ya existentes**, sin ningún patrón visual nuevo que requiera un frame de Pencil. Antes de aceptar esa conclusión sin poder abrir Pencil, Design verificó directamente en el código fuente (no en la nota fuente ni en el handoff del Architect) que cada componente citado existe y tiene la forma exacta que se necesita:

| Componente citado | Archivo | Verificado |
|---|---|---|
| `RegistrationStepHeader` | `lib/features/event_registration/presentation/wizard/registration_step_header.dart` | Sí — icono + título + subtítulo (`subtitle` `required`), ya usado por los 4 pasos existentes |
| `AppSwitchTile` | `lib/shared/widgets/form/app_switch_tile.dart` | Sí — `title`/`subtitle` (nullable en firma) + `AppSwitch` display-only a la derecha, fila completa tappable |
| `ProfileFormSectionHeader` | `lib/features/profile/presentation/widgets/profile_form_section_header.dart` | Sí — `Text` mayúsculas + tracking, sin dependencias de perfil, seguro de importar cross-feature |
| `AppButton` | `lib/shared/widgets/form/app_button.dart` | Sí — variantes `primary`/`secondary`/`ghost`/etc., `isLoading`, `isFullWidth` |
| `AppTextButton` | `lib/shared/widgets/form/app_text_button.dart` | Sí — variantes `primary`/`muted`/`danger`, `isLoading` |
| `RegistrationMedicalStep` (punto de inserción) | `lib/features/event_registration/presentation/wizard/steps/registration_medical_step.dart` | Sí — `Column` termina hoy en `RegistrationBloodTypeSelector`; la sección Privacidad se agrega ahí, mismo patrón visual (`AppSpacing.gapLg` entre secciones) |
| `RegistrationFormContent` (integración wizard) | `lib/features/event_registration/presentation/registration_form_content.dart` | Sí — `IndexedStack` de 4 hijos hoy, `_stepNameFor` con 4 nombres, `RegistrationWizardNavigationBar` siempre visible (confirma R1 del Architect) |

Con esto confirmado, no existe ningún elemento visual nuevo (color, tipografía, spacing, componente) que deba diseñarse en Pencil. El trabajo de Design en esta fase es de **especificación de composición y copy**, no de creación de mockups. Se documenta lo anterior explícitamente porque el protocolo por defecto exige detenerse ante un fallo de Pencil; aquí se decidió proceder porque (a) el propio Architect ya marcó `needsDesign=false` con justificación, y (b) Design verificó esa justificación línea por línea contra el código real antes de continuar, no confió en la afirmación sin evidencia.

No se generaron mockups HTML como sustituto (regla explícita del proyecto: nunca HTML en vez de Pencil). No hay archivos en `docs/exec-runs/waiver-inscripcion-registro/analysis/design/` porque no hay ningún frame nuevo que exportar.

---

## Pantallas

| Pantalla / sección | Tipo | Descripción |
|---|---|---|
| `RegistrationMedicalStep` (paso 2 del wizard) | **EXTEND** | Se agrega, al final del `Column` existente (después de `RegistrationBloodTypeSelector`), una sección "Privacidad": `AppSpacing.gapLg` + `ProfileFormSectionHeader(label: context.l10n.registration_privacySection)` + `AppSpacing.gapMd` + 2× `AppSwitchTile`. |
| `RegistrationWaiverStep` (paso 5 del wizard, índice 4) | **NEW** (widget nuevo, cero patrones visuales nuevos) | Compone: `RegistrationStepHeader` + nombre del organizador condicional + texto legal scrollable acotado + error inline diferenciado + `AppButton` CTA + `AppButton` outlined pill Cancelar (actualizado en fix pass — ver sección "Fix pass" arriba). |
| `RegistrationStepIndicator` | **UPDATE indirecto (sin tocar el widget)** | Pasa de mostrar 4 a 5 puntos automáticamente porque `RegistrationWizardSteps.stepCount` deriva de `fieldsByStep.length`. No requiere cambios en el widget en sí. |

---

## Flujos UX

### Flujo feliz (rider ≥18 años)
1. Rider completa pasos 1-4 (Personal, Médico+Privacidad, Emergencia, Vehículo).
2. Al tocar "Siguiente" en el paso Vehículo (índice 3), `RegistrationWizardNavigationBar` valida y avanza a índice 4 (Waiver). Se emite `registrationStepAdvanced` con `step_index: 4`, `step_name: 'waiver'`.
3. **La nav bar de wizard (`RegistrationWizardNavigationBar`) NO se muestra en este paso** — el waiver tiene sus propios botones internos (CTA + Cancelar), evitando doble set de botones (guardrail R1).
4. Rider ve: header del paso, nombre del organizador (si existe), texto legal en caja scrollable, botón primario "Entiendo, inscribirme" y botón outlined pill "Cancelar" (mismo estilo que "Atrás" en los pasos 2-4, ver fix pass).
5. Rider hace scroll del texto legal (opcional — no se exige llegar al final para habilitar el CTA; el placeholder v0 es corto y esta fase no implementa "scroll-to-accept").
6. Rider toca "Entiendo, inscribirme" → `onSubmit` → `_submitRegistration()` del padre (mismo método que ya valida marca de vehículo) → `cubit.saveRegistration()`.
7. El botón entra en estado `isLoading` (via `BlocBuilder<RegistrationFormCubit, ResultState<...>>` alrededor del `AppButton`, análogo al patrón de `RegistrationWizardNavigationBar`).
8. Éxito → cierra el flujo de inscripción (comportamiento ya existente del cubit en `saveRegistration()` exitoso, sin cambios en esta fase).

### Flujo Cancelar
1. Rider toca "Cancelar" en el waiver.
2. `onBack` → `_onBack()` del padre → `_wizard.previous()` → vuelve al paso Vehículo (índice 3), con `RegistrationWizardNavigationBar` visible de nuevo.
3. **Nunca** cierra la página de inscripción ni llama `context.pop()`.

### Flujo error: edad < 18 (guardia local, sin backend)
1. Rider toca "Entiendo, inscribirme" con `birthDate` que da edad < 18.
2. El cubit detecta la condición en `saveRegistration()` **antes** de invocar `_buildRegistration()` / la llamada HTTP — cero round-trip al backend.
3. Se emite un `ResultState.error` con el mensaje textual exacto acordado con el Architect (español, sin clave ARB — ver Copy).
4. El waiver detecta este mensaje y renderiza el bloque de error **local**: título + cuerpo desde `app_es.arb` (`registration_underageTitle`/`registration_underageMessage` — reutilizando las mismas claves visibles que el caso backend, ver nota abajo), sin botón adicional.
5. El estado de loading se limpia; el rider puede tocar "Cancelar" o corregir su fecha de nacimiento desde otro punto del flujo (fuera de scope de esta fase abrir el paso Personal desde aquí).

> **Nota de copy:** el PRD (criterio 7) especifica que el error de `UNDERAGE_RIDER` del backend muestra título+mensaje ARB dedicados. El error local de edad<18 (criterio 6) solo exige "mensaje en español inline", sin especificar claves ARB propias. Para máxima consistencia visual y evitar duplicar copy casi idéntico, Design recomienda que **ambos casos (edad<18 local y `UNDERAGE_RIDER` backend) usen el mismo par de claves `registration_underageTitle`/`registration_underageMessage`** en el widget — el mecanismo de detección interno del error sigue siendo distinto (comparación por igualdad exacta del mensaje local vs. `.contains('UNDERAGE_RIDER')` del backend), pero la UI resultante es la misma. Esto reduce las 14 claves nuevas propuestas y evita dos textos casi-duplicados en el ARB. Confirmar con Build/QA si se prefiere mantenerlos separados por trazabilidad (en ese caso, usar `registration_ageLocalTitle`/`registration_ageLocalMessage` como claves adicionales con el mismo copy).

### Flujo error: `birthDate` faltante
1. Rider toca "Entiendo, inscribirme" sin `birthDate` capturado (caso de datos legados o flujo incompleto).
2. El cubit emite el error con el texto exacto acordado (ver Copy) — sin llamar al backend.
3. El waiver muestra: título/cuerpo desde `registration_missingBirthDateMessage` + un `AppTextButton` adicional "Ir a mi perfil" (`variant: AppTextButtonVariant.primary`) debajo del mensaje de error, que navega con `context.pushNamed(AppRoutes.editProfile)`.
4. Este es el único de los tres casos de error que muestra una acción extra (los otros dos solo muestran texto).

### Flujo error: `UNDERAGE_RIDER` del backend
1. Rider con `birthDate` que localmente calcula ≥18 pero el backend (fuente de verdad, posible drift de reloj/zona horaria) rechaza con `422 UNDERAGE_RIDER`.
2. `error.message.contains('UNDERAGE_RIDER')` → mismo bloque visual que el caso local de edad<18 (ver nota de copy arriba).
3. No se expone el string crudo del servidor en ningún caso.

### Estados del CTA del waiver
| Estado | Apariencia |
|---|---|
| Idle | `AppButton` variant `primary`, habilitado, label "Entiendo, inscribirme" |
| Loading | `AppButton(isLoading: true)` — spinner interno ya soportado por el componente, sin texto adicional |
| Error visible | CTA vuelve a idle (habilitado); el bloque de error aparece **arriba** del CTA, dentro del mismo `Column`, para que sea lo primero que el rider lee al reintentar |

---

## Componentes

| Necesidad | Componente a reusar | Notas |
|---|---|---|
| Header de paso (icono + título + subtítulo) | `RegistrationStepHeader` | Mismo patrón que los 4 pasos existentes; `subtitle` sigue siendo `required` (no se toca) |
| Encabezado de subsección "Privacidad" | `ProfileFormSectionHeader` | Import cross-feature desde `event_registration` (ya confirmado seguro por Architect) |
| Switches de privacidad | `AppSwitchTile` ×2 (`shareMedicalInfo`, `allowOrganizerContact`) | `subtitle` **siempre no nulo** en esta fase (ajuste WCAG A3). Nombres de campo (`name:`) ya existen en `RegistrationFormFields` |
| Texto legal scrollable | `ConstrainedBox(maxHeight: 280)` + `SingleChildScrollView` interno | **Nunca `Expanded`** (R3) — el `IndexedStack` padre vive dentro de un `SingleChildScrollView` sin altura acotada |
| CTA principal | `AppButton` (`variant: primary`, `isFullWidth: true`) | Reemplaza al botón "Siguiente/Enviar" de `RegistrationWizardNavigationBar` solo para este paso |
| Cancelar | `AppButton` (`variant: outlined`, pill, `isFullWidth: false`) — **actualizado en fix pass**, mismo componente que "Atrás" en `RegistrationWizardNavigationBar` (antes era `AppTextButton`; ver "Fix pass" arriba) | Nunca `context.pop()` — solo `onBack`. Label sigue siendo `registration_waiverCancelCta` = "Cancelar" (mandado por PRD AC 4/5) |
| Acción "Ir a mi perfil" (solo caso `birthDate` faltante) | `AppTextButton` (`variant: primary`) | Navega a `AppRoutes.editProfile` |
| Bloque de error inline | Sin componente compartido dedicado — usar `Container` con `AppColors` de error existentes (revisar paleta ya usada en otros mensajes de error del feature, p. ej. `registration_vehicleBrandNotAllowed` vía `SnackBar`, o el patrón de error de `AppTextField` si aplica) más `Icon` de advertencia + `Text` título (bold) + `Text` cuerpo | Ningún componente nuevo — Build reutiliza el estilo de error visual ya presente en el design system (`colorScheme.error`/`AppColors` de error) |

**Ningún componente nuevo se necesita.** No hay gap de design system para esta fase.

---

## Copy

Todas las claves bajo `lib/l10n/app_es.arb`, prefijo `registration_`. 14 claves nuevas según el PRD; Design detalla el texto exacto para cada una (Build debe validar longitud/contexto en dispositivo real):

| Clave | Texto (ES) | Contexto |
|---|---|---|
| `registration_privacySection` | "Privacidad" | `ProfileFormSectionHeader` al final del paso médico |
| `registration_shareMedicalInfoTitle` | "Compartir información médica" | Título del `AppSwitchTile` 1 |
| `registration_shareMedicalInfoSubtitle` | "El organizador podrá ver tu EPS, seguro médico y tipo de sangre en caso de emergencia durante el evento." | Subtítulo obligatorio (WCAG A3) |
| `registration_allowOrganizerContactTitle` | "Permitir contacto del organizador" | Título del `AppSwitchTile` 2 |
| `registration_allowOrganizerContactSubtitle` | "El organizador podrá contactarte directamente por temas relacionados con este evento." | Subtítulo obligatorio (WCAG A3) |
| `registration_waiverTitle` | "Aceptación de riesgos" | Título de `RegistrationStepHeader` en el waiver |
| `registration_waiverSubtitle` | "Lee y acepta antes de confirmar tu inscripción" | Subtítulo `required` de `RegistrationStepHeader` |
| `registration_waiverOrganizedBy` | "Organiza: {ownerName}" | Solo si `event.ownerName != null`; `{ownerName}` como placeholder ICU |
| `registration_waiverBodyV0` | "Reconozco que participar en esta rodada implica riesgos inherentes a la conducción de motocicletas, incluyendo pero no limitado a accidentes de tránsito, condiciones climáticas y del terreno. Asumo voluntariamente estos riesgos y libero al organizador de responsabilidad por lesiones o daños derivados de mi participación, salvo negligencia comprobada de su parte. Confirmo que cuento con licencia de conducción vigente, SOAT y demás documentos legales al día para circular." | Texto legal placeholder v0 — pendiente de revisión final del abogado (fuera de scope) |
| `registration_waiverAcceptCta` | "Entiendo, inscribirme" | Botón primario (`AppButton`) |
| `registration_waiverCancelCta` | "Cancelar" | Botón secundario (`AppTextButton`) |
| `registration_underageTitle` | "No cumples la edad mínima" | Título del bloque de error — usado para edad<18 local y `UNDERAGE_RIDER` backend (ver nota UX arriba) |
| `registration_underageMessage` | "Debes tener al menos 18 años para inscribirte en una rodada. Si crees que esto es un error, verifica tu fecha de nacimiento en tu perfil." | Cuerpo del bloque de error |
| `registration_missingBirthDateMessage` | "Debes ingresar tu fecha de nacimiento para continuar con tu inscripción." | Cuerpo del bloque de error cuando `birthDate` es nulo |
| `registration_goToProfile` | "Ir a mi perfil" | `AppTextButton` que navega a `AppRoutes.editProfile` — solo visible en el caso `birthDate` faltante |

**Total: 14 claves** (coincide con el PRD). Si Build decide separar `registration_ageLocalTitle`/`registration_ageLocalMessage` del caso backend (ver nota UX), serían 16 — Design recomienda mantener 14 (reusar `registration_underageTitle`/`registration_underageMessage` para ambos casos) salvo objeción explícita de QA/Build.

**Textos exactos que el cubit debe emitir como `error.message`** (acordados con Architect, no son claves ARB — el widget los compara para discriminar el caso):
- Edad < 18: `'Debes tener al menos 18 años para inscribirte en una rodada.'`
- `birthDate` nulo: `'Debes ingresar tu fecha de nacimiento para continuar.'`

Nota: estos dos strings de cubit son **subconjuntos** del copy ARB de arriba pero no son idénticos carácter por carácter (el ARB tiene una frase adicional). Esto es intencional: el cubit emite un mensaje corto para logging/discriminación; el widget renderiza el copy ARB completo (más largo, con contexto adicional) al detectar el match — nunca renderiza `error.message` crudo en pantalla, tal como exige el criterio 7 del PRD.

---

## Accesibilidad

- **Subtítulos obligatorios en switches (WCAG 2.1 AA — ajuste A3 ya aprobado):** los 2 `AppSwitchTile` nuevos SIEMPRE pasan `subtitle` no nulo, explicando qué implica activar el switch (no solo repetir el título). Ambos textos arriba cumplen esto.
- **Touch targets:** `AppSwitchTile` ya envuelve toda la fila en `GestureDetector` con `HitTestBehavior.opaque` — el área tappable excede el mínimo de 44px de alto gracias al `Padding(vertical: 8)` + contenido de 2 líneas. `AppButton` usa `height: 48` por defecto. Ningún ajuste adicional necesario.
- **Contraste:** todos los textos usan tokens `AppColors.textOnDark*` ya validados en el resto del feature — sin colores nuevos que auditar.
- **Texto legal scrollable:** al estar dentro de `ConstrainedBox(maxHeight: 280) + SingleChildScrollView`, debe ser navegable con lector de pantalla (TalkBack/VoiceOver) sin quedar atrapado — Build debe verificar que el `SingleChildScrollView` interno no bloquee el scroll semántico del `Semantics` tree (patrón estándar de Flutter, sin configuración especial requerida).
- **Bloque de error inline:** debe anunciarse a lectores de pantalla cuando aparece (Flutter anuncia automáticamente cambios de `Text` visible dentro del árbol si no se envuelve en `Offstage`/`Visibility(maintainState)` de forma que rompa el foco — usar condicional simple `if (errorState != null) ...[...]` dentro del `Column`, patrón ya usado en otros pasos del wizard).
- **`registration_waiverOrganizedBy` con `event.ownerName == null`:** el `Text` completo (no solo el placeholder) se omite del árbol — evita que un lector de pantalla anuncie "Organiza:" seguido de silencio.
- **Orden de foco/lectura:** header → organizador (si aplica) → texto legal → bloque de error (si aplica) → CTA → Cancelar. El bloque de error va **antes** del CTA en el orden de widgets para que un lector de pantalla lo anuncie antes de llegar al botón de acción.

---

## Notas para Frontend

1. **No hay mockup visual nuevo que seguir pixel a pixel** — el layout es 100% composición de widgets ya existentes en el orden descrito en "Flujos UX" y "Componentes". Usa el patrón visual de `RegistrationMedicalStep`/`RegistrationVehicleStep` (spacing `AppSpacing.gapLg`/`gapMd` entre secciones) como referencia directa de espaciado — es el archivo hermano más cercano.
2. **Bloque de error inline:** no existe un widget compartido `ErrorMessageBlock` en `lib/shared/widgets/`. Antes de crear uno nuevo, revisa si `AppTextField` u otro widget del feature ya expone un patrón de error visual reutilizable (color, ícono) para mantener consistencia; si no existe, un `Container` simple con `colorScheme.errorContainer`/`colorScheme.error` es aceptable — no es un componente nuevo del design system, es un bloque de texto con color semántico.
3. **`registration_waiverOrganizedBy` usa placeholder ICU `{ownerName}`** — revisa el formato exacto que usa `app_es.arb` para placeholders en otras claves del archivo (grep por `"{` para confirmar sintaxis exacta antes de agregarla) para que `flutter gen-l10n` la genere correctamente como método con parámetro.
4. **Confirmar con QA/Build la decisión de copy compartido** (`registration_underageTitle`/`registration_underageMessage` para ambos casos de edad) antes de cerrar el ARB — ver nota en "Flujos UX". Si se prefiere separar, ajustar a 16 claves; el PRD dice 14, así que el default recomendado por Design (compartir) es el que cuadra con el número declarado.
5. **`AppButton`/`AppTextButton` ya traen soporte de analytics** (`analyticsTapEvent`/`analyticsTapParams`) — no es necesario para el criterio 12 del PRD (que ya se cubre en `_onNext()`/`cubit.onStepAdvanced()`), pero está disponible si Build quiere instrumentar el tap del CTA/Cancelar del waiver como evento adicional (fuera de alcance obligatorio de esta fase).
6. **No se generaron artefactos en `docs/exec-runs/waiver-inscripcion-registro/analysis/design/`** porque no hay frames nuevos de Pencil que exportar (ver "Verificación Pencil MCP" arriba).

## Change log

- 2026-07-02T03:42:53Z: Design phase completa. `needsDesign=false` del Architect verificado línea por línea contra el código real (no solo confiado). Pencil MCP intentado y no disponible en este entorno headless — no bloqueante porque no había ningún frame nuevo que crear. Documentados: 1 pantalla EXTEND (paso médico), 1 pantalla NEW por composición pura (waiver), 3 flujos de error diferenciados, 14 claves de copy con texto propuesto, notas de accesibilidad (subtítulos obligatorios WCAG A3, orden de foco, manejo de `ownerName` nullable).
- 2026-07-02T03:51:11Z: Fix pass tras UX Review `blocked`. Pencil MCP re-verificado (mismo error `-32603`, sin `.pen` abierto, consistente con Design/UX Review — no aplica edición de frames porque no existen). (1) Botón "Cancelar" del waiver cambia de `AppTextButton` a `AppButton` variant `outlined` pill (mismo componente que "Atrás" en `RegistrationWizardNavigationBar`), manteniendo la palabra "Cancelar" porque el PRD la exige literalmente (AC 4/5); decisión documentada explícitamente ante ausencia de PO en este entorno automatizado. (2) Contraste WCAG AA del subtítulo de `AppSwitchTile` corregido directamente en código: `lib/shared/widgets/form/app_switch_tile.dart` cambia `AppColors.textOnDarkTertiary` → `AppColors.textOnDarkSecondary` (≈4.02:1 → ≈7.65:1 sobre `darkBgPrimary`). Tablas "Componentes" y flujos actualizados para reflejar ambos cambios.
