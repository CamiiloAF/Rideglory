# Plan: event-form-stepper

> Estado: APROBADO — auditoría UX completada (2026-06-11). Diseño en Pencil actualizado con blockers B-1 a B-6 resueltos y sugerencias S-2/S-3/S-4/S-5 aplicadas. Fase 2 actualizada para incorporar cambios de diseño.

---

## Overview

El formulario de creación de eventos pasa de un scroll único a un wizard de 4 pasos (Básico → Detalles → Ruta → Revisión) con indicador de progreso, navegación Atrás/Continuar, pantalla de revisión antes de publicar y opción de guardar borrador desde Step 4. La ciudad desaparece del formulario: la cadena completa `GetGenerateCoverUseCase → EventCoverRepository` (interface) → `EventCoverRepositoryImpl` pasa a tratar `city` como `String?`, el impl omite la clave del body cuando `city` es null o vacío, y `GenerateCoverDto.city` se marca `@IsOptional()` en el backend. `city: ''` se usa en los payloads de creación/borrador. `meetingPointName` actúa como proxy geográfico para el contexto IA de descripción. El plan se ejecuta en 3 fases secuenciales (1 → 2 → 3). La Fase 1 es el único momento con toque de `rideglory-api`. Las Fases 2 y 3 son exclusivamente Flutter.

---

## Fases

- **Fase 1** `[NORMAL]`: [Fase 1 — Fundación técnica](phases/phase-01-fundacion-tecnica.md)
- **Fase 2** `[NORMAL]`: [Fase 2 — Wizard completo](phases/phase-02-wizard-completo.md)
- **Fase 3** `[LITE]`: [Fase 3 — Cobertura y cierre](phases/phase-03-cobertura-y-cierre.md)

---

## Supuestos

1. **La generación de portada con IA fue eliminada del flujo de creación.** `CoverPickerSheet` solo tiene "Subir desde galería". La cadena `EventCoverRepository → GetGenerateCoverUseCase → EventCoverRepositoryImpl` ya no es invocada desde el formulario de creación. El retiro técnico completo pertenece a la Fase 5 del plan `ai-event-generation`.
2. El modo **edición** (`isEditing == true`) conserva el flujo de scroll único sin ningún cambio de comportamiento; el wizard aplica exclusivamente al modo de creación.
3. `meetingPointName` (campo de `EventFormState`) es la única fuente de verdad para el valor de `city` en los payloads de creación y borrador; ningún campo de formulario registra `city` en el modo wizard.
4. Las reglas de diseño existentes aplican: texto/iconos/badges sobre acento naranja deben usar `AppColors.darkBgPrimary`, nunca blanco (`Colors.white`).
5. El mapa de Mapbox (`RouteMapPreview` / `MapWidget`) se construye en modo lazy — `IndexedStack` construye todos los hijos en el árbol, por lo que `EventFormLocationsSection` necesita el parámetro `isActive` para devolver `SizedBox.shrink()` cuando el paso 3 no está activo.
6. El campo `EventFormFields.city` desaparece únicamente de la capa de presentación del modo wizard. La columna `city` en la base de datos no cambia y el payload de creación de evento sigue incluyendo `city: ''` como cadena vacía.
7. No existen usuarios reales en producción activos; los refactors de formulario son seguros siempre que los tests pasen.

---

## Riesgos

| ID | Fase | Riesgo | Prob | Impacto | Mitigación |
|----|------|--------|------|---------|-----------|
| R-01 | 1 | Archivos `??` (untracked) en `lib/features/events/` al iniciar — trabajo en progreso de la feature de IA | Alta | Alto | Prerrequisito bloqueante en Fase 1 Paso 1: ejecutar `git status --short lib/features/events/`; detener si hay untracked y esperar instrucción humana |
| R-02 | 1 | `buildEventToSave()` hace cast duro `formData[city] as String` — puede arrojar null cast error si el campo no fue rellenado | Media | Medio | Fase 1 Paso 7: cambiar a `(formData[EventFormFields.city] as String?)?.trim() ?? ''` |
| R-03 | 1 | Codegen freezed falla si `event_form_cubit.dart` tiene syntax error o conflicto de `part` | Baja | Bajo | Correr `dart run build_runner clean` antes de `build` si hay conflictos |
| R-04 | 1 | `event_form_details_section.dart` o los widgets bajo `sections/details/` tienen imports en call sites no identificados | Baja | Bajo | Fase 1 Paso 11: `grep -r` obligatorio antes de borrar |
| R-05 | 1 | `flutter gen-l10n` falla si `event_step_progressLabel` no declara los placeholders con tipo `int` | Baja | Medio | Verificar sección `@event_step_progressLabel` con `placeholders: { current: { type: int }, total: { type: int } }` |
| R-06 | 1 | `@IsOptional()` puesto después de `@IsString()` en el DTO de NestJS — class-validator sigue rechazando requests sin `city` | Baja | Bajo | Fase 1 Paso 2 especifica el orden explícito: `@IsOptional()` primero |
| R-07 | 1 | `IsOptional` no importado en `generate-cover.dto.ts` — TypeScript falla con `TS2304: Cannot find name 'IsOptional'` | Baja | Alto | Fase 1 Paso 2: actualizar import a `{ IsNotEmpty, IsOptional, IsString }` |
| R-08 | 1 | `validateStep(0) == true` no puede verificarse en test de cubit puro porque requiere FormBuilder montado | Media | Bajo | Criterio 4 separado como widget test; documentado explícitamente |
| R-09 | 1-2 | Fase 2 asume que todos los campos de `_step2Fields`/`_step3Fields` existen en `formKey.currentState.fields` | Media | Medio | `meetingPoint`, `destination`, `waypoints` e `isFreeEvent` pueden gestionarse via `EventFormState`, no FormBuilder; Fase 2 deberá distinguir ambas fuentes |
| R-10 | 2 | `EventFormView` convertido a `StatefulWidget` rompe contexto de cubit si `BlocProvider` está bajo él | Baja | Alto | Verificar que `EventFormPage` provee el `BlocProvider<EventFormCubit>` por encima de `EventFormView` |
| R-11 | 2 | `EventFormLocationsSection` no tenía parámetro `isActive` — call sites en modo edición deben actualizarse | Media | Medio | `grep -rn "EventFormLocationsSection" lib/` antes de modificar el constructor; añadir `isActive: true` en call sites de edición |
| R-12 | 2 | `EventFormStep4Review` muestra la descripción de Quill como string raw (Delta JSON) | Media | Medio | Si el value empieza con `[`, usar `Document.fromJson(jsonDecode(value)).toPlainText()`; no renderizar `QuillEditor` |
| R-13 | 2 | Keys ARB de Fase 1 y Fase 2 podrían solaparse (e.g., `event_step_basic` vs `event_stepLabelInfo`) | Baja | Bajo | `grep -n "event_step" lib/l10n/app_es.arb` antes de añadir nuevas keys |
| R-14 | 3 | `buildDraftToSave()` no fue refactorizado para derivar `city` de `state.meetingPointName` en Fase 1/2 | Media | Alto | TC-step-07 falla con `city == ''`; escalar como bug bloqueante a Fase 1/2 — no auto-remediar |
| R-15 | 3 | `AiDescriptionChatCubit` no registrado en GetIt del test → `LateInitializationError` al montar Step1 | Media | Medio | Mock registrado en `setUp` via `getIt.registerFactory`; `tearDown` lo desregistra |
| R-16 | 3 | `event_step_continue` ARB key no existe (faltó en Fase 2) | Baja | Medio | Fase 3 Paso 1 verifica la key antes de continuar; escala a Fase 2 si falta |

---

## Como ejecutar una fase

> Cada fase se implementa con `rg-exec` en el nivel recomendado (ver el `[LITE/NORMAL/FULL]` del título y la sección "Ejecución recomendada" de cada fase).

```js
// Fase 1
Workflow({ name: 'rg-exec', args: { source: 'docs/plans/event-form-stepper/phases/phase-01-fundacion-tecnica.md', mode: 'normal' } })

// Fase 2
Workflow({ name: 'rg-exec', args: { source: 'docs/plans/event-form-stepper/phases/phase-02-wizard-completo.md', mode: 'normal' } })

// Fase 3
Workflow({ name: 'rg-exec', args: { source: 'docs/plans/event-form-stepper/phases/phase-03-cobertura-y-cierre.md', mode: 'lite' } })
```

> `lite` = mecánico/bajo riesgo; `normal` = feature acotada; `full` = complejo/riesgoso (contratos, migraciones, seguridad).
