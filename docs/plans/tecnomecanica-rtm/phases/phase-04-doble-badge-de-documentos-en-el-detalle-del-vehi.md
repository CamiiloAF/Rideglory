# Fase 4 — Doble badge de documentos en el detalle del vehículo

**Slug:** `tecnomecanica-rtm`
**Fase:** 4 de 6
**Corte / PR:** parte del corte RTM (PR #3, Fases 3–5)
**Depende de:** Fase 1 (`vehicle_documents/` + `VehicleDocumentCard` genérico), Fase 3 (`TecnomecanicaModel`/`TecnomecanicaCubit`)
**Nivel rg-exec:** normal
**Generado:** 2026-06-04T13:26:51Z

> Sesión de planeación. No se modifica código de la app. Este archivo es la especificación ejecutable de la fase; el implementador la ejecuta con `rg-exec` (nivel normal). Respeta Clean Architecture + `rideglory-coding-standards`.

---

## Objetivo

En el detalle de su moto, el conductor ve **de un vistazo** el estado del SOAT y el de la RTM (dos badges apilados: SOAT arriba, RTM debajo), cada uno con sus 4 estados, y puede **tocar cada uno** para entrar a su flujo respectivo (SOAT → `SoatEntryFlow`/`soatStatus`; RTM → flujo de captura/estado de Fase 3). Es una **capa fina** sobre el `VehicleDocumentCard` genérico que ya nace en Fase 1: esta fase **no diseña** el badge, solo **monta dos instancias** del genérico en el detalle y blinda el punto de acoplamiento.

---

## Alcance (entra / no entra)

### Entra
- Montar **dos** instancias de `VehicleDocumentCard` (genérico de Fase 1, parametrizado por `kind`) en el detalle del vehículo: SOAT arriba, RTM debajo, mismo alto y spacing.
- Garantizar que cada badge **carga de forma independiente** (cada uno con su propio cubit por `kind`): uno puede estar `loading` mientras el otro ya tiene `data`/`empty`, sin bloqueo cruzado ni parpadeo/reflow. El loading skeleton **por badge** se preserva.
- Cablear el **tap** del badge RTM hacia el flujo de Fase 3 (`tecnomecanica/`), igual que el SOAT ya entra a su flujo.
- **Gate de no-acoplamiento (A11):** los dos archivos del host del badge en el detalle (`vehicle_detail_page.dart` y `vehicle_detail_view.dart`) **no importan** `features/soat/` ni `features/tecnomecanica/` concretos — solo el contrato genérico `features/vehicle_documents/` (y `vehicles/` propio). Verificable por grep **acotado a esos dos archivos**.
- Resolver `vehicle_soat_section.dart`: hoy es un widget **huérfano** (clase `VehicleSoatSection` sin consumidores en `lib/`) que importa `features/soat/`. **Borrarlo** como parte de la fase (ver paso 8) para que no quede deuda acoplada en `garage/widgets/`.
- **Regresión visual del badge SOAT:** los 4 estados (`valid`/`expiringSoon`/`expired`/`none`) se ven y se comportan idénticos a hoy.

### No entra
- **No** se rediseña el `VehicleDocumentCard` ni la lógica de estados: eso es Fase 1 (ADR-F). Aquí solo se consume.
- **No** se toca el flujo de **captura-en-alta-de-vehículo** (`vehicle_form_docs_section.dart`, `vehicle_soat_form_slot.dart`, `vehicle_form_view.dart`, y el re-export de `SoatStatus` por `vehicle_model.dart`). Esos archivos **conservan legítimamente** imports de `features/soat/` por ser otro caso de uso (alta de vehículo), fuera de alcance de esta fase y del gate (ver §Gate / Criterio 1). ADR-E solo renombra el modelo duplicado a `VehicleSoatFormData`; **no** lo desacopla de `soat/`.
- **No** hay cambios de contrato `rideglory-api` ni migraciones.
- **No** se crea el flujo RTM ni el cubit RTM (Fase 3). Esta fase **asume** que `TecnomecanicaCubit` y su flujo ya existen.
- **No** se unifican strings SOAT↔RTM (claves en paralelo, decisión de Fase 1/3).

---

## Que se debe hacer (pasos concretos y ordenados)

1. **Verificar prerequisitos de Fase 1 y 3.** Confirmar que existe `VehicleDocumentCard` genérico (parametrizado por `VehicleDocumentKind`, alimentado por un cubit con `ResultState`, sin `getIt` en el widget, strings en ARB) y que `TecnomecanicaCubit extends VehicleDocumentCubit<TecnomecanicaModel>` con su flujo de tap ya está disponible. Si `VehicleDocumentCard` aún expone el anti-patrón (`getIt`/`bool _isLoading`/strings hardcodeados del viejo `vehicle_soat_card.dart`), **la Fase 1 no está completa**: bloquear y reportar, no parchear aquí.

2. **Decidir el patrón de provisión de cubits por badge.** Cada badge necesita su propio cubit (`SoatCubit` para SOAT, `TecnomecanicaCubit` para RTM), provisto por `BlocProvider` en el árbol (no `getIt` dentro del widget; regla de proyecto: cubits `@injectable` + `BlocProvider`). Recomendación: proveer **ambos** cubits en `vehicle_detail_page.dart` (el `StatefulWidget` que ya es el host de estado del detalle) y pasarlos/reenviarlos a `VehicleDetailView` → a cada `VehicleDocumentCard`. Mantener **carga independiente**: cada cubit dispara su `load(vehicleId)` por separado; ningún `BlocBuilder` espera al otro. **Si la única manera de instanciar esos cubits es importar los tipos concretos `SoatCubit`/`TecnomecanicaCubit` dentro del host, eso rompe el gate A11 — Fase 1 debe exponer una vía genérica (factory/provider por `kind` en `vehicle_documents/`); si no existe, escalar a Fase 1/Architect, no parchear con un import concreto.**

3. **Insertar el segundo badge en `vehicle_detail_view.dart`.** Hoy (líneas 59–60) hay un único `VehicleSoatCard(vehicle: vehicle)` seguido de `SizedBox(height: 16)`. Reemplazar por **dos** `VehicleDocumentCard` (uno `kind: soat`, otro `kind: tecnomecanica`) apilados con el mismo `SizedBox(height: 16)` entre ellos: SOAT arriba, RTM debajo. Mismo alto/spacing que el resto de cards del detalle.

4. **Reapuntar imports del host.** En `vehicle_detail_view.dart`, eliminar el import de `vehicle_soat_card.dart` y cualquier import de `features/soat/`; importar solo el genérico `features/vehicle_documents/` + tipos propios de `vehicles/`. En `vehicle_detail_page.dart`, si se proveen los cubits ahí, hacerlo a través del contrato genérico que Fase 1 exponga en `vehicle_documents/` (no importar `SoatCubit`/`TecnomecanicaCubit` concretos — ver paso 2).

5. **Preservar el `BlocListener<VehicleCubit>` existente.** `vehicle_detail_page.dart` es hoy un `StatefulWidget` con `_vehicle` mutable y un `BlocListener<VehicleCubit, ResultState<List<VehicleModel>>>` (líneas 61–89) que sincroniza el odómetro. **No romperlo.** Los dos cubits nuevos (SOAT, RTM) deben llegar/instanciarse de forma que el `BlocListener` y el `setState`/`copyWith` del odómetro sigan exactamente igual: si se añaden `BlocProvider`s, anidarlos **dentro** del `build` envolviendo el `child` del `BlocListener` (o por encima), sin alterar la firma del callback de odómetro ni el `onVehicleUpdated`. La firma pública de `VehicleDetailView` puede recibir lo que haga falta por constructor, pero los callbacks de mantenimiento/odómetro existentes se mantienen intactos.

6. **Cablear el tap RTM.** El badge RTM, al tocarse, entra al flujo de Fase 3 (captura si no hay documento → estado si lo hay), espejo de cómo el badge SOAT entra a `SoatEntryFlow.start` / `AppRoutes.soatStatus`. El genérico de Fase 1 debe recibir el handler de tap por `kind` (o el card resuelve el destino por `kind`); usar ese contrato, no hardcodear navegación a `soat/`/`tecnomecanica/` en `vehicles/`.

7. **Verificar el gate A11 por grep ACOTADO (no global).** El grep global sobre todo `lib/features/vehicles/` devuelve hoy **6 archivos / ≥8 matches preexistentes y legítimos** del flujo de alta de vehículo (`vehicle_model.dart`, `vehicle_form_docs_section.dart`, `vehicle_soat_form_slot.dart`, `vehicle_form_view.dart`). Si el implementador corre el grep global lo vería "rojo" y se bloquearía sin razón. El gate de **esta fase** es solo sobre los **dos hosts del badge en el detalle**:

   ```bash
   grep -n "features/soat\|features/tecnomecanica" \
     lib/features/vehicles/presentation/detail/vehicle_detail_page.dart \
     lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart
   ```

   Resultado esperado: **cero matches**. Si aparece cualquier import concreto de `soat/` o `tecnomecanica/` en esos dos archivos, el gate **falla**.

8. **Borrar el huérfano `vehicle_soat_section.dart`.** Verificado en el scan: la clase `VehicleSoatSection` (`lib/features/vehicles/presentation/garage/widgets/vehicle_soat_section.dart`) **no tiene consumidores** en `lib/` (el único match de `vehicle_soat_section` en el viejo card es la clave l10n `vehicle_soat_section_title`, no el widget) e importa `features/soat/`. Borrar el archivo. Confirmar antes de borrar con `grep -rln "VehicleSoatSection" lib/` → solo debe aparecer el propio archivo.

9. **Borrar `vehicle_soat_card.dart`** una vez que `vehicle_detail_view.dart` ya no lo referencia (su lógica vive ahora en el `VehicleDocumentCard` genérico de Fase 1). Confirmar con `grep -rln "VehicleSoatCard" lib/` → vacío (salvo el propio archivo) antes de borrar.

10. **Tests y verificación visual.** Widget tests de los dos badges (estados independientes), regresión visual del SOAT en sus 4 estados, `dart analyze` sin nuevos warnings, `dart run build_runner build` si Fase 1 introdujo DI/cubits nuevos consumidos aquí.

---

## Archivos a crear/modificar (rutas reales, una línea de "que cambia")

| Ruta | Acción | Qué cambia |
|------|--------|------------|
| `lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart` | modificar | Reemplaza el único `VehicleSoatCard` por **dos** `VehicleDocumentCard` (SOAT arriba, RTM debajo) con mismo spacing; elimina import de `vehicle_soat_card.dart` y de `features/soat/`. **Gate A11 aplica a este archivo.** |
| `lib/features/vehicles/presentation/detail/vehicle_detail_page.dart` | modificar | Provee los **dos cubits por badge** (`BlocProvider` en el árbol, dentro de `build`) y los reenvía a `VehicleDetailView`. **Es `StatefulWidget` con `_vehicle` mutable y `BlocListener<VehicleCubit>` (líneas 61–89): preservar intactos el listener de odómetro, `onVehicleUpdated` y los callbacks de mantenimiento.** Los nuevos providers se anidan dentro del `build` envolviendo el `child` del `BlocListener`, sin cambiar la firma de los callbacks existentes ni la del `StatefulWidget` (los cubits llegan/instancian sin tocar el contrato de odómetro). **Gate A11 aplica a este archivo.** |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_soat_card.dart` | **borrar** | Su lógica (4 estados, tap, label) ya vive en el `VehicleDocumentCard` genérico de Fase 1; sin consumidores tras el paso 3. Elimina el anti-patrón (`getIt`, `bool _isLoading`, `'Vigente'`/`'Por vencer'`/`'Vence …'` hardcodeados). |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_soat_section.dart` | **borrar** | Widget `VehicleSoatSection` huérfano (sin consumidores en `lib/`) que importa `features/soat/`; se elimina para no dejar acoplamiento muerto en `garage/widgets/`. |
| `lib/l10n/app_es.arb` (+ generados) | revisar | Solo si Fase 1 no migró ya las strings del badge (`vehicle_doc_soat_label`, `vehicle_soat_tap_to_add`, etc.) y la clave RTM equivalente. Verificar que el badge RTM usa claves `tecnomecanica_*`; no crear claves nuevas si Fase 1/3 ya las definió. |
| `test/features/vehicles/.../vehicle_documents_badges_test.dart` | crear | Widget test: dos badges renderizan juntos, carga independiente (uno `loading` / otro `data`), regresión visual SOAT en 4 estados, tap navega al flujo correcto por `kind`. |

> Nota: la **forma exacta** de cómo `VehicleDocumentCard` recibe su cubit/handler la define Fase 1 (ADR-F). Esta fase **consume** ese contrato; si la firma del genérico no soporta lo que pide el paso 2/6, es bug de Fase 1, no se resuelve aquí.

---

## Contratos / API rideglory-api (o "ninguno")

**Ninguno.** No hay rutas, DTOs ni `@MessagePattern` nuevos ni modificados. Esta fase es 100% Flutter de presentación; consume el contrato genérico de Fase 1 y el flujo RTM de Fase 3 (que a su vez consume el contrato de Fase 2). No toca `rideglory-api`.

---

## Cambios de datos / migraciones (o "ninguno")

**Ninguno.** Sin Prisma, sin tablas, sin migración. No hay persistencia nueva.

---

## Criterios de aceptación (numerados, observables, testeables)

1. **Gate de no-acoplamiento del host del detalle (acotado y SATISFACIBLE).** El siguiente grep devuelve **cero matches**:

   ```bash
   grep -n "features/soat\|features/tecnomecanica" \
     lib/features/vehicles/presentation/detail/vehicle_detail_page.dart \
     lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart
   ```

   Justificación de por qué NO se usa el grep global sobre `lib/features/vehicles/`: ese grep devuelve hoy **6 archivos** con imports de `soat/` **legítimos** porque pertenecen al flujo de **captura-en-alta-de-vehículo** (`vehicle_form_docs_section.dart`, `vehicle_soat_form_slot.dart`, `vehicle_form_view.dart`) y al re-export de `SoatStatus` por `vehicle_model.dart`. Ese flujo está **fuera de alcance** de esta fase y de esta iteración (ADR-E solo renombra el modelo duplicado a `VehicleSoatFormData`, **no** lo desacopla de `soat/`). Acoplarlos sería un refactor distinto y mayor; aplicar el gate global aquí sería un criterio **no satisfacible** dentro del alcance.

2. **`vehicle_detail_page.dart` y `vehicle_detail_view.dart` libres de tipos concretos de features de documentos.** Ambos archivos (nombrados explícitamente, son los dos hosts naturales de los providers/badges) no importan ni referencian `SoatModel`, `SoatStatus`, `SoatCubit`, `TecnomecanicaModel`, `TecnomecanicaCubit`, `VehicleSoatCard`, `SoatEntryFlow`, ni rutas/usecases de `soat/`/`tecnomecanica/`. Solo dependen del contrato genérico `vehicle_documents/` + tipos propios de `vehicles/`. (Cubre los dos hosts; el criterio 1 lo verifica por grep.)

3. **Dos badges renderizan juntos.** En el detalle del vehículo se ven **dos** `VehicleDocumentCard`: SOAT arriba, RTM debajo, con el **mismo alto y spacing** (separación `SizedBox(height: 16)`, idéntica al resto de cards del detalle). Verificable por widget test (encuentra 2 cards) e inspección visual.

4. **Carga independiente por badge (sin bloqueo cruzado).** Con SOAT en `loading` y RTM en `data` (o viceversa), cada badge muestra su propio estado a la vez; ninguno espera al otro. No hay parpadeo/reflow al resolver uno mientras el otro sigue cargando. Cada badge preserva su **loading skeleton**. Verificable por widget test con cubits en estados distintos.

5. **Regresión visual del badge SOAT.** Los 4 estados del SOAT (`valid` → "Vigente", `expiringSoon` → "Por vencer", `expired` → label vencido, `none`/`null` → "tap to add") se ven y se comportan **idénticos a hoy** (color de estado, label, fecha de vencimiento, ícono, chevron, tap). Verificable por widget test parametrizado por estado.

6. **Tap de cada badge entra a su flujo.** Tocar el badge SOAT entra al flujo SOAT (captura si no hay documento, estado si lo hay); tocar el badge RTM entra al flujo RTM de Fase 3. La navegación por `kind` la resuelve el genérico/contrato de Fase 1; no hay navegación a `soat/`/`tecnomecanica/` hardcodeada en `vehicles/`.

7. **`BlocListener<VehicleCubit>` de odómetro intacto.** Tras crear/actualizar un mantenimiento, el `currentMileage` del detalle sigue sincronizándose vía el `BlocListener` existente (líneas 61–89) sin regresión; los callbacks de mantenimiento (`onMaintenanceCreated`, `onPendingMaintenanceConsumed`, `onMaintenanceRefreshRequested`, `onVehicleUpdated`) siguen funcionando.

8. **Huérfanos eliminados.** `vehicle_soat_card.dart` y `vehicle_soat_section.dart` ya no existen; `grep -rln "VehicleSoatCard\|VehicleSoatSection" lib/` devuelve vacío.

9. **Transversales Flutter:** `dart analyze` sin **nuevos** warnings; un widget por archivo; cero métodos `Widget _buildX()`; texto/iconos oscuros sobre el primario donde aplique; strings vía `context.l10n.<key>` (cero literales hardcodeados — los `'Vigente'`/`'Por vencer'`/`'Vence …'` del viejo card quedan eliminados con su borrado).

---

## Pruebas (unitarias/widget/integración)

**Widget (lo central de esta fase):**
- **Dos badges juntos:** el detalle renderiza exactamente 2 `VehicleDocumentCard`; SOAT antes que RTM en el orden del árbol.
- **Carga independiente:** inyectar `SoatCubit` en `loading` y `TecnomecanicaCubit` en `data` → ambos estados visibles simultáneamente; invertir → idem. Verificar que resolver uno no dispara reflow/parpadeo en el otro (el skeleton del que sigue cargando permanece).
- **Regresión SOAT (4 estados):** parametrizar el cubit SOAT por estado y verificar color/label/fecha idénticos a la baseline (capturar la baseline del comportamiento actual de `vehicle_soat_card.dart` antes de borrarlo).
- **Tap por `kind`:** tocar badge SOAT → navega al flujo SOAT; tocar badge RTM → navega al flujo RTM. Verificar con un router/navigator mock.

**Integración / regresión cruzada:**
- `BlocListener<VehicleCubit>` de odómetro: simular emisión de `VehicleCubit` con `currentMileage` distinto → el detalle se actualiza (no se rompió al envolver con los nuevos providers).

**Estáticas / gate:**
- Test de gate (o paso CI/manual) que ejecuta el grep acotado del Criterio 1 y exige cero matches.
- `dart analyze` sin nuevos warnings; `dart run build_runner build` sin conflictos si aplica.

> No requiere QA adversarial (nivel normal). El riesgo se cubre con widget tests de carga independiente + regresión SOAT + el gate de grep.

---

## Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigación |
|---|--------|-----------|------------|
| R-gate | El único modo de proveer los cubits obliga a importar `SoatCubit`/`TecnomecanicaCubit` concretos en `vehicle_detail_page.dart`, rompiendo A11. | Media | Fase 1 debe exponer un mecanismo genérico (factory/provider por `kind` en `vehicle_documents/`) para que el detalle no importe features concretos. Si no existe, **escalar a Fase 1/Architect**, no parchear con un import concreto. Pasos 2 y 4. |
| R-visual | Regresión visual del badge SOAT al migrar del card específico al genérico. | Media | Capturar baseline del comportamiento actual antes de borrar `vehicle_soat_card.dart`; widget test parametrizado por los 4 estados; verificación visual manual (Fase 6 también lo revisa). |
| R-cross | Bloqueo cruzado / parpadeo si ambos badges comparten un solo cubit o un `FutureBuilder` combinado. | Media | Un cubit **por badge**, cargas disparadas por separado; widget test con estados desincronizados. Criterio 4. |
| R-listener | Romper el `BlocListener<VehicleCubit>` de odómetro al cambiar la firma del `StatefulWidget`/`build` para inyectar providers. | Media | Anidar los `BlocProvider` **dentro** del `build` envolviendo el `child` del `BlocListener`; no tocar los callbacks de odómetro/mantenimiento. Criterio 7 + test de integración. |
| R-orphan | Borrar `vehicle_soat_section.dart`/`vehicle_soat_card.dart` rompe un consumidor no detectado. | Baja | `grep -rln` antes de borrar (pasos 8/9); confirmado en scan que `VehicleSoatSection` no tiene consumidores y `VehicleSoatCard` solo lo usa `vehicle_detail_view.dart` (que se modifica primero). |
| R-l10n | Strings del badge quedan hardcodeadas o duplicadas. | Baja | Fase 1 ya mueve las del SOAT a ARB; verificar que el badge RTM usa `tecnomecanica_*`. No crear claves si Fase 1/3 ya las definió. |

---

## Dependencias (fases prerequisito y por qué)

- **Fase 1 — Abstracción `vehicle_documents/` + refactor SOAT (regresión cero).** Es el prerequisito duro: provee el `VehicleDocumentCard` genérico (parametrizado por `kind`, cubit + `ResultState`, sin `getIt`/`bool`, strings en ARB) y el contrato que soporta **N badges desde el inicio** (A3/ADR-F). Esta fase **monta** ese genérico dos veces; no lo diseña. Si el genérico no está limpio, esta fase no puede cerrar.
- **Fase 3 — Registrar/ver/editar/borrar RTM.** Provee `TecnomecanicaModel`/`TecnomecanicaCubit` (`extends VehicleDocumentCubit<TecnomecanicaModel>`) y el flujo de captura/estado RTM al que el badge RTM hace tap. Sin Fase 3 no hay segundo `kind` real que montar ni destino de navegación para el tap RTM.

(Fase 3 a su vez depende de Fase 2 para el contrato backend, pero esta fase no consume backend directamente.)

---

## Ejecución recomendada (nivel rg-exec: normal)

**Por qué ese nivel:** Capa fina sobre el genérico de Fase 1, pero es el **punto de acoplamiento crítico**: el gate de no-importar features concretos en `vehicles/` y la carga independiente por badge tienen riesgo de **regresión visual y arquitectónica medio**. No hay contrato ni migración, así que **normal con el gate de imports explícito basta**; no requiere QA adversarial. El flujo Architect-check (sanidad del contrato genérico de Fase 1) + Build + QA (widget tests de carga independiente y regresión SOAT) + 2 rondas + Tech Lead (enforce del gate acotado del Criterio 1 y del `BlocListener` preservado) cubre el riesgo real sin inflar el esfuerzo a `full`.
