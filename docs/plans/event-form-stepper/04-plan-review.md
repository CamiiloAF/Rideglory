# 04 — Plan Review

**Slug:** `event-form-stepper`
**Fecha:** 2026-06-09T00:12:01Z
**Reviewer:** Plan Reviewer (UX móvil + Clean Architecture)

---

## Veredicto general

`ok_con_ajustes` — El plan está bien estructurado y los 3 fases tienen valor incremental claro. Las fases son ejecutables sin deuda estructural, pero hay 7 ajustes concretos que deben incorporarse al plan detallado antes de ejecutar la Fase 1. Ninguno es bloqueante para la dirección general; todos son de scope o precisión de implementación.

---

## UX por fase

### Fase 1 — Fundación técnica

No produce cambios visibles para el usuario. Sin touch targets que evaluar en esta fase.

**Riesgo UX:** Si los ARB keys del stepper se definen sin revisar el layout final de 375px, los textos de paso pueden quedar truncados en la Fase 2. La Fase 1 debe incluir una lista completa de keys (ver Ajuste 1).

### Fase 2 — Wizard completo

**Indicador de progreso (`EventStepIndicator`) en 375px:**
Con 4 pasos, el espacio disponible por paso es aproximadamente 88px. Mostrar un número de paso circular + etiqueta corta debajo de cada círculo es la única distribución que cabe sin truncar. Las etiquetas deben ser ≤8 caracteres (p.ej. "Básico", "Detalles", "Ruta", "Revisar"). Si se usan etiquetas más largas la solución obvia es solo mostrar el número activo con líneas de conexión entre los pasos inactivos. Esto debe definirse en el plan detallado de Fase 2 antes de implementar `EventStepIndicator` (ver Ajuste 5).

**Touch targets:**
- `EventStepNavBar` (botones Atrás / Continuar): deben usar `AppButton` que ya garantiza 44px de altura mínima. El bottom bar necesita `SafeArea` o padding equivalente sobre el home indicator en iOS.
- "Guardar borrador" en Step 4 es actualmente un `DraftLink` (solo texto). Si este widget sobrevive como enlace de texto en el Step 4, su área de tap (height) debe ser ≥48px con padding explícito — no confiar en el tamaño de la fuente.
- El área de portada en Step 1 (tap para abrir `CoverPickerSheet`) debe ser mínimo 120px de altura para ser cómoda.

**Estados por paso:**
- Step 1: idle → (nombre vacío) botón Continuar deshabilitado → (nombre lleno) habilitado.
- Step 1 portada: idle → loading (AI genera) → data (preview) → error (snackbar, no modal).
- Steps 2–3: siempre tienen valores por defecto válidos → Continuar siempre habilitado.
- Step 4: idle → loading (publicar/guardar) → success (pop) → error (snackbar).
- El plan no especifica qué ocurre si el usuario retrocede a Step 1 desde Step 4 y borra el nombre. La validación al avanzar debe re-evaluarse. No es bloqueante, pero el cubit debe no asumir que el estado de validación previa persiste.

**`CoverPickerSheet`:**
El plan lo lista como widget nuevo. Debe mapear exactamente a los dos CTAs existentes en `FormImageSection` (galería + generar con IA) — no introducir patrones nuevos. Reutilizar `AppButton` para ambas opciones dentro del bottom sheet.

**Step 4 — Review:**
La propuesta no delimita qué información muestra. Renderizar `flutter_quill` en modo solo-lectura, mapa de ruta completo y pickers de marcas dentro de Step 4 dispararía el costo de la fase. El plan debe acotar Step 4 a un resumen de texto plano (ver Ajuste 6).

**Animación de transición:**
El plan menciona `AnimatedSwitcher` sobre el `IndexedStack`. Es la solución correcta. El `key` del child del `AnimatedSwitcher` debe ser `ValueKey(currentStep)` para forzar el swap. Si esto no se especifica en el plan detallado, el implementador puede usar el `AnimatedSwitcher` sin cambiar el key y la animación nunca dispara.

### Fase 3 — Cobertura y cierre

Sin impacto UX directo. El valor es la seguridad de no regresión.

**Estado idle de los tests:** Los tests de cubit de pasos son straightforward. El riesgo es sobre-scopear widget tests para los 4 steps. Ver Ajuste 7.

---

## Gates de calidad

### Fase 1

| Gate | Estado esperado | Riesgo |
|------|-----------------|--------|
| `EventFormState.currentStep` añadido como `int` con default `0` | Debe regenerar `event_form_cubit.freezed.dart` — el plan menciona esto pero no dice quién lo ejecuta | Bajo: el implementador debe saber correr `build_runner` |
| `city: ''` en `buildEventToSave()` y `buildDraftToSave()` | Aceptable por el API (`@IsString()` sin `@IsNotEmpty()`) | Bajo |
| `generateCover()` sin `city` hardcoded | Requiere decisión de qué string se pasa — ver Ajuste 2 | **Alto si no se decide antes** |
| `EventFormDetailsSection` eliminado | Código muerto, safe | Bajo |
| ARB strings completos para el stepper | Si se omiten keys, la Fase 2 hardcodea strings | Medio |
| Campo-por-paso centralizado en el cubit | Si no se hace en Fase 1, la validación por paso en Fase 2 queda acoplada a los widgets | Medio |

### Fase 2

| Gate | Estado esperado | Riesgo |
|------|-----------------|--------|
| Un widget por archivo en `widgets/steps/` | Regla crítica de coding-standards | Bajo con disciplina |
| Sin métodos `Widget _buildXxx()` | El `EventFormStep4Review` es el más tentador para violar esta regla (muchos campos de resumen) | **Medio** |
| `AppButton` en `EventStepNavBar`, no `ElevatedButton` | Fácil de verificar en revisión | Bajo |
| Strings via `context.l10n` en todos los nuevos widgets | Depende de que Fase 1 haya creado todos los ARB keys | Bajo si Fase 1 los crea |
| `CoverPlaceholderView` no eliminado | El plan lo reconoce correctamente | Bajo |
| `draft_link.dart` y `publish_button.dart` eliminados junto con `EventFormBottomBar` | Si se olvidan quedan imports huérfanos que rompen `dart analyze` | Medio — ver Ajuste 4 |
| Modo edición (`isEditing = true`) sin regresión | El scroll form debe seguir funcionando | **Alto si `EventFormContent` se borra sin guardar el path de edición** |
| `IndexedStack` envuelto por `FormBuilder` global | `formKey` accesible desde todos los pasos | Bajo |
| `AnimatedSwitcher` con `ValueKey(currentStep)` | Sin key la animación no funciona | Medio |

### Fase 3

| Gate | Estado esperado |
|------|-----------------|
| `dart analyze` sin warnings ni errores | Bloqueante para merge |
| Tests de cubit: `nextStep()`, `prevStep()`, `buildEventToSave()` sin `city` | Cubren los ACs de Fase 1 y 2 |
| `event_form_basic_info_section_test.dart` actualizado (sin `city`) | El scan detectó referencias a `city` en líneas 85, 147, 220 |

---

## Riesgos de scope

### Riesgo 1 — `GenerateCoverDto.city @IsNotEmpty()` (ALTO)

El endpoint `POST /events/generate-cover` rechaza `city: ''` con HTTP 400. Si esto no se resuelve en Fase 1, el botón "Generar con IA" en el nuevo Step 1 estará roto el día que se publique Fase 2. Las dos opciones son:

- **A (sin backend):** Pasar el texto de `meetingPoint` (que el usuario habrá ingresado en Step 3) como proxy. Problema: el usuario rellena la portada en Step 1, antes de tener `meetingPoint`. El texto estará vacío en el flujo lineal del wizard.
- **B (con backend — recomendada):** Hacer `city` opcional (`@IsOptional() @IsString()`) en `GenerateCoverDto` en `rideglory-api`. Es un cambio de 1 línea sin migración de datos. El prompt de Gemini simplemente omite la ciudad si no viene.

La decisión debe tomarse y ejecutarse en Fase 1. El plan la deja abierta; debe cerrarse.

### Riesgo 2 — Edit mode break (ALTO)

`EventFormContent` construye los `initialValues` incluyendo `EventFormFields.city`. Al refactorizar, si `EventFormContent` se elimina sin extraer el path de edición, el modo edición queda roto. El plan reconoce que edición conserva el scroll único, pero no dice explícitamente qué archivos lo sirven después de la Fase 2. El plan detallado debe nombrar el componente que sirve edición.

### Riesgo 3 — Step 4 scope creep (MEDIO)

Sin definición explícita de qué muestra `EventFormStep4Review`, el implementador puede intentar reusar `EventFormBasicInfoSection` (con Quill) en modo solo-lectura, o montar el mapa de ruta dentro del resumen. Esto triplicaría el esfuerzo de Fase 2. El plan detallado debe decir explícitamente "resumen de texto plano".

### Riesgo 4 — `IndexedStack` y widgets pesados en memoria (BAJO-MEDIO)

`EventFormLocationsSection` contiene un Mapbox map widget y `EventFormBasicInfoSection` contiene `flutter_quill`. Tener ambos vivos simultáneamente es aceptable en flagship (iPhone 15, Pixel 8) pero en gama baja puede causar jank. No es bloqueante para el plan actual (sin usuarios reales), pero debe anotarse como tech debt en `EventFormView`.

### Riesgo 5 — Codegen tras añadir `currentStep` (BAJO)

El implementador debe ejecutar `dart run build_runner build --delete-conflicting-outputs` después de tocar `EventFormState`. Si no lo hace, el archivo `.freezed.dart` queda desincronizado y los tests no compilan. No es bloqueante si el plan lo menciona explícitamente.

---

## Ajustes

Los siguientes ajustes deben incorporarse al plan detallado de cada fase antes de ejecutar.

### Ajuste 1 — Fase 1: lista completa de ARB keys antes de implementar el stepper

El plan dice "ARB strings del stepper" sin listar las keys. El plan detallado de Fase 1 debe incluir la tabla completa de keys requeridos para que Fase 2 no tenga strings huérfanos. Keys mínimos:

| Key | Texto sugerido |
|-----|----------------|
| `event_step_basic` | `'Básico'` |
| `event_step_details` | `'Detalles'` |
| `event_step_route` | `'Ruta'` |
| `event_step_review` | `'Revisar'` |
| `event_step_continue` | `'Continuar'` |
| `event_step_back` | `'Atrás'` |
| `event_step_reviewAndPublish` | `'Revisar y publicar'` |
| `event_step_saveDraft` | `'Guardar borrador'` |
| `event_step_progressLabel` | `'Paso {current} de {total}'` |

### Ajuste 2 — Fase 1: cerrar la decisión de `generateCover()` / `city`

La Fase 1 debe incluir como criterio de aceptación explícito: "El método `generateCover()` en el cubit no recibe `city` como parámetro; el backend acepta `city` ausente en `GenerateCoverDto`". Esto requiere el cambio backend (opción B del Riesgo 1). Si el humano decide no hacer el backend change, el AC alternativo es "la portada solo se puede generar una vez que el usuario llena el punto de encuentro en Step 3" — lo que implica reordenar los pasos o bloquear el botón. Debe decidirse antes de ejecutar Fase 2.

### Ajuste 3 — Fase 1: centralizar listas de campos por paso en el cubit

El plan detallado de Fase 1 debe incluir la creación de constantes estáticas en `EventFormCubit` (o en `EventFormFields`):

```dart
static const _step1Fields = [EventFormFields.name, EventFormFields.description, ...];
static const _step2Fields = [EventFormFields.difficulty, EventFormFields.eventType, ...];
static const _step3Fields = [EventFormFields.meetingPoint, EventFormFields.destination, ...];
```

Y un método `bool isCurrentStepValid()` en el cubit que filtra `formKey.currentState?.fields` por la lista del paso activo. Sin esto, la validación por paso en Fase 2 queda acoplada a los widgets de paso.

### Ajuste 4 — Fase 2: eliminar `draft_link.dart` y `publish_button.dart` explícitamente

El plan detallado de Fase 2 debe listar `draft_link.dart` y `publish_button.dart` como archivos a eliminar junto con `event_form_bottom_bar.dart`. Ambos son usados únicamente por `EventFormBottomBar`. Si no se listan, quedarán como código muerto que `dart analyze` no detecta pero que ensucia el árbol.

### Ajuste 5 — Fase 2: especificar el layout del `EventStepIndicator` en 375px

El plan detallado de Fase 2 debe especificar la variante de indicador:
- 4 círculos numerados de 28px, separados por líneas de 1px.
- Etiqueta de texto debajo de cada círculo — máximo 8 caracteres.
- El círculo activo usa `colorScheme.primary` (naranja); texto del número usa `AppColors.darkBgPrimary` (oscuro, no blanco — regla de acento).
- Círculos completados usan un fill semitransparente del primario; círculos futuros usan `colorScheme.surfaceContainerHighest`.

### Ajuste 6 — Fase 2: acotar `EventFormStep4Review` a resumen de texto plano

El plan detallado de Fase 2 debe incluir la restricción: "Step 4 no reutiliza `EventFormBasicInfoSection` ni widgets de ubicación/mapa. Muestra únicamente valores de texto ya capturados: título, descripción (texto plano sin formato Quill), fecha/hora, dificultad, tipo, punto de encuentro/destino, marcas, participantes, precio." Esto mantiene Fase 2 en el esfuerzo esperado.

### Ajuste 7 — Fase 3: acotar tests a cubit + 1 widget crítico

El plan detallado de Fase 3 debe especificar el scope mínimo de tests:
- **Cubit:** `nextStep()`, `prevStep()`, `isCurrentStepValid()` con campos vacíos/llenos, `buildEventToSave()` sin `city`.
- **Widget (1 test):** `EventFormStep1` smoke test — renderiza sin overflow, el botón Continuar está deshabilitado con nombre vacío y habilitado con nombre lleno.
- No es necesario cubrir `EventFormStep2`, `Step3`, `Step4Review` con widget tests en esta iteración.
