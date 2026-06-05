# Design handoff — doble-badge-documentos-detalle

**Fecha:** 2026-06-04T20:54:22Z
**Status:** done
**Nivel:** normal

---

## Pantallas

### Pantalla: Vehicle Detail View (EXTEND)

La pantalla de detalle del vehículo (`VehicleDetailView`) agrega una segunda tarjeta de documento
entre la tarjeta de SOAT y la sección de mantenimientos. No es pantalla nueva: es la misma vista
con un card adicional debajo del SOAT.

**Tipo:** EXTEND (se añade un widget a una vista existente, nada se rediseña)

**Posición en el scroll:**
```
VehicleDetailHeroImage
VehicleDetailNav (overlay)
VehicleDetailTopRow
[si hay placa/vin] VehicleDetailIdentificationCard  + SizedBox(16)
VehicleDetailSpecsCard                               + SizedBox(16)
VehicleDocumentCard(kind: soat,  vehicle: vehicle)  + SizedBox(16)   ← existente
VehicleDocumentCard(kind: rtm,   vehicle: vehicle)  + SizedBox(16)   ← NUEVO
VehicleMaintenanceHistorySection
```

El spacing entre los dos cards es idéntico al resto de la pantalla: `SizedBox(height: 16)`.

---

## Flujos UX

### Flujo 1 — Tap badge SOAT (sin cambio respecto a hoy)

- Si `ResultState.data` → navega a `/soat-status` (detalle del SOAT)
- Si `Initial | Loading | Empty | Error` → abre `SoatEntryFlow` (flujo de captura)
- Al volver, el cubit local del badge recarga con `load(vehicleId)`

### Flujo 2 — Tap badge RTM (nuevo)

- Si `ResultState.data` → navega a `/tecnomecanica-status` (detalle RTM)
- Si `Initial | Loading | Empty | Error` → navega también a `/tecnomecanica-status`
  (la página de estado RTM maneja el empty state y el flujo de creación internamente)
- Al volver, el cubit local del badge recarga con `load(vehicleId)`

### Estados del badge RTM (espejo del badge SOAT)

| Estado cubit         | Icono color | Status label                  | Sub-label              |
|----------------------|-------------|-------------------------------|------------------------|
| `Initial / Loading`  | skeleton    | shimmer animation             | —                      |
| `Empty`              | gris        | `Sin RTM registrada`          | —                      |
| `Error`              | gris        | `Sin RTM registrada`          | —                      |
| `Data` — valid       | verde       | `Vigente`                     | `Vence {fecha}`        |
| `Data` — expiringSoon| amarillo    | `Por vencer`                  | `Vence {fecha}`        |
| `Data` — expired     | rojo        | `vencido`                     | `Vence {fecha}`        |

Los colores vienen del design system: `AppColors.statusGreen`, `AppColors.statusWarning`,
`AppColors.statusError`, `AppColors.textOnDarkSecondary`.

### Carga independiente (Criterio 4)

Cada badge tiene su propio `BlocProvider` local dentro de `VehicleDocumentCard`. Cuando el cubit
del SOAT está en `Loading`, el badge SOAT muestra el skeleton; el badge RTM puede mostrar sus datos
simultáneamente si ya resolvió. No hay dependencia cruzada ni parpadeo compartido.

---

## Componentes

### Reutilizados (sin cambio)

| Componente | Uso en esta fase |
|------------|------------------|
| `VehicleDocumentCard` | Se instancia dos veces: `kind: soat` y `kind: rtm`. Shell existente; solo se completa `_RtmDocumentCardBody`. |
| `_SoatDocumentCardBody` | Sin modificaciones (readonly). Los 4 estados SOAT se preservan intactos. |
| `AppColors.darkCard`, `AppColors.darkBorderPrimary` | Colors del card shell, sin cambio. |
| `Icons.assignment_outlined` | Icono central de ambos badges. |
| `Icons.arrow_forward_ios` | Chevron derecho de ambos badges. |
| `Icons.shield_outlined` | Icono en la cabecera del card SOAT (header, ya existente). |

### Modificado

| Componente | Cambio |
|------------|--------|
| `_RtmDocumentCardBody` | Completar: envolver en `BlocBuilder<TecnomecanicaCubit, ResultState<TecnomecanicaModel>>`. Añadir header `DOCUMENTOS` + separador (igual que `_SoatDocumentCardBody`). Añadir 4 estados (skeleton, valid, expiringSoon, expired, empty). |

### Borrado

| Archivo | Razón |
|---------|-------|
| `vehicle_soat_section.dart` | Widget huérfano con imports concretos de `features/soat/`. Sin consumidores en `lib/`. |

### No se crea ningún componente nuevo

El layout del badge RTM es estructuralmente idéntico al del SOAT. El frontend reutiliza el mismo
patron de `Container + Column + header + Divider + BlocBuilder + InkWell + Row` que ya tiene
`_SoatDocumentCardBody`.

---

## Copy (Español)

### Claves ARB nuevas — badge RTM compacto

| Clave ARB | Texto | Contexto |
|-----------|-------|---------|
| `vehicle_doc_rtm_status_valid` | `Vigente` | Estado badge RTM cuando `documentStatus == valid` |
| `vehicle_doc_rtm_status_expiring_soon` | `Por vencer` | Estado badge RTM cuando `documentStatus == expiringSoon` |
| `vehicle_doc_rtm_status_expired` | `vencido` | Estado badge RTM cuando `documentStatus == expired` |

### Claves reutilizadas (sin cambio)

| Clave ARB existente | Texto | Uso en badge RTM |
|--------------------|-------|-----------------|
| `tecnomecanica_status_no_rtm` | `Sin RTM registrada` | Estado empty/error del badge RTM |
| `vehicle_doc_techreview_label` | `Técnico-mecánica` | Sub-label del tipo de documento en el badge RTM |
| `vehicle_doc_expires_on` | `Vence {date}` | Sub-label de fecha de vencimiento (ambos badges) |
| `tecnomecanica_page_status_title` | `Mi tecnomecánica` | Ya existía; usada en el stub, se reemplaza por el header apropiado |

### Header del card

El badge SOAT muestra en el header: `vehicle_soat_section_title` → `"Documentos"` (en mayúsculas
con `toUpperCase()`). El badge RTM usará la misma clave `vehicle_soat_section_title` para mantener
consistencia visual. Ambos cards muestran `"DOCUMENTOS"` en el header.

**Nota para Frontend:** el stub actual de `_RtmDocumentCardBody` usa
`context.l10n.tecnomecanica_page_status_title` como header label (sin `toUpperCase()`). Esto debe
corregirse para usar `vehicle_soat_section_title.toUpperCase()` igual que `_SoatDocumentCardBody`.

---

## Accesibilidad

### Semántica por badge

Cada badge (`_SoatDocumentCardBody`, `_RtmDocumentCardBody`) es un `InkWell` con `onTap`. No se
necesita `Semantics` wrapper adicional siempre que el árbol de texto sea legible por el lector de
pantalla: el `Column` con `doc-type-label` + `doc-status-label` + `doc-expiry-label` forma una
descripción completa (ej. "SOAT · Vigente · Vence 15 dic. 2026").

### Contraste

- Labels de estado (`valid`, `expiringSoon`, `expired`) sobre `AppColors.darkCard` (`#1C1C1E`):
  - `AppColors.statusGreen` (`#4ade80`) sobre `#1C1C1E` → ratio ≈ 9.3:1 (AA+)
  - `AppColors.statusWarning` (`#fbbf24`) sobre `#1C1C1E` → ratio ≈ 8.7:1 (AA+)
  - `AppColors.statusError` (`#ef4444`) sobre `#1C1C1E` → ratio ≈ 4.6:1 (AA)
- Estado `empty`: `AppColors.textOnDarkSecondary` sobre `#1C1C1E` → cumple AA

### Skeleton (loading)

El skeleton no necesita texto alternativo durante la carga; el `InkWell` no tiene `onTap` en el
estado loading/initial (el stub actual ya lo omite). Si se añade `onTap` durante loading, el
`Semantics` debe excluirlo (`excludeSemantics: true` o `onTap: null`).

### Tap targets

El badge completo es tappable (todo el área del `InkWell`). Mínimo de altura: ~64px (36px icono +
14px padding × 2) → cumple el mínimo táctil de 48px de Material.

---

## Notas para Frontend

### 1. Estructura de `_RtmDocumentCardBody` — espejo de `_SoatDocumentCardBody`

El cuerpo del badge RTM debe replicar la misma estructura de 3 capas:

```
Container (card shell: darkCard, border, borderRadius 12, clipHardEdge)
  Column
    Padding (header row: icon + "DOCUMENTOS".toUpperCase())
    Divider (height 1, darkBorderPrimary)
    BlocBuilder<TecnomecanicaCubit, ResultState<TecnomecanicaModel>>
      if (loading | initial) → skeleton (SizedBox height 36 + CircularProgressIndicator 20px)
      else → InkWell → Padding → Row [icon-box | text-col | chevron]
```

El `BlocProvider` ya está en `VehicleDocumentCard.build` (switch por kind). El `_RtmDocumentCardBody`
solo hace `context.read<TecnomecanicaCubit>()` para el tap y `BlocBuilder` para escuchar.

### 2. Color y label por `documentStatus`

`TecnomecanicaModel` implementa el mixin `VehicleDocumentExpiry`, por lo que expone
`documentStatus: VehicleDocumentStatus`. Mapearlo igual que el SOAT:

```dart
Color _statusColor(VehicleDocumentStatus? status) => switch (status) {
  VehicleDocumentStatus.valid        => AppColors.statusGreen,
  VehicleDocumentStatus.expiringSoon => AppColors.statusWarning,
  VehicleDocumentStatus.expired      => AppColors.statusError,
  _                                  => AppColors.textOnDarkSecondary,
};

String _statusLabel(BuildContext context, VehicleDocumentStatus? status) =>
  switch (status) {
    VehicleDocumentStatus.valid        => context.l10n.vehicle_doc_rtm_status_valid,
    VehicleDocumentStatus.expiringSoon => context.l10n.vehicle_doc_rtm_status_expiring_soon,
    VehicleDocumentStatus.expired      => context.l10n.vehicle_doc_rtm_status_expired,
    _                                  => context.l10n.tecnomecanica_status_no_rtm,
  };
```

### 3. Tap RTM — siempre navega a `/tecnomecanica-status`

A diferencia del SOAT (que bifurca entre detalle y flujo de captura según si hay datos), el tap RTM
siempre va a `AppRoutes.tecnomecanicaStatus` (con `extra: vehicle`). La página de estado RTM maneja
internamente el empty state. Al retornar, el cubit recarga con `context.read<TecnomecanicaCubit>().load(vehicle.id ?? '')`.

### 4. Gate A11 — verificar antes de cerrar

Ejecutar el grep acotado del Criterio 1 del PRD:
```bash
grep -n "features/soat\|features/tecnomecanica" \
  lib/features/vehicles/presentation/detail/vehicle_detail_page.dart \
  lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart
```
Debe devolver **cero líneas**.

### 5. No crear VehicleDocumentCardHeader como widget separado

El header (`icon + label`) tiene ~3 líneas de código. No justifica extracción a un archivo propio;
va inline en el `Column` de cada `_XDocumentCardBody`. Extraerlo violaría el principio de no
sobre-fragmentar widgets simples.

### 6. Mockup HTML de referencia

`docs/exec-runs/doble-badge-documentos-detalle/analysis/design/vehicle_detail_document_badges.html`

Contiene 4 estados representados en 4 "phones":
- Phone 1: Ambos vigentes
- Phone 2: SOAT por vencer + RTM vencida
- Phone 3: Ambos sin registrar (empty)
- Phone 4: SOAT cargando (skeleton) + RTM ya resuelta (carga independiente)
