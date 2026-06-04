# PRD Normalizado — RTM CRUD Flutter (Fase 3 tecnomecánica)

> **Slug:** `rtm-crud-flutter`
> **Generado:** 2026-06-04T18:44:34Z
> **Fuente:** `docs/plans/tecnomecanica-rtm/phases/phase-03-registrar-ver-editar-y-borrar-la-rtm-desde-la-ap.md`
> **Nivel rg-exec:** `normal`

---

## 1 Objetivo

Implementar en la app Flutter el CRUD completo de la Revisión Técnico-Mecánica (RTM / tecnomecánica) de un vehículo: el conductor captura manualmente los datos, los guarda, los consulta, los edita y los borra; ve el estado del documento (sin documento / vigente / por vencer / vencido) y la fecha de vencimiento.

El flujo es espejo fino del SOAT pero **sin OCR** y montado sobre los genéricos de `vehicle_documents/` (Fase 1). Valor entregado: paridad funcional SOAT para RTM, cumpliendo Clean Architecture, Pattern B y payloads de escritura vía `DTO.toJson()`.

---

## 2 Por qué

- Los usuarios deben poder registrar su RTM igual que el SOAT, sin depender de funciones de OCR o escaneo.
- El contrato de backend ya fue fijado en Fase 2 (`rideglory-api`); la infraestructura genérica de documentos de vehículo ya existe (Fase 1). Esta fase capitaliza ambas bases.
- No hay usuarios reales en producción aún, lo que permite un refactor agresivo y limpio.

---

## 3 Alcance

### Entra
- Feature nuevo `lib/features/tecnomecanica/` con tres capas (domain / data / presentation).
- `TecnomecanicaModel with VehicleDocumentExpiry implements VehicleDocumentModel` (clases puras, no freezed).
- `TecnomecanicaDto extends TecnomecanicaModel` (Pattern B) + `CreateTecnomecanicaRequestDto` con `.toJson()`.
- `TecnomecanicaService` Retrofit (`@singleton`): `GET/POST/DELETE /api/vehicles/:vehicleId/tecnomecanica`; `404 → Right(null) → ResultState.empty()`.
- `TecnomecanicaRepository` (interfaz) + `TecnomecanicaRepositoryImpl`.
- Use cases: `GetTecnomecanicaUseCase`, `SaveTecnomecanicaUseCase`, `DeleteTecnomecanicaUseCase` (sin OCR).
- `TecnomecanicaCubit extends VehicleDocumentCubit<TecnomecanicaModel>` (`@injectable`).
- Páginas: `TecnomecanicaStatusPage` y `TecnomecanicaManualCapturePage`.
- Orquestador `TecnomecanicaEntryFlow.start(context, vehicle)`.
- Rutas go_router: `/tecnomecanica/status` y `/tecnomecanica/manual-capture`.
- Formulario: `certificateNumber` (req), `cdaName` (req), `cdaCode` (opt), `startDate` (opt), `expiryDate` (req), `documentUrl` (opt).
- Editar (precarga) y borrar (con `ConfirmationDialog`).
- `TecnomecanicaExemptionNotice`: info chip no bloqueante para vehículo <2 años (por `purchaseDate`, fallback `year`).
- Strings `tecnomecanica_*` en `app_es.arb` (copy legal propio de RTM vencida).
- Eventos analytics `tecnomecanica_*` (snake_case, ≤40 chars), claves propias.
- DI + code-gen (`build_runner`).

### No entra
- OCR: sin autofill_banner, scan overlay, ScanSoatUseCase equivalente, image_picker, pdfx, ML Kit, TecnomecanicaUploadCubit.
- Badge RTM en detalle del vehículo → Fase 4.
- Backend / contrato / migración Prisma → ya cerrada en Fase 2.
- Recordatorios push / notificaciones → Fase 5.
- Cambios en el feature SOAT más allá de consumir los genéricos de Fase 1.
- Promover/crear genéricos en `vehicle_documents/` (ya existen).

---

## 4 Áreas afectadas

| Área | Descripción |
|------|-------------|
| `lib/features/tecnomecanica/` | Feature nuevo completo (domain / data / presentation) |
| `lib/l10n/app_es.arb` | Añadir claves `tecnomecanica_*`; claves SOAT intactas |
| `lib/core/services/analytics/analytics_events.dart` | Constantes `tecnomecanica_*` (≤40 chars) |
| `lib/core/services/analytics/analytics_params.dart` | Params RTM si aplica |
| `lib/shared/router/app_routes.dart` | Rutas `tecnomecanicaStatus`, `tecnomecanicaManualCapture` |
| `lib/shared/router/app_router.dart` | Registrar 2 rutas RTM (espejo de las SOAT ~líneas 372–381) |
| Generados (`*.g.dart`, `injection.config.dart`) | Regenerados por `build_runner`; no editar a mano |
| **No toca** | `lib/features/soat/`, `lib/features/vehicle_documents/` (solo consumo), `rideglory-api/` |

---

## 5 Criterios de aceptación

1. **Payload vía DTO.** El cuerpo del `POST /tecnomecanica` se construye con `CreateTecnomecanicaRequestDto.toJson()`. Grep en `tecnomecanica/` no encuentra ningún `<String, dynamic>{...}` construido a mano como body de escritura.

2. **Pattern B.** `TecnomecanicaModel implements VehicleDocumentModel` (con `VehicleDocumentExpiry`) y `TecnomecanicaDto extends TecnomecanicaModel`. `build_runner` genera `tecnomecanica_dto.g.dart` sin conflictos.

3. **Cubit sobre la base genérica.** `TecnomecanicaCubit extends VehicleDocumentCubit<TecnomecanicaModel>`, usa `ResultState<TecnomecanicaModel>` y emite `ResultState.empty()` cuando el GET responde 404 (verificable con un repo fake que devuelve `Right(null)`).

4. **Registrar.** Desde la pantalla de captura, con campos válidos, al guardar se hace POST y la `StatusPage` queda en `ResultState.data` mostrando los datos guardados.

5. **Ver.** Al entrar con un vehículo que tiene RTM, la `StatusPage` muestra estado (vigente / por vencer / vencido) y fecha de vencimiento derivados del mixin `VehicleDocumentExpiry` (umbral 30 días, `<0 → vencido`).

6. **Editar.** Desde la `StatusPage` de una RTM existente, "Editar" abre el formulario precargado con los datos actuales; al guardar, el documento se actualiza (upsert) y la vista refleja los nuevos valores.

7. **Borrar.** Desde la `StatusPage`, "Borrar" muestra `ConfirmationDialog`; al confirmar se hace DELETE y la vista pasa a `ResultState.empty()` (estado "sin documento").

8. **Analytics.** Existen constantes `tecnomecanica_*` en snake_case, cada una ≤40 chars (verificable por longitud), distintas de las claves SOAT. Se emite al menos: ver estado, guardar manual, borrar.

9. **Exención no bloqueante.** Para un vehículo con `purchaseDate` < 2 años (o `year` equivalente como fallback), aparece el info chip de exención; el botón "Guardar" sigue habilitado y permite guardar. No se emite error ni se bloquea por la exención.

10. **Sin OCR.** No existe en `tecnomecanica/` ningún `autofill_banner`, `scan`/`Stack` de cámara, "no reconocido", `*UploadCubit`, ni import de `image_picker`/`file_picker`/`pdfx`/ML Kit (verificable por grep).

11. **Copy legal propio.** El texto de "RTM vencida" en `app_es.arb` es propio de RTM (no idéntico al literal de SOAT). Claves SOAT no modificadas.

12. **Clean Architecture + estándares.** `domain/` sin Flutter/HTTP; `data/` sin `BuildContext`/widgets; `presentation/` sin HTTP directo ni DTO expuesto. Un widget por archivo; cero `Widget _buildX()`. Strings vía `context.l10n.<key>`. Texto/iconos oscuros sobre primario donde aplique. `dart analyze` sin nuevos warnings.

---

## 6 Guardrails de regresión

- La suite de tests SOAT debe seguir 100% verde sin modificar ningún test de `soat/`.
- `flutter test` y `dart analyze` sin nuevos warnings tras la fase.
- `dart run build_runner build --delete-conflicting-outputs` sin conflictos.
- Las claves SOAT en `app_es.arb` y `analytics_events.dart` deben quedar intactas (grep de verificación).
- `lib/features/vehicle_documents/` (genéricos de Fase 1) no se modifica; solo se consume.
- No introducir nuevas dependencias de pub (`pubspec.yaml` sin cambios de paquetes).
- No tocar `rideglory-api/` (contrato ya fijado en Fase 2).

---

## 7 Constraints heredados

- **Dependencia bloqueante Fase 1:** Deben existir `VehicleDocumentModel` (abstract), `VehicleDocumentExpiry` (mixin), `VehicleDocumentStatus`/`VehicleDocumentKind` (enums) y `VehicleDocumentCubit<T>` en `lib/features/vehicle_documents/`, más los widgets genéricos puros. Si falta alguno es bloqueo duro; no se improvisan aquí.
- **Dependencia bloqueante Fase 2 (integración real):** La API `rideglory-api` tiene el contrato RTM fijado; el front puede desarrollarse contra mock, pero la validación end-to-end requiere la API.
- **DTO.toJson() obligatorio:** Payloads de escritura HTTP siempre vía `DTO.toJson()`; nunca `Map<String, dynamic>` a mano (MEMORY: `feedback_dto_toJson.md`).
- **Pattern B obligatorio:** Todo DTO con modelo 1:1 extiende el modelo; `toModel()`/`fromModel()`/`.toDto()` están prohibidos.
- **Un widget por archivo:** Cero `Widget _buildX()`. Cada clase widget en su propio archivo.
- **Strings localizadas:** Cero literales hardcodeados en UI; todo vía `context.l10n.<key>`.
- **Texto oscuro sobre primario:** Sobre el acento naranja, texto/iconos/knob van con `darkBgPrimary` / `colorScheme.onPrimary`, nunca blanco.
- **AppSwitch unificado:** Cualquier switch usa `AppSwitch`/`AppSwitchTile`; nunca Material `Switch`/`FormBuilderSwitch`/`CupertinoSwitch`.
- **Cubits no singleton:** `@injectable` + `BlocProvider` en el árbol; nunca `@singleton`/`getIt` para cubits (excepción: `AuthCubit`).
- **Sin commits automáticos:** El árbol de trabajo queda sucio para revisión humana; no ejecutar `git add/commit/push`.
- **Local API hack:** `api_base_url_resolver.dart shouldUseLocalApi=true` es config local del usuario; no revertir ni commitear.
