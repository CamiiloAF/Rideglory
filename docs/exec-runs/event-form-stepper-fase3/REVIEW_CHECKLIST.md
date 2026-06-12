# Review Checklist — event-form-stepper-fase3

Pasos manuales antes de commitear. Todos los items marcados como BLOCKER deben resolverse.

---

## Blockers — Código (deben resolverse antes del commit)

- [ ] **B1 — `review_row.dart:44`**: Eliminar `Widget _rowContent()`. Opciones:
  - Inline el `if/else` directamente en `build()` (sin método auxiliar).
  - O crear `lib/.../steps/review_row_content.dart` como clase `ReviewRowContent extends StatelessWidget` y referenciarla desde `build()`.
  - Confirmar con `dart analyze lib/` que no quedan warnings.

- [ ] **B2 — `navigation_row.dart:30`**: Reemplazar `GestureDetector + Container` del botón "Atrás" con:
  ```dart
  AppButton(
    label: context.l10n.event_step_back,
    onPressed: isSaving ? null : cubit.prevStep,
    variant: AppButtonVariant.secondary,
    style: AppButtonStyle.filled,
    shape: AppButtonShape.pill,
    height: 52,
  )
  ```
  Si `AppButtonVariant.secondary` no produce el color `#242429`, agregar `// Custom: AppButton.secondary difiere del tono Pencil EzQtb #242429` junto al GestureDetector.

- [ ] **B3 — `publish_row.dart:39`**: Reemplazar `GestureDetector + Container` del botón "Guardar borrador" con `AppButton(variant: secondary, shape: pill, height: 44)` o con `AppTextButton(label: ..., variant: muted)`. Si no cubre el tono exacto, documentar con `// Custom:`.

- [ ] **B4 — `route_cta_bar.dart`**: Evaluar si `AppButton` puede cubrir los dos estados (activo con glow / deshabilitado). Si el glow shadow no es soportado, mantener el `GestureDetector` con comentario explícito: `// Custom: AppButton no soporta boxShadow glow requerido por Pencil spec veaGt`.

- [ ] **B5 — `Color(0xFF...)` en build()**: Agregar en `AppColors` las constantes que faltan (o verificar si ya existe un alias):
  - `0xFF1A1A1F` → `AppColors.darkBgInput` (o verificar nombre existente)
  - `0xFF1E1E24` → `AppColors.darkBgCard` (o `AppColors.darkCard` si existe)
  - `0xFF2A2A32` → `AppColors.darkBorderSubtle` (o `AppColors.darkBorderPrimary` si es el mismo)
  - `0xFF6B7280` → `AppColors.textOnDarkDisabled`
  - `0xFF9CA3AF` → `AppColors.textOnDarkMuted`
  - `0xFF2D2117` → `AppColors.primaryGlowShadow` (o verificar `AppColors.primarySubtle`)
  Luego reemplazar todos los usos en: `step_circle.dart`, `route_cta_bar.dart`, `review_row.dart`, `review_card.dart`, `route_search_bar.dart`, `route_map_area.dart`, `navigation_row.dart`, `publish_row.dart`.
  Ejecutar `dart analyze lib/` al terminar.

---

## Verificación automática (después de los fixes)

- [ ] `dart analyze lib/` → "No issues found!"
- [ ] `flutter test` → 824 tests, 0 failing
- [ ] `grep -r "EventFormFields.city" lib/features/events/presentation/` → sin resultados

---

## Pruebas manuales del wizard (validación visual)

- [ ] `flutter run --flavor dev --dart-define-from-file=config/dev.json`
- [ ] Navegar a "Crear Evento" — el step indicator muestra 4 pasos con labels y círculos correctos
- [ ] Paso 1: dejar nombre vacío → "Continuar" deshabilitado (gris, opacidad)
- [ ] Paso 1: escribir un nombre → "Continuar" habilitado (naranja, pill)
- [ ] Navegar 1→2→3→4 y volver con "Atrás" — indicator actualiza correctamente
- [ ] Paso 4 (Revisión): cards con iconos, 4 secciones (Básico, Configuración, Ruta, Fecha y hora)
- [ ] Paso 4: botones "Editar" en cada card navegan al paso correcto
- [ ] Paso 4: "Publicar evento" (pill naranja) y "Guardar borrador" (pill oscuro) visibles
- [ ] Flujo edición evento existente: NO se muestra `EventStepIndicator`
- [ ] Route builder: barra de búsqueda con focus state (borde naranja), botón recenter circular abajo-derecha
- [ ] Route builder: banner de límite (9 waypoints) full-width sin radio
