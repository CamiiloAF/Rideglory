# 04 — Plan Review (UX móvil + Calidad / Clean Architecture) — Tecnomecánica (RTM)

**Slug:** `tecnomecanica-rtm`
**Generado:** 2026-06-04T13:06:35Z
**Rol:** Plan Reviewer (UX móvil + calidad / Clean Architecture)
**Insumos:** `00-intake.md`, `01-scan.md`, `02-po-proposal.md`, código real de `lib/features/soat/**`, `lib/features/vehicles/presentation/garage/widgets/vehicle_soat_card.dart`, mockups `docs/design/html-mockups/iter-2/soat.html`.

> Sesión de planeación. No se modifica código. Veredicto: **ok_con_ajustes**. El fasing es correcto y bien dimensionado; los ajustes son sobre estados de UX por fase, gates de calidad explícitos y un riesgo de scope real en el refactor del cubit genérico (fase 1) y en el formulario de captura (fase 3).

---

## UX por fase

### Fase 1 — Abstracción + refactor SOAT (regresión cero)
- **Sin superficie de UX nueva.** Correcto: el usuario no debe percibir cambio. El único criterio de UX aquí es **paridad pixel/comportamiento**: los 4 estados del badge SOAT, la `SoatValidityCard`, el status page y el flujo de entrada deben verse y comportarse idénticos tras consumir los widgets genéricos.
- **Riesgo de UX oculto:** `vehicle_soat_card.dart` hoy tiene strings **hardcodeados** (`'Vente ${DateFormat...}'`, `'Vigente'`, `'Por vencer'`) y usa `getIt<GetSoatUseCase>()` directo en el widget. Si la fase 1 promueve este card a genérico "tal cual", arrastra la deuda. Debe normalizarse al promoverlo (ver Ajustes A1, A2).
- **Estado idle/loading:** el card actual ya pinta un `CircularProgressIndicator` de 20px mientras carga; el genérico debe preservar ese skeleton/loading por badge para no dejar el detalle en blanco.

### Fase 2 — Backend persistencia RTM
- **Sin UX.** Correcto. Único requisito de cara al frontend: el contrato `GET /tecnomecanica` debe responder **404 → sin documento** igual que SOAT (el repo Flutter mapea 404 → `Right(null)` → `ResultState.empty()`). Si el backend devuelve `200 {data:null}` en vez de 404, rompe la convención `empty` de la fase 3. **Fijar esto en el contrato de la fase 2** (ver A6).

### Fase 3 — Registrar y ver RTM desde la app
Aquí está la mayor superficie de UX. Estados por pantalla (375px):
- **Status page RTM (4 estados):** sin RTM (CTA registrar) / vigente / por vencer / vencido. El mockup SOAT (`iter-2/soat.html` cols 6–8) ya define copy y colores (`badge-success/warning/error`); RTM los reutiliza. Falta definir el **copy específico vencido RTM** (el de SOAT dice "Circular sin SOAT vigente es una infracción" — RTM necesita su propio mensaje legal, no reutilizar el de SOAT literal).
- **Manual capture RTM:** campos `certificateNumber`, `cdaName` (texto libre), `cdaCode?`, `startDate`, `expiryDate`. Estados: idle / validando (fechas: `expiry > start`) / guardando (botón con label "Guardando…", deshabilitado) / error (banner inline, ya existe el patrón en `soat_manual_capture_page`). **No replicar el `Stack` de overlay de escaneo OCR** — RTM no tiene OCR, así que la pantalla es más simple (sin banner autofill, sin "documento no reconocido", sin loading overlay de scan).
- **Nota de exención <2 años:** debe ser **no bloqueante e informativa** (info chip, no error, no impide guardar). UX: aparece cuando `vehicle.purchaseDate`/`year` indica <2 años; copy claro ("Tu moto podría estar exenta de RTM por antigüedad. Verifica con tu CDA."). Touch: no captura tap, es informativa.
- **Empty state** (sin RTM en status page): reutiliza `soat_empty_state` promovido a genérico, con copy RTM.
- **Touch targets:** date pickers, botón confirmar, picker de documento — todos ≥44px (los `AppButton`/`AppDatePicker` ya cumplen). Verificar el botón "cambiar/eliminar documento" en la sección superior.
- **Faltante en la propuesta:** ¿el usuario puede **editar** y **borrar** una RTM ya registrada? El status page SOAT lo permite; la fase 3 menciona "registrar y ver" pero los criterios globales dicen "actualizar y borrar". Confirmar que la fase 3 incluye editar+borrar (DELETE ya está en el contrato de fase 2). Ver A4.

### Fase 4 — Doble badge en detalle del vehículo
- **UX central:** dos cards/badges apilados (SOAT + RTM) en el detalle. El mockup SOAT ya muestra 1 badge con 4 estados; RTM es un segundo idéntico. Verificar **orden vertical** (SOAT primero, RTM debajo) y que ambos respeten el mismo alto/spacing para que el detalle no se vea inconsistente.
- **Cada badge tap-able** hacia su flujo (SOAT → SoatEntryFlow/status; RTM → flujo RTM). Touch target del card completo ≥44px (ya lo es vía `InkWell`).
- **Estado loading independiente por badge:** cada uno carga su documento por separado; uno puede estar `loading` mientras el otro ya tiene `data`. No bloquear el render de SOAT esperando a RTM.
- **Riesgo de UX:** si se mantiene el patrón actual (cada card hace su propio fetch en `initState`), son 2 llamadas de red al abrir el detalle. Aceptable, pero el genérico debe evitar parpadeo/reflow cuando ambos resuelven.

### Fase 5 — Recordatorios push + centro de notificaciones RTM
- **Sin UI nueva** (el centro de notificaciones ya existe y el deep-link `route` ya funciona, confirmado por scan). UX = **copy de las 3 notificaciones** (30d/7d/0d) parametrizado por `kind`. Definir copy RTM distinto del SOAT (mensaje, no solo el documento).
- **Deep-link destino:** SOAT usa `rideglory://garage`. Confirmar que RTM lleve **al detalle de la moto** (criterio global), no al garage genérico — si hoy SOAT cae en garage, RTM debería al menos igualar o mejorar (idealmente detalle del vehículo con el badge RTM visible). Definir el `route` exacto en la fase 5 (ver A5).
- **Estado:** notificación tappable → navega; sin estado de error de UI (el deep-link tiene fallback ya existente).

### Fase 6 — Calidad, regresión, docs
- **Sin UX.** Gate: los 4 estados RTM verificados visualmente, regresión SOAT cero. Añadir verificación manual de los **dos badges** renderizando juntos (es el punto de integración más frágil).

---

## Gates de calidad

Gates bloqueantes que el Tech Lead debe exigir, por fase:

**Transversales (toda fase Flutter):**
- `dart analyze` sin **nuevos** warnings (criterio del intake/PO).
- Clean Architecture: `domain/` sin Flutter/HTTP; `data/` sin `BuildContext`/widgets; `presentation/` sin HTTP directo ni DTO expuesto.
- **Un widget por archivo; cero métodos `Widget _buildX()`.** ⚠️ El `soat_manual_capture_page` actual no tiene métodos que retornan Widget (bien), pero sí tiene lógica pesada inline; el espejo RTM debe extraer cada pieza (nota de exención, sección de campos) a su propio widget.
- **Texto/iconos oscuros sobre primario** (knob, badges sobre naranja). Los badges de estado usan green/warning/error sobre fondo oscuro — OK; vigilar cualquier CTA naranja.
- Switch unificado (`AppSwitch`/`AppSwitchTile`) si aparece alguno (no se espera en RTM).
- Strings vía `context.l10n.<key>` — **cero literales hardcodeados**.

**Fase 1 (el gate más crítico):**
- **Regresión cero SOAT:** toda la suite de tests SOAT existente verde **sin cambiar su acceptance**. Si un test SOAT requiere editar su assertion, es señal de regresión, no de refactor.
- La promoción de widgets a genéricos **debe arreglar**, no arrastrar, los literales hardcodeados de `vehicle_soat_card` (`'Vigente'`, `'Por vencer'`, `'Vence …'`).
- **Eliminar el anti-patrón `getIt<…>()` en widget**: el card genérico debe consumir un cubit `@injectable` vía `BlocProvider`/`context.read`, no `getIt` directo en `initState`.
- `SoatModel implements/extends VehicleDocumentModel` **sin romper Pattern B** (DTO extends Model). Este es el punto técnico que el Architect debe haber cerrado; el Tech Lead verifica que la serialización SOAT sigue intacta.

**Fase 2 (backend):**
- Firebase Auth guard en las 3 rutas `/tecnomecanica`.
- `validateVehicleOwnership` en upsert/find/delete (espejo SOAT).
- Regla `expiry > start` validada server-side.
- **404 en GET cuando no existe** (alinea con `empty` del frontend).
- Migración Prisma: **local → validación humana → remoto** (regla de proyecto). La fase 2 no cierra sin validación humana de la migración.
- `tecnomecanica.service.spec.ts` con casos de upsert/find/delete/expiring.

**Fase 3:**
- `TecnomecanicaModel implements VehicleDocumentModel` + DTO Pattern B; payload de escritura vía `.toJson()` del DTO (regla de memoria "write payloads via DTO toJson", **no** `Map` a mano — el SOAT actual viola esto en su extensión; RTM **no debe replicar** esa deuda).
- Cubit RTM genérico parametrizado por `kind`, `ResultState<T>`, `empty` en 404.
- Eventos analytics `tecnomecanica_*` (snake_case, ≤40 chars).
- Nota de exención: widget propio, no bloqueante.

**Fase 4:**
- El badge genérico **no acopla `vehicles/` a `soat/` ni a `tecnomecanica/`** concretos: parametrizado por `kind` vía usecase/cubit genérico. Si `vehicle_detail` termina importando ambos features concretos, el gate falla.
- Carga independiente por badge (sin bloqueo cruzado).

**Fase 5 (backend):**
- 3 `NotificationType` RTM en **ambos** archivos (`notifications-ms` + `api-gateway`) — checklist explícito (riesgo de desincronización confirmado por scan).
- `sendDocumentExpiryReminders(kind, ...)` genérico sin romper los 3 crons SOAT existentes (regresión cero también aquí).
- Tests de crons con fixtures 30d/7d/0d.

**Fase 6:**
- Test unit de la lógica de estado (4 estados) a nivel `VehicleDocumentModel` con casos SOAT **y** RTM.
- Test parametrizado del cubit genérico por `kind`.
- `flutter test` 100%, `dart analyze` limpio en ambos repos.
- Docs: `tecnomecanica.md`, `soat.md` actualizado, `CLAUDE.md`, endpoint backend.

---

## Riesgos de scope

1. **Fase 1 está sub-dimensionada respecto a la deuda real.** No es "promover widgets tal cual": hay que (a) limpiar literales hardcodeados de `vehicle_soat_card`, (b) eliminar el `getIt` en widget, (c) aislar el `SoatModel`/`SoatDto` **duplicado** en `vehicles/`, (d) reconciliar no-freezed + Pattern B. Es la fase con más riesgo de desborde. **Sugerencia:** que el Architect marque explícitamente qué se generaliza vs. qué se deja como capa fina, para que la fase no se infle.

2. **Frontera fase 3 ↔ acoplamiento del badge (fase 4).** El status page y el flujo de entrada RTM (fase 3) y el badge en el detalle (fase 4) comparten el patrón "genérico parametrizado por kind". Si el genérico no se diseña en fase 1 pensando en N badges, la fase 4 obliga a re-refactorizar. Mitigación: el contrato del genérico (cubit/usecase por `kind`) debe nacer en fase 1, no improvisarse en fase 4.

3. **Editar/borrar RTM ambiguo en fase 3.** Los criterios globales prometen "actualizar y borrar" pero el título de la fase 3 dice solo "registrar y ver". Riesgo de que editar/borrar se cuele a fase 6 o quede sin dueño. Asignarlo explícitamente a fase 3.

4. **OCR-coupling como ruido de copia.** `soat_manual_capture_page` está fuertemente acoplado a OCR (autofill banner, scan overlay, "no reconocido", `ScanSoatUseCase`). Si el espejo RTM se copia mecánicamente, arrastra complejidad muerta. La fase 3 debe partir del genérico **limpio**, no del page SOAT con OCR podado. Riesgo de scope si se intenta "copiar y borrar".

5. **Deep-link destino subespecificado (fase 5).** "Llega al detalle de su moto" vs. SOAT que hoy usa `rideglory://garage`. Si el detalle del vehículo no tiene una ruta deep-linkable por `vehicleId`, la fase 5 esconde trabajo de routing no contabilizado. Verificar que `rideglory://...` resuelve a detalle de vehículo concreto.

6. **Migración Prisma remota bloquea fase 3 contra entorno real.** Bien mitigado por el PO (frontend contra contrato/mock). Mantener esa independencia para que la espera de validación humana no detenga la fase 3.

7. **Copy genérico vs. específico (ARB).** Unificar `document_status_*` tocaría claves SOAT y arriesga regresión. El plan prefiere paralelo (más seguro). Riesgo menor pero hay que decidirlo en fase 1 para no rehacer ARB en fase 3.

---

## Ajustes

- **A1.** Fase 1: al promover el card de badge a genérico, **eliminar literales hardcodeados** (`'Vigente'`, `'Por vencer'`, `'Vence ${DateFormat}'`) moviéndolos a `app_es.arb`. No es opcional: es deuda existente que el refactor debe cerrar, no propagar.
- **A2.** Fase 1: el badge/card genérico debe consumir un **cubit `@injectable` vía `BlocProvider`/`context.read`**, eliminando el `getIt<GetSoatUseCase>()` directo en `initState` del widget actual (anti-patrón confirmado por scan y memoria).
- **A3.** Fase 1: definir en el plan que **el contrato del genérico soporta N badges** (cubit/usecase parametrizado por `kind`) desde el inicio, para que la fase 4 sea capa fina y no un segundo refactor.
- **A4.** Fase 3: declarar explícitamente que incluye **editar y borrar** la RTM (no solo registrar/ver), alineando con los criterios globales y con el DELETE del contrato de fase 2.
- **A5.** Fase 5: especificar el **`route` deep-link exacto** (al detalle del vehículo por `vehicleId`, no al garage genérico) y verificar que esa ruta existe; si no, contabilizar el trabajo de routing.
- **A6.** Fase 2: fijar en el contrato que **GET sin documento responde 404** (no `200 {data:null}`) para preservar la convención `404 → Right(null) → ResultState.empty()` del frontend.
- **A7.** Fase 3: el espejo RTM parte del **genérico limpio sin OCR** (sin autofill banner, sin scan overlay `Stack`, sin "no reconocido", sin `ScanSoatUseCase`), no del `soat_manual_capture_page` podado. Cada pieza de UI (nota de exención, sección de campos) en su propio widget.
- **A8.** Fase 3: el **payload de escritura RTM debe usar `.toJson()` del DTO**, no un `Map` construido a mano (el SOAT viola esto hoy; no replicar la deuda — regla de memoria).
- **A9.** Fase 3: la **nota de exención <2 años** es un widget informativo no bloqueante (info chip), nunca un error ni un gate de guardado; copy en español propio.
- **A10.** Fase 3/5: definir **copy legal propio de RTM vencida** (no reutilizar literal "Circular sin SOAT vigente es una infracción"; RTM tiene su propio régimen).
- **A11.** Fase 4: gate explícito de que `vehicles/` **no importa** `soat/` ni `tecnomecanica/` concretos; solo el contrato genérico `vehicle_documents/`.
- **A12.** Fase 1 y 5: añadir a los criterios de cierre **"regresión cero"** también en el backend (los 3 crons SOAT siguen funcionando tras el helper genérico) y en SOAT widgets (tests SOAT verdes sin tocar acceptance).
