# Design handoff — tecnomecanica-rtm-ph1

**Fecha:** 2026-06-04T16:06:36Z
**Status:** done

---

## Resumen de alcance de diseño

Esta fase es **refactor puro de arquitectura** — no hay pantallas nuevas, no hay flujos nuevos, no hay cambios de copy visible para el usuario. El objetivo de diseño es garantizar que la extracción de widgets genéricos y el reemplazo de `VehicleSoatCard` por `VehicleDocumentCard` preserven exactamente la apariencia actual.

---

## Pantallas

### Pantallas afectadas

| Pantalla | Tipo | Cambio visible |
|----------|------|---------------|
| Detalle de vehículo (`vehicle_detail_view.dart`) | UPDATE | Ninguno — `VehicleSoatCard` → `VehicleDocumentCard` con idéntico layout |
| Estado SOAT (`SoatStatusView`) | UPDATE | Ninguno — refactor interno de widgets; Scaffold, AppBar, BlocBuilder intactos |

### Pantallas NO afectadas

- Garage / listado de vehículos
- Formulario de vehículo (formulario SOAT)
- Home badge SOAT (`home_garage_soat_badge.dart`)
- Flujo OCR / escáner de SOAT

---

## Flujos UX

### Flujo: tarjeta SOAT en detalle de vehículo (preservado sin cambio)

```
vehicle_detail_view
  └── VehicleDocumentCard(kind: .soat, vehicle: vehicle)   [antes: VehicleSoatCard]
        ├── ResultState.loading  →  Skeleton (CircularProgressIndicator 20×20, alto 36)
        ├── ResultState.data     →  Row con:
        │     • Icono de documento con color de estado (fondo alpha 30)
        │     • Label "SOAT" (11px, textOnDarkTertiary)
        │     • Status label localizado (13px w600, color de estado)
        │     • Fecha "Vence {fecha}" si expiryDate != null (11px, textOnDarkTertiary)
        │     • Flecha → (14px, textOnDarkTertiary)
        │   onTap → context.pushNamed(AppRoutes.soatStatus)
        ├── ResultState.empty    →  Row con estado "Sin registrar · Agregar →" (misma rama que soatStatus==null)
        └── ResultState.error    →  Idem empty (misma apariencia que sin SOAT)
```

### Flujo: página de estado SOAT (preservado sin cambio)

```
SoatStatusView
  ├── AppBar: título "Estado del SOAT", acción "Editar" si hay datos
  └── BlocBuilder<SoatCubit, ResultState<SoatModel>>
        ├── Initial/Loading  →  AppLoadingIndicator(variant: page)
        ├── Empty            →  SoatEmptyState (icon 80×80, título, subtítulo, AppButton "Registrar SOAT")
        ├── Data             →  SoatDataView
        │     ├── Hero card (color de estado, icono 48, título, chip de días)
        │     ├── Banner de advertencia (si expiringSoon/expired)
        │     ├── Card de detalles (SoatDetailRow × N filas)
        │     ├── AppButton "Renovar" (solo si expired)
        │     └── Action list (ver documento, eliminar)
        └── Error            →  Icon error + mensaje + AppButton "Reintentar"
```

---

## Componentes

### Nuevos widgets genéricos a crear (sin cambio visual, parametrizados)

#### `lib/features/vehicle_documents/presentation/widgets/detail_row.dart`
Extracción directa de `SoatDetailRow`. Mismos parámetros: `label`, `value`, `isLast`.
- Label: 13px, `textOnDarkSecondary`, flex 2
- Value: 13px w600, `textOnDarkPrimary`, flex 3, textAlign end
- Padding bottom: 12 (o 0 si `isLast`)

#### `lib/features/vehicle_documents/presentation/widgets/validity_card.dart`
Extracción directa de `SoatValidityCard`. Mismos parámetros: `DateTime? startDate`, `DateTime? expiryDate`.
Cuatro estados visuales preservados:
1. Sin fechas → Container gris (`darkTertiary`), icono `shield_outlined`, copy localizado
2. Fechas inválidas → Container rojo alpha 0.1, icono `error_outline`, copy localizado
3. Vencido → Container rojo alpha 0.1, icono `shield_outlined`, copy localizado
4. Vigente → Container verde alpha 0.1, icono `verified_user_outlined`, copy localizado

#### `lib/features/vehicle_documents/presentation/widgets/section_header.dart`
Widget nuevo de cabecera de sección para cards de documentos.
- Row: Icon (14px, `textOnDarkTertiary`) + SizedBox(6) + Text uppercase (11px w600, letterSpacing 0.5, `textOnDarkTertiary`)
- Padding: `fromLTRB(14, 12, 14, 10)`
- Trailing opcional para acción futura

#### `lib/features/vehicle_documents/presentation/widgets/empty_state.dart`
Generalización de `SoatEmptyState`.
Parámetros: `IconData icon`, `String title`, `String subtitle`, `String ctaLabel`, `VoidCallback onCta`.
- Container icono: 80×80, `darkCard` bg, border `darkBorderPrimary`, borderRadius 20, icono 40px `textOnDarkTertiary`
- Título: 18px w700, `textOnDarkPrimary`
- Subtítulo: 14px height 1.5, `textOnDarkSecondary`, textAlign center
- CTA: `AppButton` full width

#### `lib/features/vehicle_documents/presentation/widgets/status_view.dart`
Scaffold genérico para páginas de estado de documentos.
Parámetros: `String title`, `Widget? editAction`, `VehicleDocumentCubit<T> cubit`, builders para cada estado.
Preserva la estructura de `SoatStatusView`: `Scaffold` + `AppBar` + `BlocBuilder`.

#### `lib/features/vehicle_documents/presentation/widgets/data_view.dart`
Vista genérica de datos parametrizada.
Parámetros: `Color heroColor`, `IconData heroIcon`, `String heroTitle`, `String? daysChip`, `String? warningText`, `List<Widget> detailRows`, `List<Widget>? actions`.
Preserva la estructura de `SoatDataView` hero card + detalles.

### Widget reemplazado

#### `VehicleDocumentCard` (nuevo) reemplaza `VehicleSoatCard` (eliminado)
**Layout idéntico al actual `VehicleSoatCard`:**

```
Container (darkCard bg, borderRadius 12, border darkBorderPrimary)
├── SectionHeader: icon shield_outlined + "SOAT" label uppercase
├── Divider (height 1, darkBorderPrimary)
└── InkWell (onTap condicional)
      └── Padding(all: 14)
            ├── [loading] SizedBox(h:36) → CircularProgressIndicator(size:20, strokeWidth:2)
            └── [loaded] Row
                  ├── Container(36×36, borderRadius 8, color statusColor.withAlpha(30))
                  │     └── Icon(assignment_outlined, 18, statusColor)
                  ├── SizedBox(12)
                  ├── Expanded → Column
                  │     ├── Text("SOAT", 11px, textOnDarkTertiary)
                  │     ├── Text(statusLabel, 13px w600, statusColor)
                  │     └── [si expiryDate != null] Text("Vence {fecha}", 11px, textOnDarkTertiary)
                  └── Icon(arrow_forward_ios, 14, textOnDarkTertiary)
```

**Colores de estado (preservados):**
| Estado | Color |
|--------|-------|
| `valid` | `AppColors.statusGreen` |
| `expiringSoon` | `AppColors.statusWarning` |
| `expired` | `AppColors.statusError` |
| `noSoat` / null | `AppColors.textOnDarkSecondary` |

---

## Copy

### Claves existentes reusadas en `VehicleDocumentCard`

| Clave ARB | Valor | Uso en card |
|-----------|-------|-------------|
| `vehicle_doc_soat_label` | "SOAT" | Label pequeño 11px |
| `soat_status_valid` | "Vigente" | Status label verde |
| `soat_status_expiring_soon` | "Por vencer" | Status label naranja |
| `maintenance_expired_label` | "Vencido" | Status label rojo |
| `vehicle_soat_tap_to_add` | "Sin registrar · Agregar →" | Estado sin SOAT |
| `vehicle_soat_section_title` | "Documentos" | Header del card (uppercase en widget) |

### Clave nueva requerida

| Clave ARB | Valor | Placeholder | Uso |
|-----------|-------|-------------|-----|
| `vehicle_doc_expires_on` | `"Vence {date}"` | `{date}` (String) | Línea de fecha bajo el status label |

**Nota:** La clave se añade a `lib/l10n/app_es.arb`. El valor `{date}` es un String ya formateado por `DateFormat.yMMMd('es')` antes de pasarse al widget (el widget no formatea fechas — recibe el string).

### Copy para widgets genéricos `vehicle_documents/`

Los widgets genéricos `empty_state.dart`, `status_view.dart`, `data_view.dart` no tienen copy propio — reciben strings como parámetros. El copy concreto (español) vive en los wrappers SOAT que los instancian, usando las claves ARB existentes de `soat_*`.

---

## Accesibilidad

### Invariantes preservados (sin regresión)

1. **Contraste de texto:** todos los textos sobre fondo oscuro usan colores del sistema (`textOnDarkPrimary`, `textOnDarkSecondary`, `textOnDarkTertiary`) — sin cambio.
2. **Hit area de la tarjeta:** `InkWell` cubre toda el área de contenido del card (padding 14 all) — preservado en `VehicleDocumentCard`.
3. **Estado de carga:** `onTap: null` mientras carga para evitar interacciones duplicadas — preservado via `ResultState.loading`.
4. **Tamaño mínimo de tap:** el card completo es tappable (no solo el icono flecha) — preservado.
5. **Skeleton accesible:** el `CircularProgressIndicator` de 20×20 dentro del `SizedBox(h:36)` mantiene la altura mínima del card para evitar layout shift.

### Consideraciones para widgets genéricos

- `empty_state.dart`: el `AppButton` tiene texto localizado — el botón sigue siendo semánticamente un botón primario.
- `detail_row.dart`: ratio label/value flex 2:3 da prioridad visual al valor — correcto para datos de documentos.
- `section_header.dart`: texto uppercase con `letterSpacing 0.5` es solo decorativo (tamaño 11px) — el significado no depende de mayúsculas.

---

## Notas para Frontend

### Prioridad de implementación

Seguir el orden del architect: dominio → cubit base → ADR-E rename → conectar SoatModel → refactor SoatCubit → widgets genéricos → reapuntar widgets SOAT → VehicleDocumentCard → l10n → codegen.

### VehicleDocumentCard — detalles críticos de implementación

1. **`BlocProvider` local con `getIt`:** El card usa `BlocProvider(create: (ctx) => getIt<SoatCubit>()..load(vehicle.id ?? ''))` para crear una instancia scoped al card. No hereda `SoatCubit` del árbol global (no está en `MultiBlocProvider` de main). El `getIt<SoatCubit>()` en el `create` del `BlocProvider` es la única excepción permitida — no aparece en el `build` del widget.
2. **`ResultState` en lugar de `bool _isLoading`:** Los estados `Initial` y `Loading` renderizan el skeleton. Los estados `Empty` y `Error` renderizan el estado "sin SOAT" (misma apariencia que `soatStatus == null` en el card original). Solo `Data<SoatModel>` muestra el row de estado con fecha.
3. **Formato de fecha:** Usar `DateFormat.yMMMd('es').format(soat.expiryDate)` y pasar el string resultante a `context.l10n.vehicle_doc_expires_on(formattedDate)`.
4. **`onTap`:** Si `state is Data<SoatModel>` → `context.pushNamed(AppRoutes.soatStatus, extra: vehicle)`. Si `state is Empty` → `SoatEntryFlow.start(context, vehicle: vehicle)`. Recargar tras retorno del push usando un `.then((_) => cubit.load(...))` si el cubit es local.
5. **Reapuntar `vehicle_detail_view.dart`:** Reemplazar `VehicleSoatCard(vehicle: vehicle)` en línea 59 por `VehicleDocumentCard(kind: VehicleDocumentKind.soat, vehicle: vehicle)`.

### Widgets SOAT como thin wrappers

Los widgets `soat_detail_row.dart`, `soat_empty_state.dart`, `soat_validity_card.dart` se convierten en thin wrappers que delegan a los genéricos con los parámetros SOAT-específicos. Esto no cambia su API pública — los consumidores (`soat_data_view.dart`, `soat_status_view.dart`) no necesitan actualizarse por este cambio.

### SoatModel + VehicleDocumentExpiry — posible colisión de getters

`SoatModel` ya tiene `int get daysUntilExpiry` calculado. El mixin `VehicleDocumentExpiry` también declarará `int get daysUntilExpiry`. La solución: el mixin declara el getter como abstracto (sin implementación) — `SoatModel` ya lo satisface. El mixin solo provee la implementación de `VehicleDocumentStatus get documentStatus` que usa `daysUntilExpiry`. Verificar que no hay doble definición en `SoatModel`.

### L10N — clave nueva

Añadir en `app_es.arb` antes del grupo de claves `vehicle_doc_*`:
```json
"vehicle_doc_expires_on": "Vence {date}",
"@vehicle_doc_expires_on": {
  "description": "Fecha de vencimiento de un documento de vehículo en el card resumen",
  "placeholders": {
    "date": {
      "type": "String"
    }
  }
}
```
Ejecutar `flutter gen-l10n` tras el cambio.

### Sin Pencil para esta fase

Esta fase no crea pantallas nuevas. No se requiere actualizar el archivo `.pen` ni exportar mockups. El diseño de referencia son los widgets existentes (`vehicle_soat_card.dart`, `soat_data_view.dart`, `soat_status_view.dart`) — el frontend los preserva sin cambio visual.
