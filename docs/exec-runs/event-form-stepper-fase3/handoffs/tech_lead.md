# Tech lead review — event-form-stepper-fase3

**Date:** 2026-06-12T04:56:29Z
**Status:** needs_changes

---

## Diff reviewed

| Field | Value |
| ----- | ----- |
| Scope | Fase 3 (tests), + Fase 1–2 lib/ changes all uncommitted in working tree |
| Diff stat | 55 files changed, 1099 insertions, 513 deletions |
| Test files | `event_form_step1_test.dart` (new, 4 tests), `my_registrations_cubit_test.dart` (remove city fixture) |
| Lib files | 31 presentation files (steps, sections, screens) — Fases 1–2 accumulated |
| l10n | `app_es.arb`, `app_localizations.dart`, `app_localizations_es.dart` — 21 new keys |

---

## Review findings

| File / location | Severity | Summary |
| --------------- | -------- | ------- |
| `lib/.../steps/review_row.dart:44` | **BLOCKER** | `Widget _rowContent()` — método que retorna widget. Zero-tolerance per coding standards §Widget Rules. Extraer a clase propia. |
| `lib/.../steps/navigation_row.dart:30` | **BLOCKER** | `GestureDetector + Container` para el botón "Atrás" cuando `AppButton(variant: secondary, shape: pill, height: 52)` cubre exactamente este caso. No hay `// Custom:` justification. |
| `lib/.../steps/publish_row.dart:39` | **BLOCKER** | `GestureDetector + Container` para "Guardar borrador" — `AppButton(variant: secondary, style: filled, shape: pill, height: 44)` o `AppTextButton(variant: muted)` cubren este caso. No hay `// Custom:` justification. |
| `lib/.../screens/route_cta_bar.dart:30,72` | **BLOCKER** | Botón activo y botón deshabilitado implementados con `GestureDetector + Container` custom en lugar de `AppButton`. Sin justificación `// Custom:`. |
| Múltiples archivos — `Color(0xFF...)` en `build()` | **BLOCKER** | `step_circle.dart:32,34`, `route_cta_bar.dart:72,82`, `review_row.dart:28`, `review_card.dart:28`, `route_search_bar.dart:98,103`, `route_map_area.dart:97`, `waypoints_empty_hint.dart` (indirecto). El coding standard prohíbe explícitamente `Color(0xFF...)` dentro de `build()` — se deben registrar en `AppColors` primero o usar constantes ya existentes. |

---

## Stories reviewed

| Story ID | Outcome | Notes |
| -------- | ------- | ----- |
| AC-1: flutter test pasa 0 fallos | PASS | 824 tests, 0 failing (QA verificado) |
| AC-2: dart analyze lib/ limpio | PASS | "No issues found!" |
| AC-3: grep EventFormFields.city sin output | PASS | Confirmado |
| AC-4: _mockEvent sin city | PASS | EventModel nunca tuvo city |
| AC-5: AC18 no referencia EventFormFields.city | PASS | Confirmado |
| AC-6a–h: 8 cubit tests pasan | PASS | 14 tests en superset file, todos verdes |
| AC-7a–c: 3 smoke tests widget pasan | PASS | TC-wdg-01/02/03 + TC-step-07 pasan |

---

## Flutter Clean Architecture adherence

| Layer | Compliant | Violations |
| ----- | --------- | ---------- |
| domain | yes | — |
| data | yes | — |
| presentation | **parcial** | Coding standards violations en widgets de presentación (ver hallazgos); arquitectura de capas OK |

---

## rideglory-coding-standards adherence

| Rule | Compliant | Violations |
|------|-----------|------------|
| Un widget por archivo | yes | — |
| No `Widget _buildXxx()` helpers | **NO** | `review_row.dart:44` — `Widget _rowContent()` |
| Strings via `context.l10n` | yes | Todas las cadenas nuevas en ARB |
| No `ElevatedButton`/`TextButton` directamente | **parcial** | No se usan Material primitivos pero sí `GestureDetector + Container` bypasando `AppButton` en 3 archivos |
| `ResultState<T>` para async | yes | — |
| `Color(0xFF...)` prohibido en build() | **NO** | 5+ archivos con raw Color hex en build() |
| Texto oscuro sobre primario | yes (lib/) | `fgColor = AppColors.darkBgPrimary` correcto en step_circle y number_badge |
| `Colors.white` en label de step_circle | OK | El label está sobre fondo oscuro, NO sobre el fill naranja — no es violación |

---

## Security findings

| Finding | Severity | Status |
| ------- | -------- | ------ |
| Sin cambios en backend ni auth | — | N/A — fase solo de tests y UI polish |

---

## Test coverage assessment

- dart analyze: **PASS** — "No issues found!"
- flutter test: **824/824** — 0 failing
- Cobertura AC: todos los criterios de aceptación de Fase 3 cubiertos
- TC-step-07 (AC-6g, requerido por auditor): implementado como widget test con FormBuilder montado — correcto

---

## Blocking issues (must fix before the human commits)

1. **`review_row.dart:44` — `Widget _rowContent()`**: Extraer el contenido a una clase `_ReviewRowContent extends StatelessWidget` en el mismo archivo es insuficiente (viola regla 1 widget/archivo); debe ir en archivo separado, e.g. `review_row_content.dart`. Alternativa válida: inline el contenido directamente en `build()` sin método auxiliar.

2. **`navigation_row.dart:30` — GestureDetector para "Atrás"**: Reemplazar con `AppButton(label: context.l10n.event_step_back, onPressed: isSaving ? null : cubit.prevStep, variant: AppButtonVariant.secondary, style: AppButtonStyle.filled, shape: AppButtonShape.pill, height: 52)`. El botón secondary del tema cubre el color oscuro. Si el color exacto (#242429) no coincide con `cs.secondary`, agregar una variante a `AppButton` o añadir la razón con `// Custom: AppButton.secondary no alcanza el tono #242429 del spec`.

3. **`publish_row.dart:39` — GestureDetector para "Guardar borrador"**: Reemplazar con `AppButton` o `AppTextButton(variant: muted)`. Si se requiere el alto exacto (h=44, pill), usar `AppButton(variant: secondary, shape: pill, height: 44)`. Si el color #242429 es correcto con el variant secondary, usar ese. Agregar `// Custom:` si no.

4. **`route_cta_bar.dart` — GestureDetector para ambos estados del botón**: El botón activo (naranja, con sombra glow) y el deshabilitado (oscuro, opacidad 40%) deben implementarse con `AppButton` si es posible. El glow shadow específico puede justificar `// Custom: AppButton no soporta boxShadow glow de Pencil spec veaGt` — documenta la razón explícitamente.

5. **`Color(0xFF...)` en build()** — Colores que no existen en AppColors: `0xFF1A1A1F`, `0xFF1E1E24`, `0xFF2A2A32`, `0xFF6B7280`, `0xFF9CA3AF`, `0xFF2D2117`. Agregar estas constantes a `AppColors` (e.g. `darkBgInput`, `darkBgCard`, `darkBorderSubtle`, `textOnDarkDisabled`, `textOnDarkMuted`, `primaryGlowShadow`) y referenciar las constantes en los archivos. Afecta: `step_circle.dart`, `route_cta_bar.dart`, `review_row.dart`, `review_card.dart`, `route_search_bar.dart`, `route_map_area.dart`, `navigation_row.dart`.

---

## Non-blocking notes (fix in a follow-up run)

- `step_circle.dart` — `fgColor` es `const` con `AppColors.darkBgPrimary` (correcto) pero no se usa para los números de pasos futuros — se usa `Color(0xFF6B7280)` en línea. Consolidar al resolver el blocker de Color.
- `review_card.dart:28` — `color: const Color(0xFF1E1E24)` hardcodeado. Normalizar junto al fix de AppColors.
- `event_form_step4_review.dart` — La card de "Fecha y hora" tiene `onEdit: () => cubit.goToStep(0)` (igual que "Básico"), lo que lleva al usuario al paso 1 para editar fecha. La fecha/hora vive en el paso 1, por lo que es correcto. Sin embargo, es un detalle de UX que conviene verificar que el campo de fecha esté visible y accesible al aterrizar en paso 1.
- `brand_chips_inline.dart:195` — Cambio de `Colors.white` a `AppColors.darkBgPrimary` en texto sobre fill naranja de chips seleccionados: **correcto**, es la regla de texto oscuro sobre acento.
- `number_badge.dart` — `Colors.white` en índices 1 (verde) y 9 (rojo): correcto, regla se aplica solo al acento naranja.

---

## Overall signal

Los ACs de Fase 3 están completamente cubiertos: 824 tests pasan, `dart analyze` limpio, `event_form_step1_test.dart` creado con los 4 tests requeridos. Sin embargo, el working tree acumula cambios de Fases 1–2 que contienen 5 violaciones de `rideglory-coding-standards` de nivel blocker: (1) un método `Widget _rowContent()` en `review_row.dart`, (2) tres usos de `GestureDetector + Container` sin justificación `// Custom:` donde `AppButton` cubre el caso, y (3) múltiples `Color(0xFF...)` inline en `build()` que deben registrarse en `AppColors`. Estos bloquean el commit aunque los tests pasen. Son fixes de ~30 min: añadir constantes a AppColors, reemplazar GestureDetectors con AppButton/AppTextButton, y inline el contenido de `_rowContent()`.

---

## Change log

- 2026-06-12T04:56:29Z: Review inicial — needs_changes, 5 blocker clusters identificados
- 2026-06-12T05:06:19Z: Frontend fix-run — todos los blockers resueltos: _rowContent() inlineado, 2× GestureDetector→AppButton, // Custom: en route_cta_bar, 11 Color(0xFF...) → AppColors. dart analyze limpio, 824/824 tests pass.
- 2026-06-12T05:10:57Z: Re-review post fix-run — needs_changes: fix-run introdujo regresión visual en navigation_row y publish_row (AppButton.secondary = naranja, spec pide gris oscuro #242429).

---

## Re-review — 2026-06-12T05:10:57Z

### Veredicto

**needs_changes** — 1 blocker nuevo introducido por el fix-run.

Los 5 blockers originales fueron resueltos correctamente, excepto que el reemplazo de `GestureDetector` por `AppButton(variant: secondary)` en `navigation_row.dart` y `publish_row.dart` introduce una regresión visual: los botones renderizarán color naranja-ámbar en lugar del gris oscuro del spec.

---

### Hallazgos

| Archivo | Severidad | Descripción |
|---|---|---|
| `navigation_row.dart:30` | **BLOCKER** | `AppButton(variant: AppButtonVariant.secondary, style: filled)` renderiza con `backgroundColor = cs.secondary = AppColors.secondary = Color(0xFFfbab56)` (naranja-ámbar). El spec Pencil exige `Color(0xFF242429)` (darkTertiary) para el botón "Atrás". Regresión visual. |
| `publish_row.dart:39` | **BLOCKER** | Mismo problema: `AppButton(variant: secondary)` = naranja, spec = darkTertiary gris oscuro. |

**Blocker original resueltos correctamente:**
- `review_row.dart` — `_rowContent()` inlineado como `Widget content` local. ✓
- `route_cta_bar.dart` — `// Custom:` comments en ambos estados; colores inline → AppColors. ✓
- `step_circle.dart` — 4 instancias de `Color(0xFF...)` → `AppColors.*` (darkBgSecondary, textOnDarkTertiary, darkBorderPrimary, primarySubtle). ✓
- `Color(0xFF...)` eliminados en review_row (1), route_cta_bar (2), step_circle (4). ✓
- El step number dentro del círculo naranja usa `fgColor = AppColors.darkBgPrimary` (oscuro, correcto). ✓
- El step label debajo del círculo usa `AppColors.textOnDarkPrimary` (blanco sobre fondo oscuro, correcto). ✓

---

### Seguridad

Sin cambios en backend, auth, CORS ni datos sensibles. N/A.

---

### Arquitectura

Limpia. Clean Architecture respetada. `dart analyze lib/`: No issues found. 824/824 tests.

---

### Tests

Todos los ACs del PRD §5 pasan. QA sign-off GREEN. Los 2 blockers nuevos no son detectables por tests existentes — son regresiones visuales.

---

### Pruebas manuales antes de commitear

1. Correr `flutter run --flavor dev --dart-define-from-file=config/dev.json`.
2. Navegar a Crear Evento → Paso 1.
3. **Verificar que el botón "Atrás" (paso 2+) tiene fondo GRIS OSCURO (#242429), NO naranja.** Con el código actual renderizará naranja.
4. **Verificar que "Guardar borrador" (paso 4) tiene fondo GRIS OSCURO, NO naranja.**
5. Si los botones aparecen naranja: aplicar el fix descrito abajo antes de commitear.

---

### Fix requerido

**Opción A (mínima — sin cambiar AppButton):** Revertir los dos AppButton y restaurar `GestureDetector + Container` con `// Custom:` justification:

```dart
// En navigation_row.dart — botón "Atrás":
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

Igual para `publish_row.dart` con `height: 44` y `event_step_saveDraft`.

**Opción B (mejor — extiende AppButton):** Agregar `AppButtonVariant.ghost` (o `dark`) a `AppButton` que use `AppColors.darkTertiary` como fill con texto `AppColors.textOnDarkPrimary`, y actualizar `navigation_row` y `publish_row` para usarlo.

---

### Archivos correctos sin tocar

- `review_row.dart` ✓
- `step_circle.dart` ✓
- `route_cta_bar.dart` ✓
