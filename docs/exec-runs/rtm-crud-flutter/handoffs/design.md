# Design handoff — rtm-crud-flutter

**Date:** 2026-06-04T19:02:51Z
**Status:** done (v2 — auditor corrections applied)

---

## Design system baseline

- Primary: `#f98c1f` | Dark bg primary: `#0D0D0F` | Dark card: `#1a1a1a` | Border: `#2a2a2a`
- Font: Space Grotesk | Border radius: 8px (standard), 12px (cards), 16px (hero card), 20px (pill chips)
- Success: `#34c759` | Warning: `#ff9f0a` | Error: `#ff453a`
- Changed this iteration: none — RTM screens are a direct mirror of SOAT visual language, no new tokens

---

## Pantallas

| Pantalla | Tipo | Artefacto | Descripción |
|----------|------|-----------|-------------|
| `TecnomecanicaStatusPage` | NEW | `tecnomecanica_status_page.html` | Scaffold con AppBar + BlocBuilder; delega a `TecnomecanicaStatusView` |
| `TecnomecanicaStatusView` — Vigente | NEW | HTML State 1 · .pen `RTM — Estado (Vigente)` | Hero card verde + detalles + acción Eliminar |
| `TecnomecanicaStatusView` — Por vencer | NEW | HTML State 2 · .pen `RTM — Estado (Por vencer)` | Hero card naranja + banner advertencia (sin promesa de notificación) + detalles + Eliminar |
| `TecnomecanicaStatusView` — Vencida | NEW | HTML State 3 · .pen `RTM — Estado (Vencida)` | Hero card rojo + banner + detalles + CTA "Registrar nueva RTM" + Eliminar |
| `TecnomecanicaEmptyState` — sin RTM | NEW | HTML State 4 · .pen `RTM — Estado (Empty)` | Icono + título + subtítulo + `TecnomecanicaExemptionNotice` (si aplica) + CTA |
| `TecnomecanicaStatusView` — Loading | NEW | HTML State 5 · .pen `RTM — Estado (Loading)` | `AppLoadingIndicator` centrado |
| `TecnomecanicaManualCapturePage` — creación | NEW | HTML Modo creación · .pen `RTM — Captura Manual` | Formulario vacío con 6 campos; `TecnomecanicaExemptionNotice` si vehículo <2 años; sin addDocRow ni statusBanner |
| `TecnomecanicaManualCapturePage` — edición | NEW | .pen `RTM — Captura Manual (Edicion)` | Campos precargados con datos existentes; título "Editar RTM" |
| `TecnomecanicaManualCapturePage` — error validación | NEW | .pen `RTM — Captura Manual (Error validacion)` | Campos con borde rojo + mensaje inline + error box de API |
| `TecnomecanicaManualCapturePage` — guardando | NEW | .pen `RTM — Captura Manual (Guardando)` | Campos deshabilitados (opacity 0.4) + botón con spinner "Guardando..." |

---

## Flujos UX

### Flujo 1: Ver estado RTM (vehículo con RTM activa)
1. Usuario navega al detalle del vehículo → toca el tile de tecnomecánica
2. `TecnomecanicaEntryFlow.start(context, vehicle)` → `context.pushNamed(AppRoutes.tecnomecanicaStatus, extra: vehicle)`
3. `TecnomecanicaStatusPage` monta un `BlocProvider` con `getIt<TecnomecanicaCubit>()` y llama `cubit.load(vehicle.id)`
4. Estado Loading → spinner; estado Data → `TecnomecanicaStatusView` con hero card de color según `VehicleDocumentStatus`

### Flujo 2: Registrar RTM nueva (estado Empty)
1. StatusPage → estado Empty → `TecnomecanicaEmptyState` → botón "Registrar RTM"
2. Toca CTA → `TecnomecanicaEntryFlow.start(context, vehicle)` (que en Empty navega a ManualCapturePage sin RTM existente)
3. `TecnomecanicaManualCapturePage` (modo creación): usuario completa los campos requeridos
4. Toca "Guardar datos" → `SaveTecnomecanicaUseCase` → POST → cubit emite `ResultState.data` → `context.pop(true)` → StatusPage recarga

### Flujo 3: Editar RTM existente
1. StatusPage (estado Data) → botón "Editar" en AppBar
2. Navega a `TecnomecanicaManualCapturePage` con `TecnomecanicaManualCaptureParams(vehicle, existingRtm)`
3. Campos precargados; usuario modifica y guarda → POST (upsert) → `context.pop(true)` → StatusPage recarga desde cubit

### Flujo 4: Eliminar RTM
1. StatusPage (estado Data) → `TecnomecanicaDataView` → tile "Eliminar RTM" (rojo)
2. `ConfirmationDialog.show(...)` → usuario confirma
3. `DeleteTecnomecanicaUseCase` → DELETE → cubit emite `ResultState.empty()` → SnackBar "RTM eliminada" → `context.pop()`

### Flujo 5: Error de red / API
1. Cualquier llamada fallida → cubit emite `ResultState.error(DomainException)`
2. StatusPage: muestra `StatusViewErrorBody` con mensaje + botón "Reintentar"
3. ManualCapturePage: muestra inline error box (no navega fuera); botón "Guardar" re-habilitado

---

## Componentes

### Reutilizados (no crear de nuevo)

| Componente | Archivo fuente | Uso en RTM |
|------------|---------------|------------|
| `DocumentStatusView<C, T>` | `vehicle_documents/presentation/widgets/status_view.dart` | Scaffold de `TecnomecanicaStatusView` — pasar `TecnomecanicaCubit` como `C` |
| `DocumentDataView<T>` | `vehicle_documents/presentation/widgets/data_view.dart` | Render del hero + details + actions en `TecnomecanicaDataView` |
| `DocumentEmptyState` | `vehicle_documents/presentation/widgets/empty_state.dart` | Base de `TecnomecanicaEmptyState` |
| `DocumentDetailRow` | `vehicle_documents/presentation/widgets/detail_row.dart` | Filas de detalles en `TecnomecanicaDataView` |
| `AppLoadingIndicator` | design_system | Loading state en StatusPage |
| `AppButton` | shared/widgets/form/ | CTA "Registrar RTM", "Guardar datos", "Registrar nueva RTM" |
| `AppTextButton` | shared/widgets/form/ | Botón "Editar" en AppBar de StatusPage |
| `AppTextField` | shared/widgets/form/ | Campos `certificateNumber`, `cdaName`, `cdaCode`, `documentUrl` |
| `AppDatePicker` | shared/widgets/form/ | Campos `startDate`, `expiryDate` (fila lado a lado) |
| `ConfirmationDialog` | shared/widgets/modals/ | Diálogo de confirmación de borrado |
| `FormBuilder` / `flutter_form_builder` | deps | Wrapper del formulario de captura |
| `StatusViewErrorBody` | `vehicle_documents/presentation/widgets/` | Error state en StatusView |

### Nuevos (crear en `tecnomecanica/presentation/widgets/`)

| Componente | Descripción | Inputs clave |
|------------|-------------|-------------|
| `TecnomecanicaStatusView` | Thin wrapper sobre `DocumentStatusView<TecnomecanicaCubit, TecnomecanicaModel>` que inyecta `buildEmpty`, `buildData`, `buildDataActions` con la lógica específica de RTM | `vehicle: VehicleModel` |
| `TecnomecanicaDataView` | Thin wrapper sobre `DocumentDataView<TecnomecanicaModel>` con `heroColor`, `heroTitle`, `heroDaysChip`, `heroWarning` calculados desde `rtm.documentStatus` (mixin `VehicleDocumentExpiry`); `detailRows` para los 5 campos; `actions` con el tile de eliminar | `vehicle`, `rtm: TecnomecanicaModel` |
| `TecnomecanicaEmptyState` | Thin wrapper sobre `DocumentEmptyState` con icono `Icons.assignment_outlined`, copy específico, y CTA que llama `TecnomecanicaEntryFlow.start(context, vehicle)` | `vehicle: VehicleModel` |
| `TecnomecanicaExemptionNotice` | Info chip no bloqueante. Color: **primary/naranja** (`$accent` / `#F98C1F1A` fill, `$accent` stroke, texto `$accent`). Nunca azul `$info`. Solo se muestra, nunca bloquea el guardado. Lógica: `purchaseDate != null ? DateTime.now().difference(purchaseDate!).inDays < 730 : (DateTime.now().year - year) < 2` | `vehicle: VehicleModel` |

### Jerarquía de widgets en ManualCapturePage

Seis campos en orden (sin `addDocRow` de image/PDF — AC #10 no-OCR; sin `statusBanner` verde — no es parte del flujo de captura):

```
TecnomecanicaManualCapturePage (StatefulWidget)
└── Scaffold
    ├── AppBar (título dinámico: "Registrar RTM" / "Editar RTM")
    └── body: FormBuilder
        └── SingleChildScrollView
            ├── Text (subtítulo: "Ingresa los datos de la revisión técnico-mecánica de {vehicleName}.")
            ├── TecnomecanicaExemptionNotice (condicional — color primary/naranja, nunca azul)
            ├── AppTextField (certificateNumber, requerido *)
            ├── AppTextField (cdaName, requerido *)
            ├── AppTextField (cdaCode, opcional)
            ├── Row
            │   ├── AppDatePicker (startDate, opcional)
            │   └── AppDatePicker (expiryDate, requerido *)
            ├── AppTextField (documentUrl, opcional, keyboardType: url)
            ├── [ErrorBox condicional — si _error != null]
            └── AppButton ("Guardar datos" / spinner)
```

---

## Copy

### Pantalla StatusPage / StatusView

| Clave l10n propuesta | Texto ES | Contexto |
|---------------------|----------|---------|
| `tecnomecanica_page_status_title` | `Mi tecnomecánica` | AppBar título |
| `tecnomecanica_edit_btn` | `Editar` | AppBar action (Data state) |
| `tecnomecanica_valid_title` | `Tu RTM está al día` | Hero card — estado vigente |
| `tecnomecanica_expiring_title` | `Tu RTM vence pronto` | Hero card — por vencer |
| `tecnomecanica_expired_title` | `Tu RTM está vencida` | Hero card — vencida |
| `tecnomecanica_valid_days_remaining` | `{count} días restantes` | Chip en hero (vigente/por vencer) — param: `count` |
| `tecnomecanica_expired_days_ago` | `Venció hace {count} días` | Chip en hero (vencida) — param: `count` |
| `tecnomecanica_expiring_warning` | `Programa tu revisión técnico-mecánica con anticipación para evitar sanciones.` | Banner advertencia — por vencer |
| `tecnomecanica_expired_warning` | `Circular sin revisión técnico-mecánica vigente es una infracción. Lleva tu moto a revisión lo antes posible.` | Banner advertencia — vencida (copy legal propio, distinto del SOAT) |
| `tecnomecanica_renew_btn` | `Registrar nueva RTM` | CTA en estado vencida |
| `tecnomecanica_field_certificate_number` | `N.° de certificado` | Etiqueta fila detalles |
| `tecnomecanica_field_cda_name` | `CDA` | Etiqueta fila detalles |
| `tecnomecanica_field_cda_code` | `Código CDA` | Etiqueta fila detalles |
| `tecnomecanica_field_start_date` | `Fecha inicio` | Etiqueta fila detalles |
| `tecnomecanica_field_expiry_date` | `Fecha vencimiento` | Etiqueta fila detalles |
| `tecnomecanica_delete_button` | `Eliminar RTM` | Tile acción / ConfirmationDialog |
| `tecnomecanica_delete_confirm_title` | `¿Eliminar RTM?` | ConfirmationDialog título |
| `tecnomecanica_delete_confirm_message` | `Se eliminará la información de la revisión técnico-mecánica de este vehículo. Esta acción no se puede deshacer.` | ConfirmationDialog cuerpo |
| `tecnomecanica_deleted_success` | `RTM eliminada` | SnackBar tras borrado exitoso |

### Pantalla EmptyState

| Clave l10n propuesta | Texto ES | Contexto |
|---------------------|----------|---------|
| `tecnomecanica_status_no_rtm` | `Sin RTM registrada` | Título estado vacío |
| `tecnomecanica_manual_note` | `Registra los datos de tu revisión técnico-mecánica para hacer seguimiento de su vencimiento.` | Subtítulo estado vacío |

### Pantalla ManualCapturePage

| Clave l10n propuesta | Texto ES | Contexto |
|---------------------|----------|---------|
| `tecnomecanica_form_create_title` | `Registrar RTM` | AppBar — modo creación |
| `tecnomecanica_edit_title` | `Editar RTM` | AppBar — modo edición |
| `tecnomecanica_manual_subtitle` | `Ingresa los datos de la revisión técnico-mecánica de {vehicleName}.` | Subtítulo — param: `vehicleName` |
| `tecnomecanica_cert_number_label` | `Número de certificado` | Label campo |
| `tecnomecanica_cert_number_hint` | `Ej: RTM-2025-01234` | Hint campo |
| `tecnomecanica_cda_name_label` | `Centro de diagnóstico (CDA)` | Label campo |
| `tecnomecanica_cda_name_hint` | `Ej: CDA Motos Bogotá` | Hint campo |
| `tecnomecanica_cda_code_label` | `Código del CDA` | Label campo |
| `tecnomecanica_cda_code_hint` | `Ej: CDA-0021` | Hint campo |
| `tecnomecanica_start_date_label` | `Fecha de inicio` | Label campo |
| `tecnomecanica_start_date_hint` | `dd/mm/aaaa` | Hint campo |
| `tecnomecanica_expiry_date_label` | `Fecha de vencimiento` | Label campo |
| `tecnomecanica_expiry_date_hint` | `dd/mm/aaaa` | Hint campo |
| `tecnomecanica_document_url_label` | `URL del documento` | Label campo |
| `tecnomecanica_document_url_hint` | `https://...` | Hint campo |
| `tecnomecanica_save_data_btn` | `Guardar datos` | Botón guardar (ambos modos) |
| `tecnomecanica_saving` | `Guardando...` | Botón durante _saving |

### ExemptionNotice

| Clave l10n propuesta | Texto ES | Contexto |
|---------------------|----------|---------|
| `tecnomecanica_exemption_notice` | `Tu vehículo tiene menos de 2 años, por lo que está exento de la RTM. Aun así, puedes registrarla.` | Chip info |

---

## Accesibilidad

- **Targets mínimos 44×44 pt:** AppBar back button (44×44), AppTextButton "Editar" (min 44×44 con padding), action tiles (min 56px height), AppButton (52px height).
- **Contraste:** Hero titles y chips usan el mismo color semántico del estado (verde/naranja/rojo) sobre fondos 8% opacity — cumple WCAG AA para texto grande (>18px). Textos secundarios en `#888` sobre `#0d0d0f` — contraste 4.5:1.
- **Texto sobre primario:** El botón principal (`AppButton`) tiene `color: #0d0d0f` (darkBgPrimary) como label sobre el relleno naranja. Nunca blanco.
- **Semantics:** Los campos `AppTextField` y `AppDatePicker` tienen `labelText` visible — Flutter form_builder lo mapea a `Semantics(label:)` automáticamente.
- **Error feedback:** Los errores inline de validación aparecen justo debajo del campo afectado (no solo en la parte inferior), facilitando la lectura por VoiceOver/TalkBack.
- **ExemptionNotice:** `Semantics(liveRegion: false)` — es informativo, no crítico; no interrumpe el flujo.
- **ConfirmationDialog:** botón destructivo ("Eliminar RTM") en `DialogActionType.danger` — usa color `#ff453a`. El foco inicial debe estar en "Cancelar" (acción por defecto) para evitar borrados accidentales.

---

## Notas para Frontend

### Estructura de archivos

Seguir estrictamente el patrón del SOAT. Cada clase widget en su propio archivo. La `TecnomecanicaManualCapturePage` es el único `StatefulWidget` complejo; su `State` coexiste en el mismo archivo.

### Widgets genéricos de `vehicle_documents/`

Usar directamente los genéricos. No re-implementar lógica de scaffold ni layout:
- `DocumentStatusView<TecnomecanicaCubit, TecnomecanicaModel>` ya maneja el AppBar, back button, BlocBuilder, y todos los estados — `TecnomecanicaStatusView` solo lo envuelve pasando los builders.
- `DocumentDataView<TecnomecanicaModel>` ya maneja el scroll, hero card, warning banner, details card, footer y actions — `TecnomecanicaDataView` solo calcula los valores semánticos (`heroColor`, `heroTitle`, etc.) a partir de `rtm.documentStatus`.
- `DocumentEmptyState` ya tiene el layout centrado — `TecnomecanicaEmptyState` solo pasa `icon`, `title`, `subtitle`, `ctaLabel`, `onCta`.

### TecnomecanicaExemptionNotice

Widget independiente (`StatelessWidget`). Recibe `VehicleModel` y calcula la exención internamente. **No bloquea** el guardado — es solo visual. Aparece:
1. En `TecnomecanicaEmptyState` (entre subtítulo y CTA)
2. En `TecnomecanicaManualCapturePage` (entre subtítulo y primer campo)

Lógica de exención (solo en widget, no en dominio):
```dart
bool get _isExempt {
  final purchase = vehicle.purchaseDate;
  if (purchase != null) {
    return DateTime.now().difference(purchase).inDays < 730;
  }
  final year = vehicle.year;
  if (year != null) {
    return DateTime.now().year - year < 2;
  }
  return false;
}
```

### Hero card y colores de estado

Usar `rtm.documentStatus` del mixin `VehicleDocumentExpiry` (que ya computa `valid`, `expiringSoon`, `expired`, `none`). Mapear al color semántico:
- `valid` → `AppColors.success` (`#34c759`)
- `expiringSoon` → `AppColors.warning` (`#ff9f0a`)
- `expired` → `AppColors.error` (`#ff453a`)
- `none` → `AppColors.textOnDarkSecondary`

Umbral `expiringSoon`: 30 días (definido en `VehicleDocumentExpiry`; no redefinir en RTM).

### ManualCapturePage — campos

Cinco grupos de campos en orden:
1. `certificateNumber` — `AppTextField`, `isRequired: true`, `textInputAction: TextInputAction.next`
2. `cdaName` — `AppTextField`, `isRequired: true`, `textInputAction: TextInputAction.next`
3. `cdaCode` — `AppTextField`, opcional, `textInputAction: TextInputAction.next`
4. `startDate` + `expiryDate` — `Row` con dos `AppDatePicker` (flex: 1 cada uno, gap 12px); `expiryDate` es requerido, `startDate` opcional
5. `documentUrl` — `AppTextField`, opcional, `textInputAction: TextInputAction.done`, `keyboardType: TextInputType.url`

### Modo creación vs. edición

Determinar con `widget.existingRtm != null`:
- `null` → título `tecnomecanica_form_create_title`, botón `tecnomecanica_save_data_btn`
- `!= null` → título `tecnomecanica_edit_title`, botón `tecnomecanica_save_data_btn` (mismo copy; upsert en backend)

### Payload de escritura

`CreateTecnomecanicaRequestDto.toJson()` — nunca construir `Map<String, dynamic>` a mano. El DTO incluye `expiryDate` como ISO8601 string (`toIso8601String()`).

### Analytics

Emitir eventos en los momentos clave:
- `TecnomecanicaStatusPage.initState` → `tecnomecanica_status_viewed`
- `SaveTecnomecanicaUseCase` éxito (creación) → `tecnomecanica_manual_saved`
- `SaveTecnomecanicaUseCase` éxito (edición) → `tecnomecanica_updated`
- `DeleteTecnomecanicaUseCase` éxito → `tecnomecanica_deleted`

Todas ≤40 caracteres en snake_case.

---

## Artefactos de diseño

- Mockups HTML: `docs/exec-runs/rtm-crud-flutter/analysis/design/`
  - `tecnomecanica_status_page.html` — 5 estados: Vigente, Por vencer, Vencida, Empty, Loading
  - `tecnomecanica_manual_capture_page.html` — 4 estados: Creación, Edición, Error validación, Guardando

- Frames en `rideglory.pen` (fuente de verdad del implementador):
  - `RTM — Estado (Vigente)` — hero card verde, detalles, eliminar
  - `RTM — Estado (Por vencer)` — hero naranja, banner sin promesa de notificación
  - `RTM — Estado (Vencida)` — hero rojo, banner legal, CTA Registrar nueva RTM
  - `RTM — Estado (Empty)` — empty state con exemptionNotice naranja + CTA
  - `RTM — Estado (Loading)` — spinner centrado
  - `RTM — Captura Manual` — 6 campos (certificateNumber*, cdaName*, cdaCode, startDate, expiryDate*, documentUrl); exemptionNotice naranja; sin addDocRow, sin statusBanner
  - `RTM — Captura Manual (Edicion)` — campos precargados con datos de muestra
  - `RTM — Captura Manual (Error validacion)` — bordes rojo en campos requeridos vacíos + errorBox API
  - `RTM — Captura Manual (Guardando)` — campos opacity 0.4 + botón spinner "Guardando..."

### Decisiones de diseño (correcciones v2)

| Elemento | Decisión | Razón |
|----------|----------|-------|
| `exemptionNotice` | Color `$accent` (naranja) en fill, stroke y texto | Alineado con handoff y HTML; `$info` (azul) era inconsistente |
| `addDocRow` | Eliminado del formulario | AC #10: sin OCR/image_picker/pdfx; `documentUrl` captura la referencia como texto URL |
| `statusBanner` verde | Eliminado del formulario | No está en la jerarquía del handoff; información redundante durante captura |
| Subtítulo formulario | `"Ingresa los datos de la revisión técnico-mecánica de {vehicleName}."` | Versión anterior sugería adjuntar documento, contradiciendo AC #10 |
| Banner "Por vencer" | `"Programa tu revisión técnico-mecánica con anticipación para evitar sanciones."` | Eliminada promesa de notificación ("Te notificaremos 7 días...") — Fase 5 |
