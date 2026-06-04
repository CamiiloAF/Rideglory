# Fase 6 — Calidad, regresión y documentación

> **Slug:** `tecnomecanica-rtm` · **Fase:** 6 · **dependsOn:** [1, 2, 3, 4, 5]
> **Generado:** 2026-06-04T13:21:05Z · **Rol:** Tech Lead / PO
> **Nivel rg-exec recomendado:** `normal`
> Sesión de planeación. No se modifica código de la app: este archivo solo describe el trabajo de la fase.

---

## Objetivo

Cerrar la iteración con la **garantía verificada** de que:

1. **SOAT no se rompió** tras el refactor de la Fase 1 (regresión cero): captura, estados, vencimiento, badge y recordatorios push siguen idénticos a producción.
2. **RTM funciona en sus 4 estados** (`none`, `valid`, `expiringSoon`, `expired`) a nivel de la lógica compartida `VehicleDocumentExpiry`.
3. La **abstracción `vehicle_documents/`** queda **documentada** para que un tercer documento futuro sea capa fina y no requiera arqueología del código.

Esta es una fase de **verificación, no de parche**: si un test destapa una regresión, el bug **vuelve a su fase de origen** y NO se arregla dentro de la Fase 6. La fase solo cierra cuando todas las fases de origen están verdes; por eso su alcance es acotado y verificable.

---

## Alcance (entra / no entra)

### Entra

- **Tests unit de la lógica de estado de 4 estados** a nivel de `VehicleDocumentExpiry` (mixin), con casos **SOAT y RTM** (mismo árbol de fechas, dos `kind`).
- **Test parametrizado del cubit base** `VehicleDocumentCubit<T>` por `kind` (un solo conjunto de casos que cubre SOAT y RTM, no duplicado por feature).
- **Tests de los widgets genéricos compartidos** promovidos en Fase 1 (`validity_card`, `detail_row`, `section_header`, `empty_state`, `status_view`, `data_view`): probados **una sola vez** sobre el genérico, no una vez por feature.
- **Verificación manual del punto de integración más frágil**: los **dos badges (SOAT + RTM) renderizando juntos** en el detalle del vehículo, en sus combinaciones de estado, registrada en un checklist localizable del run.
- **Suite completa verde**: `flutter test` 100% en Rideglory; `dart analyze` limpio (sin nuevos warnings) en Rideglory; suite y lint verdes en `rideglory-api` para los specs de esta iteración.
- **Documentación**:
  - Nuevo `docs/features/tecnomecanica.md`.
  - Actualización de `docs/features/soat.md` por el refactor (abstracción + renombrado del modelo duplicado).
  - Registro de `vehicle_documents/` y de la feature `tecnomecanica/` en `CLAUDE.md` (tabla de features + nota de la abstracción).
  - Endpoint backend `/tecnomecanica` documentado (contrato POST/GET/DELETE, códigos, ownership).
- **Triage de regresiones**: si un test falla, clasificar el bug a su **fase de origen** y registrarlo; no parchear aquí.

### No entra

- **Cualquier cambio de comportamiento** (no se introduce feature nueva ni se modifica UI/lógica funcional).
- **Arreglar bugs descubiertos**: se re-enrutan a su fase de origen (1–5). La Fase 6 no contiene fixes de producto.
- Tests duplicados por feature de lo que ya cubre el genérico (los widgets compartidos y el cubit base se prueban **una sola vez**).
- Tests OCR/scan específicos de SOAT más allá de lo que ya existe (RTM no tiene OCR; los widgets OCR siguen en `soat/` y no se promovieron).
- Migraciones, cambios de contrato o de endpoints (cerrados en Fases 2 y 5).

---

## Que se debe hacer (pasos concretos y ordenados)

1. **Pre-flight: confirmar que las fases de origen están verdes.** Correr `flutter test` y `dart analyze` en Rideglory y la suite + lint de `rideglory-api`. Si algo está rojo de entrada, NO se arregla en la Fase 6: se reporta a su fase de origen y la Fase 6 queda bloqueada hasta que esa fase quede verde.

2. **Tests de la lógica de estado (4 estados) sobre `VehicleDocumentExpiry`.** En `test/features/vehicle_documents/domain/` cubrir, con fechas controladas:
   - `none` (sin documento / fecha nula),
   - `valid` (vence > 30 días),
   - `expiringSoon` (0 < días restantes ≤ 30, incluir bordes 30 y 1),
   - `expired` (fecha de vencimiento ya pasada, incluir el borde "vence hoy").
   Ejecutar el **mismo árbol de casos para SOAT y para RTM** (dos `kind`), confirmando que la lógica es la misma y vive en el mixin, no duplicada.

3. **Test parametrizado del cubit base** `VehicleDocumentCubit<T>` en `test/features/vehicle_documents/presentation/`: un conjunto de casos parametrizado por `kind` que valide load → `loading` → `data`/`empty`/`error`, y el mapeo **404 → `ResultState.empty()`**. Verifica que `SoatCubit` y el cubit RTM heredan el mismo comportamiento sin lógica divergente.

4. **Tests de widgets genéricos compartidos** en `test/features/vehicle_documents/presentation/widgets/`: golden/behavior básico de cada widget promovido en Fase 1, **una sola vez**. Confirmar que el copy se inyecta por parámetro (no por clave ARB común) y que el genérico soporta N badges.

5. **Verificación manual del doble badge (integración más frágil).** Levantar la app, abrir el detalle de un vehículo y recorrer la matriz de estados de SOAT × RTM (incluyendo "uno cargando mientras el otro tiene data", "uno vencido y el otro vigente", "RTM ausente / 404 → empty"). Registrar el resultado en **`docs/exec-runs/tecnomecanica-rtm/phase-06-qa-checklist.md`** (creado por el run), con una fila por combinación verificada y su estado (OK / re-enrutado a Fase N). Sin parpadeo/reflow ni bloqueo cruzado; ambos badges con mismo alto/spacing.

6. **Suite completa + analyze en ambos repos.** `flutter test` 100% verde y `dart analyze` sin nuevos warnings (Rideglory); suite y lint verdes en `rideglory-api` para los specs de la iteración. Si algo rompe, re-enrutar a la fase de origen.

7. **Documentación.**
   - Escribir `docs/features/tecnomecanica.md` (flujos: registrar/ver/editar/borrar, 4 estados, exención <2 años, recordatorios 30/7/0, route `rideglory://garage`).
   - Actualizar `docs/features/soat.md` reflejando que SOAT ahora corre sobre `vehicle_documents/` y que el `SoatModel` duplicado de `vehicles/` pasó a `VehicleSoatFormData`.
   - Registrar en `CLAUDE.md` la abstracción `vehicle_documents/` y la feature `tecnomecanica/` (tabla de features + nota de paridad SOAT/RTM sin OCR).
   - Documentar el endpoint `/tecnomecanica` (contrato POST/GET/DELETE, 404 sin documento, ownership/auth).

8. **Cierre formal.** La Fase 6 cierra solo cuando: (a) todas las fases de origen están verdes, (b) `flutter test`/`dart analyze` y la suite/lint de `rideglory-api` pasan, (c) la verificación manual del doble badge está registrada en el checklist del run, y (d) la documentación está escrita. Cualquier bug encontrado debe estar **re-enrutado y registrado**, no parcheado aquí.

---

## Archivos a crear/modificar (rutas reales, una linea de "que cambia")

### Rideglory (Flutter) — tests (crear)

- `test/features/vehicle_documents/domain/vehicle_document_expiry_test.dart` — 4 estados del mixin, casos SOAT y RTM con fechas controladas y bordes.
- `test/features/vehicle_documents/presentation/vehicle_document_cubit_test.dart` — cubit base parametrizado por `kind`; mapeo 404 → `empty`.
- `test/features/vehicle_documents/presentation/widgets/vehicle_document_widgets_test.dart` — widgets genéricos compartidos probados una sola vez.

> Si la Fase 1 ubicó la abstracción bajo otra ruta concreta (`lib/features/vehicle_documents/...`), los tests siguen el mismo árbol espejo bajo `test/features/vehicle_documents/...`.

### Rideglory (Flutter) — documentación

- `docs/features/tecnomecanica.md` — **crear**: feature RTM completa (flujos, estados, exención, notifs, route).
- `docs/features/soat.md` — **modificar**: SOAT corre sobre `vehicle_documents/`; nota del renombrado a `VehicleSoatFormData`.
- `CLAUDE.md` — **modificar**: registrar `vehicle_documents/` (abstracción) y `tecnomecanica/` en la tabla de features.

### Rideglory — run (crear, fuera del árbol de código)

- `docs/exec-runs/tecnomecanica-rtm/phase-06-qa-checklist.md` — **crear**: checklist localizable de la verificación manual del doble badge (matriz de estados SOAT × RTM, evidencia por fila).

### rideglory-api (NestJS) — tests / verificación

- `rideglory-api/vehicles-ms/src/vehicles/tecnomecanica.service.spec.ts` — **verificar verde** (origen Fase 2): cubre upsert / find / delete / expiring. Vive junto a `vehicles-ms/src/vehicles/soat.service.spec.ts`, la referencia real del SOAT (ambos sin prefijo `apps/`).
- `rideglory-api/api-gateway/src/scheduler/notification-scheduler.service.spec.ts` — **verificar verde** (origen Fase 5): los 3 crons SOAT siguen vivos y los 3 crons RTM disparan. Este spec **aún no existe** (lo crea la Fase 5) y debe nombrarse junto a `api-gateway/src/scheduler/notification-scheduler.service.ts`, donde viven los crons (confirmado en disco).
- `rideglory-api/api-gateway/src/notifications/notifications.service.spec.ts` — **verificar verde** (ya existe en disco): cubre el servicio de notificaciones; debe seguir pasando tras los `NotificationType` nuevos de la Fase 5.

> Nota: la Fase 6 **verifica** estos specs de backend; su **autoría** pertenece a las Fases 2 y 5. Si un spec rojo no existe o falla, el bug se re-enruta a su fase de origen.

---

## Contratos / API rideglory-api (o "ninguno")

**Ninguno nuevo.** La Fase 6 no crea ni modifica contratos. Solo **documenta** el ya cerrado en Fase 2:

- `POST /tecnomecanica` — upsert (Firebase Auth + `validateVehicleOwnership`; `expiry > start` server-side).
- `GET /tecnomecanica/:vehicleId` — **404 cuando no existe** documento (no `200 {data:null}`), mapeado en frontend a `Right(null) → ResultState.empty()`.
- `DELETE /tecnomecanica/:vehicleId` — borra con ownership check.

Todas las rutas de `rideglory-api` referenciadas en esta fase usan el layout real **sin prefijo `apps/`**: los microservicios viven directamente bajo la raíz del repo (`vehicles-ms/...`, `api-gateway/...`). Verificado en disco: `vehicles-ms/src/vehicles/soat.service.spec.ts`, `api-gateway/src/scheduler/notification-scheduler.service.ts` y `api-gateway/src/notifications/notifications.service.spec.ts` existen con esas rutas exactas.

---

## Cambios de datos / migraciones (o "ninguno")

**Ninguno.** La tabla de RTM y su migración Prisma se crearon y validaron localmente por un humano en la Fase 2. La Fase 6 no toca el esquema ni ejecuta migraciones.

---

## Criterios de aceptacion (numerados, observables, testeables)

1. **`flutter test` pasa al 100%** en Rideglory (sin tests `skip`/`fail`).
2. **`dart analyze` sin nuevos warnings** en Rideglory.
3. **Suite y lint de `rideglory-api` verdes** para los specs de la iteración (`vehicles-ms/.../tecnomecanica.service.spec.ts`, `api-gateway/src/scheduler/notification-scheduler.service.spec.ts`, `api-gateway/src/notifications/notifications.service.spec.ts`).
4. Existe un test de `VehicleDocumentExpiry` que verifica los **4 estados** (`none`/`valid`/`expiringSoon`/`expired`) con bordes (30 días, 1 día, "vence hoy"), ejecutado para **ambos `kind`** (SOAT y RTM) y pasando.
5. Existe un **test parametrizado del cubit base** `VehicleDocumentCubit<T>` que cubre `loading → data/empty/error` y el mapeo **404 → `empty`**, validando que SOAT y RTM heredan el mismo comportamiento, y pasa.
6. Los **widgets genéricos compartidos** tienen tests que corren **una sola vez** (no duplicados por feature) y pasan; confirman copy inyectado por parámetro y soporte de N badges.
7. **Regresión SOAT cero verificable**: ningún test SOAT existente cambió su assertion para pasar (si lo hizo, es regresión y se re-enruta a Fase 1).
8. **Verificación manual del doble badge registrada y localizable** en `docs/exec-runs/tecnomecanica-rtm/phase-06-qa-checklist.md`: una fila por combinación de estados SOAT × RTM verificada, con resultado OK o "re-enrutado a Fase N". Sin parpadeo/reflow, sin bloqueo cruzado, mismo alto/spacing entre ambos badges.
9. `docs/features/tecnomecanica.md` **existe** y describe flujos, 4 estados, exención <2 años, recordatorios 30/7/0 y route `rideglory://garage`.
10. `docs/features/soat.md` **actualizado**: refleja que SOAT corre sobre `vehicle_documents/` y el renombrado del modelo duplicado a `VehicleSoatFormData`.
11. `CLAUDE.md` registra la abstracción `vehicle_documents/` y la feature `tecnomecanica/`.
12. **Cero fixes de producto en el diff de la Fase 6**: cualquier bug encontrado está re-enrutado a su fase de origen y registrado, no parcheado aquí.

---

## Pruebas (unitarias/widget/integracion)

- **Unitarias (dominio):** `vehicle_document_expiry_test.dart` — 4 estados × 2 `kind`, fechas controladas, bordes inclusivos/exclusivos del umbral de 30 días y del "vence hoy".
- **Unitarias (presentación):** `vehicle_document_cubit_test.dart` — cubit base parametrizado por `kind`; estados `ResultState`; 404 → `empty`; error de red → `error`.
- **Widget:** `vehicle_document_widgets_test.dart` — render de cada widget genérico compartido una sola vez; verifica inyección de copy por parámetro y ausencia de literales hardcodeados.
- **Integración (manual, registrada):** doble badge en el detalle del vehículo — matriz de estados SOAT × RTM, carga independiente, sin reflow; evidencia en `docs/exec-runs/tecnomecanica-rtm/phase-06-qa-checklist.md`.
- **Backend (verificación, no autoría):** correr `vehicles-ms/src/vehicles/tecnomecanica.service.spec.ts`, `api-gateway/src/scheduler/notification-scheduler.service.spec.ts` y `api-gateway/src/notifications/notifications.service.spec.ts` en `rideglory-api`; deben pasar. Los 3 crons SOAT vivos + 3 crons RTM cubiertos.

---

## Riesgos y mitigaciones

| Riesgo | Mitigación |
|--------|------------|
| Convertir la Fase 6 en una fase-parche (arreglar bugs aquí) que mezcla verificación con fixes. | Criterio de cierre formal: todo bug se re-enruta a su fase de origen y se registra; cero fixes de producto en el diff de la Fase 6 (CA #12). |
| El punto de integración del doble badge falla solo en runtime (no en tests). | Verificación manual obligatoria de la matriz SOAT × RTM, registrada en un checklist localizable del run (CA #8). |
| Tests duplicados por feature inflan la suite y ocultan dónde vive la lógica. | Cubit base y widgets compartidos se prueban **una sola vez** sobre el genérico; el árbol de estados corre parametrizado por `kind`. |
| Un test "verde" porque alguien ajustó la assertion del SOAT. | CA #7: ningún acceptance SOAT existente puede cambiar para pasar; si cambia, es regresión → Fase 1. |
| Rutas de specs backend mal referenciadas (prefijo `apps/` inexistente) hacen la evidencia no verificable. | Rutas ancladas al layout real sin `apps/` (`vehicles-ms/...`, `api-gateway/...`), confirmadas en disco. |
| El spec del scheduler aún no existe al verificar (es de Fase 5). | Si no existe o falla, la Fase 6 queda bloqueada y se re-enruta a Fase 5; no se crea aquí. |

---

## Dependencias (fases prerequisito y por que)

- **Fase 1** — la abstracción `vehicle_documents/` (mixin `VehicleDocumentExpiry`, cubit base, widgets genéricos) es lo que esta fase prueba y documenta. Sin ella no hay objeto de test.
- **Fase 2** — el backend RTM y su `tecnomecanica.service.spec.ts` deben existir y estar verdes para verificarlos.
- **Fase 3** — RTM front (registrar/ver/editar/borrar) debe estar implementada para probar sus 4 estados y el payload DTO.
- **Fase 4** — el doble badge debe estar montado para la verificación manual de integración (punto más frágil).
- **Fase 5** — los crons RTM y su spec deben existir para verificar regresión cero de los 3 crons SOAT y disparo de los 3 RTM.

Es la **última fase**: bloqueante y de cierre. No arranca verificación real hasta que sus prerequisitos están verdes.

---

## Ejecucion recomendada (nivel rg-exec: normal)

**Por qué `normal` y no `lite`:** No introduce comportamiento nuevo, pero es **bloqueante** y cierra el alcance de toda la iteración. Se eleva por encima de `lite` porque:

1. La **verificación de integración de los dos badges juntos** (el punto de acoplamiento más frágil de todo el plan) requiere **QA real** —recorrer la matriz de estados en runtime y registrar evidencia— y no una sola pasada de un implementador.
2. La **regresión cruzada SOAT ↔ RTM en ambos repos** (Flutter + `rideglory-api`) exige correr y razonar sobre dos suites y sus crons, no un check superficial.
3. El **criterio de cierre formal** —re-enrutar cada bug a su fase de origen en vez de parchear— exige **juicio de QA** para clasificar el bug correctamente, algo que `lite` no garantiza.

**Por qué no `full`:** la fase no toca contratos, no hace migraciones y no introduce código de producto; su blast radius es de verificación y documentación. `normal` (QA real + revisión de Tech Lead) cubre el riesgo sin el costo de rondas adversariales de `full`.
