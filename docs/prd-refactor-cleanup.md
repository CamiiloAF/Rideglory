# PRD — Refactor & Cleanup Extremo (Iter Refactor-01)

**Fecha:** 2026-05-27  
**Autor:** Camilo Agudelo  
**Estado:** Draft

---

## 1. Contexto y Motivación

El codebase de Rideglory ha acumulado deuda técnica significativa durante las iteraciones de features recientes. Un análisis estático exhaustivo reveló **68 archivos** con violaciones críticas de las reglas definidas en `rideglory-coding-standards.mdc` y `agent-flutter-developer.mdc`, afectando **todas** las features del proyecto (authentication, events, vehicles, maintenance, home, profile, users, event_registration).

Estas deudas no son estéticas: generan:
- **Bugs reales** (botón SOAT muestra texto "Descargando…" en vez del spinner centralizado de `AppButton`)
- **Inconsistencia de UX** (botones raw `ElevatedButton`/`TextButton` con estilos distintos al design system)
- **Mantenibilidad nula** (archivos de 982 líneas con 9-16 clases widget distintas)
- **Duplicación de código** (dos implementaciones SOAT conviviendo: `features/soat/` y `features/vehicles/presentation/soat/`)

---

## 2. Objetivo

Realizar un refactoring completo y sin cambios funcionales, para llevar **todo** el código existente al cumplimiento 100% de los estándares definidos. Ninguna funcionalidad debe romperse; los tests actuales deben seguir pasando.

**Resultado esperado:** `dart analyze` con 0 warnings en `lib/`, todos los estándares cumplidos, y un codebase homogéneo y mantenible.

---

## 3. Análisis Detallado de Violaciones

### 3.1 Violación Crítica: Múltiples widgets por archivo

**Regla violada:** "Máximo 1 clase widget por archivo — sin excepciones"

| Archivo | Widgets encontrados |
|---------|---------------------|
| `garage_vehicles_content.dart` | **16** |
| `vehicle_detail_view.dart` | **13** |
| `maintenance_filters_bottom_sheet.dart` | **12** |
| `vehicle_form.dart` | 9 |
| `forgot_password_view.dart` | 9 |
| `event_detail_view.dart` | 9 |
| `login_view.dart` | 8 |
| `event_detail_cta_bar.dart` | 8 |
| `event_form_max_participants_section.dart` | 7 |
| `signup_view.dart` | 6 |
| `event_form_locations_section.dart` | 6 |
| `soat_document_section.dart` | 5 |
| `home_event_card.dart` | 5 |
| `event_card.dart` | 5 |
| + 16 archivos más con 2-4 widgets | (ver listado completo abajo) |

**Total: 68 archivos con violación**, en las features: authentication, events, vehicles, maintenance, home, profile, users, event_registration, splash.

Listado completo de archivos con 2-3 widgets (adicionales a la tabla):
- `soat_confirmation_page.dart` (4), `rider_profile_content.dart` (4), `live_map_app_bar.dart` (4), `events_data_view.dart` (4), `event_route_config_screen.dart` (4), `event_form_price_section.dart` (4), `event_detail_owner_lifecycle_bar.dart` (4), `event_detail_meeting_point_section.dart` (4)
- `vehicle_form_id_section.dart` (3), `profile_stats_row.dart` (3), `profile_actions_list.dart` (3), `participants_placeholder_page.dart` (3), `maintenances_page.dart` (3), `maintenance_detail_page.dart` (3), `event_form_multi_brand_section.dart` (3), `event_form_event_type_section.dart` (3), `event_form_difficulty_section.dart` (3), `event_form_details_section.dart` (3), `event_form_bottom_bar.dart` (3), `edit_profile_page.dart` (3)
- 8+ archivos con 2 widgets (ver análisis)

### 3.2 Violación Crítica: Métodos que retornan widgets

**Regla violada:** "Prohibido: métodos que retornan widgets"

| Archivo | Métodos violadores |
|---------|--------------------|
| `garage_vehicles_content.dart` | `Widget _buildContainer()`, `Widget _buildPlaceholderIcon()` |
| `event_detail_by_id_page.dart` | `Widget _shell()` |
| `event_detail_cta_bar.dart` | `Widget _buildContent()` |
| `maintenance_grouped_list_item.dart` | `Widget _rightBadge()` |
| `participants_placeholder_page.dart` | `Widget _buildEmptyState()`, `Widget _buildRiderList()` |
| `event_card_header.dart` | `Widget _buildPopupMenu()` |
| `vehicle_card.dart` | `Widget _buildPlaceholderIcon()` |
| `app_place_suggestions_dropdown.dart` | `Widget _buildContainer()` |

### 3.3 Violación: Botones raw de Flutter en lugar de AppButton/AppTextButton

**Regla violada:** "Prohibido usar ElevatedButton, OutlinedButton, TextButton directamente en features"

25 ocurrencias totales:
- `ElevatedButton` → `rider_profile_content.dart` (1 ocurrencia)
- `TextButton` → `event_form_view.dart` (3), `event_route_config_screen.dart` (1), `end_ride_confirm_dialog.dart` (1), `sos_confirm_dialog.dart` (1)
- `OutlinedButton` → `sos_active_overlay.dart` (1)
- Resto en shared/design_system (dentro de wrappers - pueden ser excepciones justificadas)

### 3.4 Violación: FormBuilderTextField en lugar de AppTextField

**Regla violada:** "Prohibido usar FormBuilderTextField cuando existe AppTextField"

5 ocurrencias:
- `vehicle_specs_row.dart` (1)
- `vehicle_form_id_section.dart` (2)
- `maintenance_next_km_pill.dart` (1)
- `event_form_price_section.dart` (1)

### 3.5 Bug: Botón SOAT muestra texto "Descargando…" en vez de spinner

**Archivo:** `lib/features/soat/presentation/widgets/soat_data_view.dart`

**Problema:** Cuando `_openingDocument = true`, el botón "Ver documento" cambia su `label` a `context.l10n.soat_downloading` ("Descargando…"), en lugar de pasar `isLoading: true` al `AppButton`. El `AppButton` ya tiene soporte nativo de spinner; cambiar el texto es inconsistente con el comportamiento de todos los demás botones de la app.

**Fix requerido:**
```dart
// ❌ Actual (incorrecto)
AppButton(
  label: _openingDocument
      ? context.l10n.soat_downloading
      : context.l10n.soat_view_document,
  onPressed: _openingDocument ? null : _openDocument,
)

// ✅ Correcto
AppButton(
  label: context.l10n.soat_view_document,
  isLoading: _openingDocument,
  onPressed: _openDocument,
)
```

### 3.6 Violación: Navegación con `Navigator.of(context)` en lugar de go_router

**Regla violada:** Preferir `context.pushNamed`, usar `context.goAndClearStack` para limpiar stack.

29 ocurrencias de `Navigator.of(context).` en features. Los más críticos:
- `vehicles/presentation/soat/` (toda la carpeta vieja usa `Navigator.of()`)
- `maintenance/form/maintenance_form_page.dart`
- `event_registration/presentation/widgets/`

### 3.7 Violación: `context.goNamed()` en lugar de `context.pushNamed()`

5 ocurrencias de `context.goNamed()` para navegación normal:
- `profile_page.dart`: `context.goNamed(AppRoutes.home)` en `PopScope`
- `garage_page.dart`: `context.goNamed(AppRoutes.home)` en `PopScope`
- `events_page.dart`: `context.goNamed(AppRoutes.home)` en `PopScope`
- `forgot_password_view.dart`: `context.goNamed(AppRoutes.login)` (×2)

**Nota:** Los usos en `PopScope` pueden ser intencionales para evitar volver al stack anterior; documentar o cambiar según análisis.

### 3.8 Duplicación: Dos implementaciones de SOAT conviviendo

**Situación:**
- `lib/features/soat/` — Implementación nueva (feature propia, con domain/data/presentation completos)
- `lib/features/vehicles/presentation/soat/` — Implementación vieja (solo presentation, sin domain/data propios)

**Router:** Ambas están activas:
- `/vehicles/soat` → usa `vehicle_soat.SoatUploadPage` (la vieja) 
- `/soat/upload` y `/soat/status` → usa `SoatUploadPage` y `SoatStatusPage` (la nueva)
- `soat_status_view.dart` (nueva) importa `SoatManualCapturePage` de la vieja

**Acción requerida:** Consolidar en `features/soat/`, eliminar `vehicles/presentation/soat/`, migrar router.

### 3.9 Violación: Colores hardcodeados

En features se usan `Colors.white`, `Colors.black87`, `Color(0xFFEAB308)`, `Color(0x1AEAB308)` directamente, en lugar de `AppColors.*` o `colorScheme.*`:
- `home_event_view_details_button.dart`: `Colors.white`, `Colors.black87` (×2)
- `home_view_all_events_button.dart`: `Colors.transparent`
- `home_vehicle_info_row.dart`: `Color(0xFFEAB308)`, `Color(0x1AEF4444)`, `Color(0x1AEAB308)` (SOAT warning color no definido en AppColors)

### 3.10 `dart analyze` warnings

1 warning en producción:
- `api_base_url_resolver.dart:19` — dead_code (código inalcanzable)
- `api_base_url_resolver.dart:17` — prefer_const_declarations

### 3.11 `bool isLoadingMore` en NotificationsState

`notifications_state.dart` usa `@Default(false) bool isLoadingMore` como flag primitivo para la carga de paginación. Técnicamente es para "carga incremental" (no es el estado principal), pero viola el principio de evitar flags primitivos. Evaluar si convertir a `ResultState<List<>>` adicional o mantener documentado como excepción justificada para paginación.

---

## 4. Fuera de Alcance

- No se agregan features nuevas
- No se cambia la lógica de negocio
- No se modifica el API ni los DTOs
- No se cambia el diseño visual (solo se corrigen implementaciones internas)
- Los tests de integración Patrol no se modifican (tienen deprecations de `native` que son del framework, no del código de la app)

---

## 5. Criterios de Aceptación

1. ✅ **0 archivos** con más de 1 clase widget (excepto `State<T>` coexistiendo con `StatefulWidget`)
2. ✅ **0 métodos** `Widget _build*()` o `Widget _nombre*()`
3. ✅ **0 usos** de `ElevatedButton`, `OutlinedButton`, `TextButton` directamente en features (salvo excepción documentada con `// Custom: <razón>`)
4. ✅ **0 usos** de `FormBuilderTextField` donde existe `AppTextField` equivalente
5. ✅ **Bug SOAT:** Botón "Ver documento" usa `isLoading: _openingDocument` (no cambia el label)
6. ✅ **0 usos** de `Navigator.of(context).push*` en features donde va go_router
7. ✅ **0 usos** de `Color(0x...)` o `Colors.*` literales en build methods de features (usar `AppColors.*` o `colorScheme.*`)
8. ✅ `dart analyze` retorna 0 warnings/errors en `lib/`
9. ✅ `flutter test` pasa al 100%
10. ✅ Implementación SOAT consolidada en `features/soat/`, `vehicles/presentation/soat/` eliminada
11. ✅ Código eliminado: todas las clases, variables, imports no usados

---

## 6. Iteraciones Propuestas

Dado el volumen (68+ archivos, 9 features), se propone dividir en 3 sub-iteraciones enfocadas:

### Sub-iter A: Bug crítico + Código muerto + dead_code analyze
- Fix bug botón SOAT (soat_data_view)
- Consolidar SOAT: mover todo a `features/soat/`, eliminar `vehicles/presentation/soat/`
- Limpiar dead_code en `api_base_url_resolver.dart`
- Limpiar imports no usados en todos los archivos modificados

### Sub-iter B: Extracción de widgets (archivos con más violaciones)
Prioridad: archivos con 4+ widgets (los de mayor impacto)
- `garage_vehicles_content.dart` (16) → extraer a ~14 archivos
- `vehicle_detail_view.dart` (13) → extraer
- `maintenance_filters_bottom_sheet.dart` (12) → extraer
- `vehicle_form.dart` (9) → extraer
- `forgot_password_view.dart` (9) → extraer
- `event_detail_view.dart` (9) → extraer
- `login_view.dart` (8) → extraer
- `event_detail_cta_bar.dart` (8) → extraer + limpiar `Widget _buildContent()`
- 12 archivos más con 4 widgets

### Sub-iter C: Reemplazo de primitivos + colores + navegación
- Reemplazar 25 usos de `ElevatedButton/TextButton/OutlinedButton` con `AppButton/AppTextButton`
- Reemplazar 5 usos de `FormBuilderTextField` con `AppTextField`
- Corregir 29 usos de `Navigator.of(context)` con go_router
- Corregir 5 usos de `context.goNamed` → `context.pushNamed` (o documentar)
- Corregir colores hardcodeados con `AppColors.*`
- Limpiar `bool isLoadingMore` de NotificationsState si aplica
- Widget-returning methods restantes: `_shell`, `_rightBadge`, `_buildPopupMenu`, etc.

---

## 7. Riesgos

| Riesgo | Probabilidad | Mitigación |
|--------|-------------|------------|
| Romper flujo de SOAT al consolidar | Alta | Tests manuales antes/después; mantener rutas existentes |
| Extraer widget rompe StatefulWidget con state compartido | Media | Usar callbacks o BLoC para pasar estado; no romper encapsulación |
| Import circular al separar widgets | Baja | Respetar capas; features no importan entre sí |
| Cambio de `Navigator.of` a go_router rompe resultados de retorno (`pop(result)`) | Media | Revisar cada caso antes de migrar |

---

## 8. No-Regresión

- `flutter test` debe pasar antes y después de cada sub-iter
- `dart analyze` debe pasar antes y después de cada sub-iter
- Revisión manual de flujo SOAT (upload → confirmación → status)
- Revisión manual de flujo Login/Signup/ForgotPassword

---

## 9. Archivos de Referencia

- **Estándares:** `.cursor/rules/rideglory-coding-standards.mdc`
- **Dev checklist:** `.cursor/rules/agent-flutter-developer.mdc`
- **AppButton:** `lib/shared/widgets/form/app_button.dart`
- **AppTextField:** `lib/shared/widgets/form/app_text_field.dart`
- **go_router extensions:** `lib/core/extensions/go_router.dart`
- **AppColors:** `lib/core/theme/app_colors.dart` + `lib/design_system/foundation/theme/app_colors.dart`
