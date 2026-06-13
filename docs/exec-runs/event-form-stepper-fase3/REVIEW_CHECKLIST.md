# Review Checklist — event-form-stepper-fase3

**Actualizado:** 2026-06-12T05:10:57Z — Re-review post fix-run. B1/B4/B5 resueltos. B2/B3 requieren corrección adicional (regresión visual).

Pasos manuales antes de commitear. Todos los items marcados como BLOCKER deben resolverse.

---

## Blockers — Código (deben resolverse antes del commit)

- [x] **B1 — `review_row.dart`**: `_rowContent()` eliminado; contenido inlineado como `Widget content` variable local. RESUELTO ✓

- [ ] **B2 — `navigation_row.dart:30`** (**NUEVO** — regresión introducida por fix-run):
  El `AppButton(variant: AppButtonVariant.secondary, style: filled)` renderiza con `backgroundColor = cs.secondary = AppColors.secondary = Color(0xFFfbab56)` (naranja-ámbar), NO el `Color(0xFF242429)` (darkTertiary) requerido por el spec Pencil.
  **Fix opción A (mínima):** Revertir a `GestureDetector + Container` con `// Custom:`:
  ```dart
  // Custom: AppButton.secondary = cs.secondary (#fbab56, naranja) no coincide
  // con spec Pencil (#242429 darkTertiary); AppButton no tiene variante dark.
  GestureDetector(
    onTap: isSaving ? null : cubit.prevStep,
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.darkTertiary,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Center(
        child: Text(
          context.l10n.event_step_back,
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 15,
            color: AppColors.textOnDarkPrimary,
          ),
        ),
      ),
    ),
  )
  ```
  **Fix opción B (preferida):** Agregar `AppButtonVariant.ghost` a `AppButton` con fill `AppColors.darkTertiary` y texto `AppColors.textOnDarkPrimary`, luego usar ese variant.

- [ ] **B3 — `publish_row.dart:39`** (**NUEVO** — misma regresión): `AppButton(variant: secondary)` = naranja. Misma solución que B2, con `height: 44` y label `event_step_saveDraft`.

- [x] **B4 — `route_cta_bar.dart`**: `// Custom:` comments agregados en ambos estados; colores inline → AppColors. RESUELTO ✓

- [x] **B5 — `Color(0xFF...)` en build()**: Todos los colores inline reemplazados por constantes AppColors existentes en step_circle, route_cta_bar, review_row, review_card, route_search_bar, route_map_area. RESUELTO ✓

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
