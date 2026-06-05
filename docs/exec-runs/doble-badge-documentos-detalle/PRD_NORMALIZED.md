# PRD Normalizado — Doble badge de documentos en el detalle del vehículo

**Slug:** `doble-badge-documentos-detalle`
**Fuente:** `docs/plans/tecnomecanica-rtm/phases/phase-04-doble-badge-de-documentos-en-el-detalle-del-vehi.md`
**Fase origen:** 4 de 6 (plan `tecnomecanica-rtm`)
**Nivel rg-exec:** normal
**Normalizado:** 2026-06-04T20:44:30Z

---

## 1 Objetivo

Montar dos instancias del `VehicleDocumentCard` genérico (Fase 1) en el detalle del vehículo — SOAT arriba, RTM debajo — de modo que el conductor vea de un vistazo el estado de ambos documentos y pueda tocar cada badge para entrar a su flujo respectivo. Es una capa fina de presentación: no diseña el card genérico (Fase 1) ni el flujo RTM (Fase 3), solo los monta y blinda el punto de acoplamiento arquitectónico.

---

## 2 Por qué

El detalle de vehículo hoy solo muestra el SOAT via el card específico `VehicleSoatCard` (acoplado a `features/soat/`). Con la llegada de la RTM (Fase 3) se necesita un segundo badge, y el momento natural para blindar el desacoplamiento del host del detalle es ahora: si se importan `SoatCubit`/`TecnomecanicaCubit` concretos en `vehicles/`, se establece una dependencia de feature-a-feature imposible de escalar a N documentos futuros. Esta fase elimina el anti-patrón (card específico con `getIt`/strings hardcodeados), borra huérfanos acoplados, y garantiza que los hosts del detalle solo dependan del contrato genérico `vehicle_documents/`.

---

## 3 Alcance

### Entra
- Dos instancias de `VehicleDocumentCard` en `vehicle_detail_view.dart`: SOAT arriba, RTM debajo, mismo alto y `SizedBox(height: 16)` entre ellos.
- Provisión de cubits por badge mediante `BlocProvider` en el árbol (no `getIt` en el widget), con carga independiente: cada cubit dispara su `load(vehicleId)` por separado, sin bloqueo cruzado ni parpadeo/reflow.
- Cableado del tap RTM hacia el flujo de Fase 3 (`tecnomecanica/`); el tap SOAT preserva su flujo actual.
- Gate de no-acoplamiento A11 (acotado a los dos hosts): `vehicle_detail_page.dart` y `vehicle_detail_view.dart` no importan `features/soat/` ni `features/tecnomecanica/` concretos.
- Borrado de `vehicle_soat_section.dart` (widget huérfano sin consumidores que importa `features/soat/`).
- Borrado de `vehicle_soat_card.dart` una vez que `vehicle_detail_view.dart` ya no lo referencia.
- Preservación intacta del `BlocListener<VehicleCubit>` de odómetro (líneas 61–89 de `vehicle_detail_page.dart`) y de todos los callbacks de mantenimiento.
- Regresión visual del badge SOAT: 4 estados idénticos a hoy (`valid`, `expiringSoon`, `expired`, `none`).
- Widget tests de carga independiente, regresión SOAT (4 estados), tap por `kind`, y prueba de integración del listener de odómetro.

### No entra
- Rediseño del `VehicleDocumentCard` genérico ni su lógica de estados (Fase 1).
- Flujo de captura-en-alta-de-vehículo (`vehicle_form_docs_section.dart`, `vehicle_soat_form_slot.dart`, `vehicle_form_view.dart`): conservan sus imports de `soat/` legítimamente.
- Creación del flujo RTM ni del `TecnomecanicaCubit` (Fase 3).
- Cambios de contrato `rideglory-api` ni migraciones de base de datos.
- Unificación de strings SOAT↔RTM (decisión de Fase 1/3).

---

## 4 Áreas afectadas

| Área | Archivos clave |
|------|---------------|
| Presentación — detalle vehículo | `lib/features/vehicles/presentation/detail/vehicle_detail_page.dart` |
| Presentación — vista detalle | `lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart` |
| Borrados | `lib/features/vehicles/presentation/garage/widgets/vehicle_soat_card.dart`, `lib/features/vehicles/presentation/garage/widgets/vehicle_soat_section.dart` |
| Localización | `lib/l10n/app_es.arb` (verificar strings badge RTM si Fase 1/3 no las definió) |
| Tests | `test/features/vehicles/.../vehicle_documents_badges_test.dart` (nuevo) |
| Contrato consumido (solo lectura) | `lib/features/vehicle_documents/` (genérico de Fase 1), `lib/features/tecnomecanica/` (flujo de Fase 3) |

**Backend:** ninguno — fase 100% Flutter de presentación.

---

## 5 Criterios de aceptación

1. **Gate de no-acoplamiento del host (acotado, satisfacible).** El grep acotado devuelve cero matches:
   ```bash
   grep -n "features/soat\|features/tecnomecanica" \
     lib/features/vehicles/presentation/detail/vehicle_detail_page.dart \
     lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart
   ```
   (El grep global sobre `lib/features/vehicles/` NO es el gate: devuelve 6 archivos legítimos del flujo de alta de vehículo que están fuera del alcance de esta fase.)

2. **Hosts libres de tipos concretos de features de documentos.** `vehicle_detail_page.dart` y `vehicle_detail_view.dart` no importan ni referencian `SoatModel`, `SoatStatus`, `SoatCubit`, `TecnomecanicaModel`, `TecnomecanicaCubit`, `VehicleSoatCard`, `SoatEntryFlow`, ni rutas/usecases de `soat/`/`tecnomecanica/`. Solo dependen del contrato genérico `vehicle_documents/` y tipos propios de `vehicles/`.

3. **Dos badges renderizan juntos.** El detalle del vehículo muestra exactamente dos `VehicleDocumentCard`: SOAT arriba, RTM debajo, con `SizedBox(height: 16)` entre ellos (idéntico al spacing del resto de cards). Verificable por widget test (encuentra 2 instancias) e inspección visual.

4. **Carga independiente por badge (sin bloqueo cruzado).** Con `SoatCubit` en `loading` y `TecnomecanicaCubit` en `data` (o viceversa), cada badge muestra su propio estado simultáneamente; resolver uno no dispara reflow/parpadeo en el otro; cada badge preserva su loading skeleton. Verificable por widget test con cubits en estados desincronizados.

5. **Regresión visual del badge SOAT.** Los 4 estados (`valid` → "Vigente", `expiringSoon` → "Por vencer", `expired` → label vencido, `none`/`null` → "tap to add") se ven y se comportan idénticos a hoy (color de estado, label, fecha de vencimiento, ícono, chevron, tap). Verificable por widget test parametrizado por estado (baseline capturada del `vehicle_soat_card.dart` antes de borrarlo).

6. **Tap de cada badge entra a su flujo correcto.** Tocar el badge SOAT navega al flujo SOAT (captura si no hay documento, estado si lo hay); tocar el badge RTM navega al flujo RTM de Fase 3. La navegación se resuelve por `kind` a través del contrato genérico; no hay navegación hardcodeada a `soat/`/`tecnomecanica/` en `vehicles/`.

7. **`BlocListener<VehicleCubit>` de odómetro intacto.** Tras crear/actualizar un mantenimiento, el `currentMileage` del detalle sigue sincronizándose vía el listener existente sin regresión. Los callbacks `onMaintenanceCreated`, `onPendingMaintenanceConsumed`, `onMaintenanceRefreshRequested` y `onVehicleUpdated` funcionan exactamente igual. Los nuevos `BlocProvider`s se anidan dentro del `build` envolviendo el `child` del `BlocListener`, sin alterar ninguna firma de callback.

8. **Huérfanos eliminados.** `vehicle_soat_card.dart` y `vehicle_soat_section.dart` no existen en el árbol; `grep -rln "VehicleSoatCard\|VehicleSoatSection" lib/` devuelve vacío.

9. **Transversales Flutter.** `dart analyze` sin nuevos warnings; un widget por archivo; cero métodos `Widget _buildX()`; texto/iconos oscuros sobre el primario naranja donde aplique; strings vía `context.l10n.<key>` (cero literales hardcodeados — los strings `'Vigente'`/`'Por vencer'`/`'Vence …'` del viejo card quedan eliminados con su borrado).

---

## 6 Guardrails de regresión

- El `BlocListener<VehicleCubit>` de odómetro (líneas 61–89 de `vehicle_detail_page.dart`) debe preservarse intacto; cualquier cambio en la firma del `StatefulWidget`/`build` que lo rompa es regresión bloqueante.
- El grep acotado del Criterio 1 debe ejecutarse explícitamente antes de cerrar la fase; un fallo es bloqueante.
- `grep -rln "VehicleSoatCard" lib/` debe devolver vacío (o solo el propio archivo si aún no se borró) antes de borrar; y vacío después.
- `grep -rln "VehicleSoatSection" lib/` ídem.
- `dart analyze` no debe introducir nuevos warnings respecto al estado previo de la rama.
- El flujo de alta de vehículo (`vehicle_form_docs_section.dart`, `vehicle_soat_form_slot.dart`, `vehicle_form_view.dart`) no se toca; si alguno aparece modificado en el diff, es regresión.
- Si `VehicleDocumentCard` aún expone el anti-patrón (`getIt`/`bool _isLoading`/strings hardcodeados) al momento de ejecutar esta fase, **no parchear aquí**: bloquear y reportar que Fase 1 no está completa.
- Si proveer los cubits obliga a importar `SoatCubit`/`TecnomecanicaCubit` concretos en el host del detalle, **no parchear con un import concreto**: escalar a Fase 1/Architect.

---

## 7 Constraints heredados

- **Clean Architecture:** dependencias fluyen hacia adentro; `vehicles/presentation/` no importa features concretos de `soat/` ni `tecnomecanica/`; solo consume contratos de `vehicle_documents/`.
- **Cubits via `BlocProvider` en el árbol**, nunca `getIt` dentro de un widget; `AuthCubit` es la única excepción global (regla de proyecto).
- **Un widget por archivo**; cero métodos que retornan widgets (`Widget _buildX()`).
- **Texto/iconos oscuros** (`AppColors.darkBgPrimary`) sobre el primario naranja (`#f98c1f`); nunca blanco.
- **Strings vía `context.l10n.<key>`**; cero literales hardcodeados en UI.
- **`AppSwitch`/`AppSwitchTile`** para switches; nunca `Material Switch`/`FormBuilderSwitch`.
- **`dart analyze` limpio** antes de considerar la fase cerrada.
- **No commitear**: el árbol de trabajo queda sucio para revisión humana.
- **No tocar**: `workflow/state.json`, `docs/PRD.md`, `docs/PLAN.md`, `docs/ITERATION_HISTORY.md`, ni archivos del sistema `/iter`.
- **Local API hack** (`shouldUseLocalApi=true` en `api_base_url_resolver.dart`) es configuración local del usuario; no revertir ni commitear.
