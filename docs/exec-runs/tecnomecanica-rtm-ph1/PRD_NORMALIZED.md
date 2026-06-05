# PRD Normalizado — Fase 1: Abstracción vehicle_documents/ + refactor SOAT (regresión cero)

**Slug:** `tecnomecanica-rtm-ph1`
**Generado:** 2026-06-04T15:58:02Z
**Fuente:** `docs/plans/tecnomecanica-rtm/phases/phase-01-abstraccion-vehicle-documents-refactor-soat-regr.md`
**Nivel rg-exec:** `normal`

---

## 1 Objetivo

Crear la capa de abstracción `lib/features/vehicle_documents/` (dominio genérico + cubit base + widgets genéricos puros) y refactorizar SOAT para que sea la primera implementación concreta de ese contrato, eliminando la colisión de nombre `SoatModel` duplicado, el anti-patrón `getIt` dentro del widget badge y los literales hardcodeados del card — **sin ningún cambio visible para el usuario ni regresión en tests SOAT existentes**.

---

## 2 Por que

El scan de deuda reveló tres problemas en SOAT que, de no resolverse antes de implementar RTM (Fase 3), se duplicarán:
- `SoatModel` existe en dos features (`vehicles/` y `soat/`), colisión de nombre que ya genera confusión y riesgo en imports.
- `vehicle_soat_card.dart` usa `getIt<GetSoatUseCase>()` directo en widget (violación de arquitectura Clean) y `bool _isLoading` (antipatron vs `ResultState`).
- Lógica de estado (4 niveles, umbral 30d) y literales de UI atrapados en clases de dominio y en el widget badge.

Resolver esta deuda en Fase 1 paga el costo una vez y habilita que RTM (Fase 3), el segundo badge en el detalle (Fase 4) y la suite paramétrica de tests (Fase 6) sean capas finas sobre el contrato genérico ya verificado.

---

## 3 Alcance

### Entra
- **(ADR-E)** Renombrar el `SoatModel` duplicado de `vehicles/` a `VehicleSoatFormData` (archivo → `vehicle_soat_form_data.dart`). Reapuntar los 9 consumidores verificados. Pattern B preservado. `SoatStatus` no tocado.
- **(ADR-A)** Crear `lib/features/vehicle_documents/domain/`: `VehicleDocumentKind`, `VehicleDocumentStatus`, `mixin VehicleDocumentExpiry`, `abstract class VehicleDocumentModel`.
- Conectar `SoatModel` (de `soat/`) al contrato: `SoatModel with VehicleDocumentExpiry implements VehicleDocumentModel`. Mantener `SoatStatus get status` como capa de mapeo. Firma pública preservada. `SoatDto extends SoatModel` intacto.
- **(ADR-C)** Crear `abstract class VehicleDocumentCubit<T extends VehicleDocumentModel>` base. Refactorizar `SoatCubit extends VehicleDocumentCubit<SoatModel>` conservando `ResultState<SoatModel>` y analytics `soat_*`.
- **(ADR-D)** Promover widgets genéricos puros a `lib/features/vehicle_documents/presentation/widgets/` (`validity_card`, `detail_row`, `section_header`, `empty_state`, `status_view`, `data_view`), parametrizados por modelo/copy. SOAT reapunta sus imports.
- **(ADR-F)** Crear `VehicleDocumentCard` genérico (parametrizado por `VehicleDocumentKind`) en `lib/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart`. Sin `getIt` en widget, sin `bool _isLoading`, alimentado por cubit `@injectable` + `ResultState`. Eliminar `vehicle_soat_card.dart`. Reapuntar `vehicle_detail_view.dart` L59.
- Mover los 3 literales hardcodeados del card (`'Vigente'`, `'Por vencer'`, `'Vence {fecha}'`) a `context.l10n`, reusando `soat_status_valid` y `soat_status_expiring_soon`; añadir una sola clave con placeholder de fecha solo si no existe equivalente.
- Regenerar code-gen (`build_runner`) y l10n.

### No entra
- `home_garage_soat_badge.dart` (queda intacto, deuda conocida).
- `SoatStatus` enum (se preserva; consumidores no se tocan).
- Widgets OCR-específicos de `soat/`.
- Backend (`rideglory-api`), scheduler de notificaciones, `NotificationType`.
- `lib/features/tecnomecanica/` (Fase 3).
- Conversión de `SoatModel` a freezed.
- Migración de `toRequestJson()` manual a DTO de request (ADR-B, deuda para Fase 3).

---

## 4 Areas afectadas

| Area | Archivos clave |
|------|---------------|
| Dominio nuevo | `lib/features/vehicle_documents/domain/` (4 archivos nuevos) |
| Cubit base nuevo | `lib/features/vehicle_documents/presentation/cubit/vehicle_document_cubit.dart` |
| Widgets genéricos nuevos | `lib/features/vehicle_documents/presentation/widgets/` (6 archivos nuevos) |
| Modelo duplicado renombrado | `lib/features/vehicles/domain/models/soat_model.dart` → `vehicle_soat_form_data.dart`; DTO par en `data/dto/` |
| 9 consumidores del duplicado | `vehicle_repository_impl.dart`, `vehicle_service.dart`, `vehicle_repository.dart`, `vehicle_model.dart`, `vehicle_form_view.dart`, `vehicle_form_docs_section.dart`, `vehicle_soat_form_slot.dart`, `vehicle_soat_section.dart`, `soat_dto.dart` |
| `SoatModel` conectado al contrato | `lib/features/soat/domain/models/soat_model.dart` |
| `SoatCubit` refactorizado | `lib/features/soat/presentation/cubit/soat_cubit.dart` |
| Badge reescrito | `vehicle_soat_card.dart` eliminado → `vehicle_document_card.dart` nuevo |
| Consumidor del card | `lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart` L59 |
| Widgets SOAT reapuntados | 6 widgets en `lib/features/soat/presentation/widgets/` |
| l10n | `lib/l10n/app_es.arb` (reusar 2 claves; añadir 1 si no existe equivalente) |

---

## 5 Criterios de aceptacion

1. **Suite SOAT verde sin editar su acceptance:** `flutter test` pasa al 100% en todos los tests de `soat/` sin modificar ningún assertion existente. Si un test SOAT requiere cambiar su assertion para pasar, cuenta como regresión y la fase no cierra.
2. **`dart analyze` sin nuevos warnings** respecto a la línea base de `main`. Se permiten únicamente los 2 lints preexistentes del hack local de `api_base_url_resolver.dart`.
3. **`dart run build_runner build --delete-conflicting-outputs` sin conflictos** y los `.g.dart` de `SoatDto` no cambian de forma (Pattern B intacto; serialización SOAT idéntica).
4. **Cero literales hardcodeados en el card (3 exactos):** `grep -n "'Vigente'\|'Por vencer'\|'Vence "` sobre `lib/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart` devuelve 0 resultados; esos textos provienen de `context.l10n.<key>` reusando `soat_status_valid`, `soat_status_expiring_soon` y la clave de "Vence {fecha}".
5. **Cero `getIt` dentro del card:** `grep -n "getIt" lib/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart` devuelve 0 resultados. No existe `bool _isLoading` en el card (usa `ResultState`).
6. **Abstracción aplicada sin romper Pattern B:** `SoatModel with VehicleDocumentExpiry implements VehicleDocumentModel` compila; `SoatDto extends SoatModel` se mantiene; serialización SOAT idéntica (criterio 3).
7. **Colisión de nombre eliminada (ADR-E):** `grep -rn "class SoatModel" lib/` devuelve exactamente 1 resultado (el de `soat/`). El duplicado de `vehicles/` se llama `VehicleSoatFormData` y no implementa `VehicleDocumentModel`.
8. **`SoatStatus` preservado:** `grep -rn "enum SoatStatus" lib/` devuelve 1 resultado; sus consumidores (`home_garage_soat_badge`, `vehicle_cubit`, `app_router`, `vehicle_form_docs_section`, `vehicle_soat_form_slot`, `soat_status_page`, `soat_data_view`, `soat_status_view`, `vehicle_soat_section`, `vehicle_model`) compilan sin cambios de semántica.
9. **Único consumidor del card reapuntado:** `grep -rn "VehicleSoatCard(" lib/` devuelve 0 resultados; `vehicle_detail_view.dart` instancia `VehicleDocumentCard`. `home_garage_soat_badge.dart` no fue modificado.
10. **Contrato del genérico soporta N badges:** `VehicleDocumentCard` está parametrizado por `VehicleDocumentKind` y `VehicleDocumentCubit<T>` es genérico; añadir un segundo badge en Fase 4 es capa fina.
11. **Analytics SOAT intacto:** los eventos `soat_*` y los valores de `status.name` enviados a analytics son byte-idénticos a los de `main` (verificable por inspección de `SoatCubit` y del mapeo `SoatStatus`↔`VehicleDocumentStatus`).
12. **Cero cambio visible para el usuario:** el detalle del vehículo renderiza el badge SOAT con el mismo layout, colores, 4 estados, skeleton de loading y destino de tap que hoy.

---

## 6 Guardrails de regresion

- No modificar ningún assertion de tests SOAT existentes — cualquier cambio de assertion es regresión, no ajuste.
- `SoatStatus` enum no se elimina, no se renombra, no se mueve de `soat/domain/models/soat_model.dart`.
- `SoatDto extends SoatModel` (Pattern B) no se rompe; la forma de los `.g.dart` de SOAT no cambia.
- `home_garage_soat_badge.dart` no se toca.
- No se promueven widgets OCR-específicos (`soat_autofill_banner`, `soat_not_recognized_warning`, `soat_manual_option_card`, `soat_upload_option_card`, `soat_add_document_sheet`, `soat_vehicle_options_sheet`, `soat_action_tile`).
- No se convierte `SoatModel` a freezed.
- No se crea `lib/features/tecnomecanica/`.
- No se toca backend (`rideglory-api`).
- `VehicleDocumentCard` no usa `getIt` ni `bool` flags de estado.
- No se duplica copy ARB: reusar `soat_status_valid` / `soat_status_expiring_soon`; solo agregar una clave nueva de ser imprescindible para "Vence {fecha}".

---

## 7 Constraints heredados

- **Clean Architecture:** dominio sin Flutter imports; data sin widgets/BuildContext; presentación sin HTTP directo ni DTOs expuestos.
- **Pattern B obligatorio:** todo DTO con modelo 1:1 usa `XDto extends XModel`; `toModel()`/`fromModel()`/`.toDto()` están prohibidos.
- **Un widget por archivo:** cero métodos `Widget _buildX()` en el código nuevo o modificado.
- **Cubits @injectable + BlocProvider** (no @singleton / getIt); AuthCubit es la única excepción del proyecto.
- **`ResultState<T>`** para todo estado async (no booleanos de loading/error).
- **Texto oscuro sobre acento naranja** (`darkBgPrimary`), nunca blanco.
- **Switches unificados:** `AppSwitch`/`AppSwitchTile`; nunca Material/FormBuilderSwitch.
- **Shared widgets primero:** verificar `lib/shared/widgets/form/` antes de implementar cualquier widget de input/form.
- **Strings localizados:** todo texto visible en `app_es.arb` con `context.l10n.<key>`; cero literales hardcodeados en UI.
- **Code-gen en worktree fresco:** usar `--force-jit` o copiar `pubspec.lock`/`.env`/configs Firebase de `main` para evitar fallo por build hooks de `objective_c`.
- **`api_base_url_resolver.dart`** con `shouldUseLocalApi=true` es config local del usuario; no commitear ni revertir; sus 2 lints son preexistentes permitidos.
- **No commitear desde el workflow:** el árbol de trabajo queda sucio para revisión humana.
