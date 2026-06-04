# Frontend → QA — tecnomecanica-rtm-ph1

**Fecha:** 2026-06-04T16:33:23Z
**Agente:** Flutter Developer (Frontend)
**Última corrección:** 2026-06-04T16:33:23Z (Modo corrección — Auditor Opus)

---

## Baseline

- `flutter test` → EXIT 0 antes de cualquier cambio (todos los tests del repo pasaban)
- `dart analyze` → 0 issues en baseline

---

## Archivos cambiados

### Creados — Dominio genérico (`lib/features/vehicle_documents/domain/`)
| Archivo | Descripción |
|---------|-------------|
| `vehicle_document_kind.dart` | `enum VehicleDocumentKind { soat }` — extensible para RTM en Fase 4 |
| `vehicle_document_status.dart` | `enum VehicleDocumentStatus { valid, expiringSoon, expired, none }` |
| `vehicle_document_expiry.dart` | `mixin VehicleDocumentExpiry` — `daysUntilExpiry` + `documentStatus` sin imports Flutter |
| `vehicle_document_model.dart` | `abstract class VehicleDocumentModel with VehicleDocumentExpiry` — contrato base |

### Creados — Cubit base (`lib/features/vehicle_documents/presentation/cubit/`)
| Archivo | Descripción |
|---------|-------------|
| `vehicle_document_cubit.dart` | `abstract class VehicleDocumentCubit<T extends VehicleDocumentModel>` — extiende `Cubit<ResultState<T>>` |

### Creados — Widgets genéricos (`lib/features/vehicle_documents/presentation/widgets/`)
| Archivo | Descripción |
|---------|-------------|
| `detail_row.dart` | `DocumentDetailRow` — fila label/value genérica (1 widget) |
| `section_header.dart` | `DocumentSectionHeader` — cabecera con icon + title + trailing (1 widget) |
| `empty_state.dart` | `DocumentEmptyState` — estado vacío parametrizado con AppButton CTA (1 widget) |
| `validity_card.dart` | `DocumentValidityCard` — solo el orquestador; delega a los 4 sub-widgets (1 widget) |
| `validity_card_pending.dart` | `ValidityCardPending` — estado sin fechas (1 widget) |
| `validity_card_invalid_dates.dart` | `ValidityCardInvalidDates` — fechas incoherentes (1 widget) |
| `validity_card_expired.dart` | `ValidityCardExpired` — documento vencido (1 widget) |
| `validity_card_valid.dart` | `ValidityCardValid` — documento vigente (1 widget) |
| `status_view.dart` | `DocumentStatusView<C, T>` — scaffold genérico, solo 1 widget público (1 widget) |
| `status_view_error_body.dart` | `StatusViewErrorBody` — cuerpo de error extraído de status_view (1 widget) |
| `data_view.dart` | `DocumentDataView<T>` — orquestador, delega a sub-widgets (1 widget) |
| `data_view_hero_card.dart` | `DataViewHeroCard` — tarjeta hero de estado (1 widget) |
| `data_view_warning_banner.dart` | `DataViewWarningBanner` — banner de advertencia (1 widget) |
| `data_view_details_card.dart` | `DataViewDetailsCard` — tarjeta de detalles con rows (1 widget) |

### Creados — Vehicles domain
| Archivo | Descripción |
|---------|-------------|
| `lib/features/vehicles/domain/models/vehicle_soat_form_data.dart` | `VehicleSoatFormData` — reemplaza el antiguo `SoatModel` de vehicles; pure form data |

### Borrados
| Archivo | Motivo |
|---------|--------|
| `lib/features/vehicles/domain/models/soat_model.dart` | Reemplazado por `VehicleSoatFormData` (ADR-E) |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_soat_card.dart` | Reemplazado por `VehicleDocumentCard` (ADR-F) |

### Modificados
| Archivo | Cambio |
|---------|--------|
| `lib/features/vehicles/data/dto/soat_dto.dart` | Renombrado `SoatDto` → `VehicleSoatFormDataDto`; eliminado `toModel()`; extensión `toFormData()` y `toJson()` sobre `VehicleSoatFormData`; comentario corregido: documenta excepción de shape-mismatch (fechas String↔DateTime) |
| `lib/features/vehicles/data/dto/soat_dto.g.dart` | Actualizado manualmente para el nuevo nombre de clase |
| `lib/features/vehicles/data/service/vehicle_service.dart` | Retrofit signatures usan `VehicleSoatFormDataDto` |
| `lib/features/vehicles/data/repository/vehicle_repository_impl.dart` | Usa `VehicleSoatFormData`; llama `dto.toFormData()` y `soat.toJson()` (elimina `dto.toModel()`) |
| `lib/features/vehicles/domain/repository/vehicle_repository.dart` | Firmas `upsertSoat`/`getSoat` → `VehicleSoatFormData` |
| `lib/features/vehicles/presentation/form/widgets/vehicle_form_view.dart` | Import y constructor `SoatModel` → `VehicleSoatFormData` |
| `lib/features/soat/domain/models/soat_model.dart` | Añadido `with VehicleDocumentExpiry implements VehicleDocumentModel`; `documentStatus` y `@override daysUntilExpiry` |
| `lib/features/soat/presentation/cubit/soat_cubit.dart` | `extends VehicleDocumentCubit<SoatModel>`; `@override` en `load()` |
| `lib/features/soat/presentation/widgets/soat_detail_row.dart` | Thin wrapper sobre `DocumentDetailRow` |
| `lib/features/soat/presentation/widgets/soat_validity_card.dart` | Thin wrapper sobre `DocumentValidityCard` |
| `lib/features/soat/presentation/widgets/soat_empty_state.dart` | Usa `DocumentEmptyState` con parámetros SOAT |
| `lib/features/soat/presentation/widgets/soat_data_view.dart` | `SoatDetailRow` → `DocumentDetailRow` (import actualizado) |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart` | `VehicleSoatCard` → `VehicleDocumentCard(kind: .soat, vehicle: vehicle)` |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart` | Caso `expired` usa `maintenance_expired_label` ('vencido') en lugar de `soat_status_expired` ('Vencido') — AC#12 cero cambio visible |
| `lib/l10n/app_es.arb` | Añadida key `vehicle_doc_expires_on` con placeholder `{date}` |
| `lib/l10n/app_localizations.dart` | Regenerado por `flutter gen-l10n` |
| `lib/l10n/app_localizations_es.dart` | Regenerado por `flutter gen-l10n` |

### Nuevo card principal (ADR-F)
| Archivo | Descripción |
|---------|-------------|
| `lib/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart` | `VehicleDocumentCard` con `BlocProvider` local + `SoatCubit`; `ResultState` completo; cero `bool _isLoading`; `getIt` solo en `BlocProvider.create`; `_SoatDocumentCardBody` es la única clase privada interna (co-existe con el `StatelessWidget` público en el mismo archivo como clase auxiliar privada de un solo widget compuesto) |

---

## Correcciones del Auditor Opus aplicadas

1. **`_statusLabel` para `SoatStatus.expired`** — cambiado de `soat_status_expired` ('Vencido') a `maintenance_expired_label` ('vencido') para cumplir AC#12 (cero cambio visible respecto al estado previo).
2. **`validity_card.dart`** — las 4 clases privadas (`_PendingCard`, `_InvalidDatesCard`, `_ExpiredCard`, `_ValidCard`) extraídas a archivos propios: `validity_card_pending.dart`, `validity_card_invalid_dates.dart`, `validity_card_expired.dart`, `validity_card_valid.dart`. El archivo `validity_card.dart` ahora solo contiene `DocumentValidityCard`.
3. **`data_view.dart`** — las 3 clases privadas (`_HeroCard`, `_WarningBanner`, `_DetailsCard`) extraídas a `data_view_hero_card.dart`, `data_view_warning_banner.dart`, `data_view_details_card.dart`. `status_view.dart` idem: `_ErrorBody` → `status_view_error_body.dart`.
4. **`soat_dto.dart` — comentario corregido** — eliminada la mención falsa de "Pattern B"; reemplazado por documentación de la excepción de shape-mismatch (fechas String↔DateTime).

---

## Pruebas nuevas

| Archivo | Tests | Descripción |
|---------|-------|-------------|
| `test/features/vehicle_documents/domain/vehicle_document_expiry_test.dart` | 9 | `VehicleDocumentExpiry` mixin: daysUntilExpiry, documentStatus, strip de tiempo |
| `test/features/soat/domain/models/soat_model_implements_contract_test.dart` | 6 | `SoatModel` implementa `VehicleDocumentModel`; acceso vía contrato; consistencia entre `SoatStatus` y `VehicleDocumentStatus` |

Total nuevos: **15 tests** (más los 8 preexistentes del `soat_model_test.dart`).

---

## Resultado final

```
dart analyze  →  No issues found!
flutter test  →  EXIT 0 — 720 passed, 0 failed
```

---

## Verificación manual

1. **`grep -n "class SoatModel" lib/` → 1 resultado** (en `soat/domain/models/soat_model.dart`)
2. **`grep -n "getIt" vehicle_document_card.dart`** → solo en línea del `BlocProvider.create` (factory), no en el cuerpo del widget
3. **`grep -n "'Vigente'\|'Por vencer'\|'Vence '" vehicle_document_card.dart`** → 0 resultados (usa `context.l10n`)
4. **`SoatDto extends SoatModel`** en `lib/features/soat/data/dto/soat_dto.dart` → intacto
5. **`dart analyze` → 0 issues**
6. **Un widget por archivo** — todos los archivos de `vehicle_documents/presentation/widgets/` tienen exactamente 1 clase pública que extiende `StatelessWidget`/`StatefulWidget`

---

## Notas para QA

- `VehicleSoatFormData` NO implementa `VehicleDocumentModel`. Es un form data object puro para el flujo de creación/edición de vehículo. El modelo de dominio completo es `SoatModel` en `soat/`.
- El `vehicle_service.g.dart` fue regenerado por `build_runner` — los refs a `SoatDto` desaparecieron.
- `soat_status_view.dart` no requirió cambios: `SoatCubit` ahora extiende `VehicleDocumentCubit<SoatModel>` que sigue siendo `Cubit<ResultState<SoatModel>>`, por lo que el `BlocBuilder<SoatCubit, ResultState<SoatModel>>` ya existente es completamente compatible.
- Los wrappers SOAT (`SoatDetailRow`, `SoatValidityCard`) se mantienen por compatibilidad con los formularios SOAT existentes; no es necesario migrarlos en esta fase.
- La key `vehicle_doc_expires_on` usa placeholder `{date}` de tipo `String`; la llamada en el card formatea la fecha con `DateFormat.yMMMd('es')` antes de pasarla.
- El texto "vencido" (minúsculas) en el badge del garage viene de `maintenance_expired_label`; coincide con el valor pre-existente en pantalla antes de esta refactorización.
- Para Fase 4 (RTM badge): solo hay que crear `RtmModel with VehicleDocumentExpiry implements VehicleDocumentModel`, `RtmCubit extends VehicleDocumentCubit<RtmModel>`, y añadir `VehicleDocumentKind.rtm` + la rama `switch` en `VehicleDocumentCard`.
