# 04 — Plan Review: storage-hygiene

**Timestamp:** 2026-06-19T20:13:30Z
**Slug:** `storage-hygiene`
**Reviewer role:** Plan Reviewer (UX móvil + calidad / Clean Architecture)
**Verdict:** `ok_con_ajustes`

---

## UX por fase

Este plan es puramente de capa de datos y lógica de negocio. No hay pantallas nuevas, no hay flujos de navegación nuevos, y no hay cambios visibles al usuario excepto el efecto silencioso de que los archivos ya no se acumulan en Storage. La sección a continuación cubre los estados observables que sí tocan la capa de presentación y las reglas UX que aplican.

### Fase 1 — Storage Delete Utility

No hay superficie de UI. El cambio ocurre en `ImageStorageService`, un servicio de la capa de datos.

**UX relevante:** ninguna. El método `deleteByUrl` es fire-and-forget y absorbe errores; el usuario nunca ve feedback de él directamente. Correcto por diseño.

**Criterio UX a verificar en QA:** que un error de Storage no conviva con un estado de éxito incorrecto. El cubit ya emitió `ResultState.data` antes de que `deleteByUrl` se llame; si `deleteByUrl` lanza (aunque no debería propagarse), el cubit no debe volver a emitir `loading` ni `error`. La absorción en el servicio garantiza esto — verificarlo en tests.

### Fase 2 — Vehicle Image Cleanup

No hay superficie de UI nueva. Los flujos de reemplazo y eliminación permanente de vehículo ya tienen su UX implementada (`VehicleFormCubit` para edición, `VehicleActionCubit` para eliminación permanente). Este plan solo agrega lógica post-éxito de backend.

**UX relevante:** el flujo de edición de imagen en `VehicleFormCubit` ya tiene el modelo previo disponible en estado (`state.vehicle?.imageUrl` — línea 150 del form cubit). La URL anterior está presente antes del upload del reemplazo. La única precaución de UX: el usuario no debe ver latencia adicional perceptible porque `deleteByUrl` ocurre después de que el backend confirma — el cubit debe emitir `ResultState.data` con el modelo nuevo antes de llamar `deleteByUrl`, no después.

**Regla crítica de orden:** en `VehicleFormCubit`, el flujo es: (1) upload nueva imagen → (2) updateVehicle → (3) emitir `data` con nuevo modelo → (4) deleteByUrl de URL anterior. Si el paso 4 se hace antes del 3, la UI queda bloqueada en `loading` durante el borrado de Storage, lo que es una regresión de UX perceptible.

**Touch targets / estados:** sin cambios. Sin impacto en WCAG.

### Fase 3 — Event Cover Cleanup

Misma arquitectura que vehículos. `EventRepositoryImpl` también tiene `FirebaseStorage` inyectado directamente.

**UX relevante:** el cubit de detalle de evento que dispara `deleteEvent` debe tener el `EventModel` en estado antes de llamar al repositorio. Verificar que la URL de la portada se pasa como parámetro o se lee del modelo previo antes de emitir `loading` — una vez en loading, el estado anterior puede no estar disponible dependiendo de la implementación del cubit.

**Precaución adicional — upload pre-creación:** el plan reconoce el riesgo de uploads anónimos (antes de tener `eventId`). Este riesgo está bien catalogado como fuera de alcance. Sin impacto UX en este plan.

### Fase 4 — SOAT Document Cleanup

Requiere cambios en la firma del dominio: `SoatRepository.saveSoat` y `SaveSoatUseCase` reciben `oldDocumentUrl` opcional.

**UX relevante para save (reemplazo):** `SoatCubit.save()` ya carga el modelo en estado antes de disparar save. En línea 50 del cubit: `_saveSoatUseCase(vehicleId: vehicleId, soat: soat)`. El modelo actual con `documentUrl` anterior está disponible en `state` en ese momento. La fase debe documentar que el llamador (`SoatCubit`) extrae `state.dataOrNull?.documentUrl` como `oldDocumentUrl` antes de emitir `loading` — porque una vez que emite `loading`, el acceso al estado anterior es más frágil si el cubit resetea el estado.

**UX relevante para delete:** `SoatCubit.delete()` línea 73-86 — igual, el modelo está en el estado antes de llamar. Pero el cubit actualmente solo pasa `vehicleId` al use case. Si `DeleteSoatUseCase` necesita `oldDocumentUrl`, la firma del use case y del cubit deben actualizarse; el cubit debe capturar `state.dataOrNull?.documentUrl` **antes** de llamar `emit(loading)`.

**Pattern de captura de URL antes de loading — obligatorio para fases 4 y 5:**
```dart
// Correcto: capturar antes de loading
final oldUrl = state.dataOrNull?.documentUrl;
emit(const ResultState.loading());
final result = await _deleteUseCase(vehicleId, oldDocumentUrl: oldUrl);
```
Este patrón debe quedar explícito en las fases.

### Fase 5 — RTM Document Cleanup

Idéntico a SOAT en arquitectura y precauciones. `TecnomecanicaCubit.delete()` línea 76-88 — misma precaución de capturar URL antes de emit(loading).

**Punto específico:** `TecnomecanicaCubit` no tiene `_getTecnomecanicaUseCase` en su cubit (ver línea 29 — solo `_saveTecnomecanicaUseCase`, `_deleteTecnomecanicaUseCase`, pero sí tiene `_getTecnomecanicaUseCase` en el cubit según el grep, confirmar). Verificar que el modelo esté cargado en estado antes de llamar delete en todos los flujos de entrada a esa pantalla.

### Fase 6 — QA & Docs

No hay UX de usuario. Los mocks de test son infraestructura interna.

**Punto de calidad:** los helpers de test en `test/helpers/` deben ser pure Dart (sin Flutter imports) para respetar la separación de capas incluso en tests.

---

## Gates de calidad (Clean Architecture + coding standards)

### Gate 1 — Capa correcta para deleteByUrl

`deleteByUrl` vive en `ImageStorageService` (capa de datos — `lib/core/services/`). Correcto. El servicio debe inyectarse via `@injectable` y GetIt — ya lo hace. No debe usarse desde la capa de dominio ni desde widgets directamente.

**Verificar:** que `VehicleRepositoryImpl` y `EventRepositoryImpl` migren de `FirebaseStorage` directo a `ImageStorageService` en la inyección. Actualmente ambos inyectan `FirebaseStorage` para upload — el plan propone consolidar. Esta consolidación es obligatoria para no tener dos caminos paralelos de Storage.

### Gate 2 — Validación de bucket en deleteByUrl

El plan requiere validar con `AppEnv.firebaseStorageBucket` antes de borrar URLs externas. Verificar que `AppEnv` es accesible en la capa de datos (es un singleton `@singleton` con envied). No debe pasarse como parámetro al servicio — el servicio lo lee directamente desde `AppEnv`.

**Restricción:** no se puede acceder a `AppEnv` desde dominio. El repositorio (datos) sí puede. Correcto.

### Gate 3 — Firma de dominio (fases 4 y 5)

Cambiar `SoatRepository.saveSoat` y `TecnomecanicaRepository.saveTecnomecanica` para recibir `oldDocumentUrl` es un cambio de interfaz de dominio. La capa de dominio puede recibir `String?` como parámetro sin violaciones — es Dart puro, sin dependencias de Flutter o HTTP. Correcto.

**Verificar:** que `SoatRepositoryImpl` y `TecnomecanicaRepositoryImpl` implementen el parámetro sin exponer `ImageStorageService` en el dominio (el servicio solo se inyecta en el impl, no en la interfaz).

**Anti-patrón a evitar:** no inyectar `ImageStorageService` en `SoatRepository` (la interfaz abstracta). El impl concreto lo recibe via DI, la interfaz no.

### Gate 4 — Orden de operaciones (storage después de persistencia)

El plan menciona esto como riesgo pero no lo eleva a criterio de aceptación formal. Debe ser un criterio verificable en cada test de repositorio:

**Criterio de aceptación técnico obligatorio para fases 2–5:** en todos los tests de repositorio, verificar mediante `verifyInOrder` (mocktail) que `_service.updateX(...)` / `_service.deleteX(...)` se llama **antes** que `imageStorageService.deleteByUrl(...)`.

### Gate 5 — Deuda técnica _vehicleRequest

El scan identifica que `VehicleRepositoryImpl._vehicleRequest` construye un `Map<String, dynamic>` manual, violando el estándar de DTO `.toJson()`. La fase 2 toca `VehicleRepositoryImpl`. El implementador de la fase 2 **no debe reparar esta deuda** (está fuera de alcance declarado), pero tampoco debe agravar el patrón. Verificar que la fase 2 no agrega más claves al map manual.

### Gate 6 — Un widget por archivo / sin métodos que retornen widgets

No aplica — este plan no toca la capa de presentación en sus fases de datos. La única superficie de presentación que se toca son los cubits, que no son widgets. No hay riesgo de violación de la regla de widgets.

### Gate 7 — ResultState en cubits

`SoatCubit` y `TecnomecanicaCubit` extienden `VehicleDocumentCubit<T>` que a su vez usa `ResultState<T>`. Correcto. Las fases 4 y 5 no deben introducir `bool isLoading` auxiliares — la URL anterior debe capturarse del estado antes de emitir loading, no guardarse en un campo separado.

### Gate 8 — Tests con mocktail (sin firebase_storage_mocks)

Los mocks deben estar en `test/helpers/` y ser compartidos entre las fases 2–5. La fase 6 consolida, pero las fases 2–5 crean los mocks incrementalmente. Riesgo: duplicación de mocks entre fases si cada implementador crea los suyos. El plan debe declarar que el primer implementador que cree el mock de `FirebaseStorage`/`Reference`/`TaskSnapshot` lo pone en `test/helpers/` desde la fase 2, y las fases siguientes lo reusan.

---

## Riesgos de scope

### Riesgo 1 — Migración de upload en fases 2 y 3 amplía el scope

La propuesta de migrar `VehicleRepositoryImpl` y `EventRepositoryImpl` de `FirebaseStorage` directo a `ImageStorageService` para unificar el patrón es correcta en teoría, pero amplía la superficie de cambio de las fases 2 y 3. Si el upload falla después de la migración (por diferencias en configuración de `storagePath`, compresión, etc.), el bug no tiene que ver con el cleanup de Storage — sin embargo bloquea el feature completo.

**Mitigación recomendada:** las fases 2 y 3 deben separar explícitamente:
- Sub-tarea A: migrar el upload a `ImageStorageService` (con su propio test de integración).
- Sub-tarea B: agregar `deleteByUrl` en los flujos de update/delete (sobre la base migrada).

Si el tiempo es limitado, la sub-tarea A puede deferirse y las fases 2–3 solo añaden `deleteByUrl` llamando al servicio existente sin migrar el upload — es un compromiso aceptable siempre que el repositorio inyecte `ImageStorageService` (no `FirebaseStorage` crudo) para el delete.

### Riesgo 2 — VehicleActionCubit.permanentlyDeleteVehicle recibe solo vehicleId

El método actual `permanentlyDeleteVehicle(String vehicleId)` no recibe el `VehicleModel` completo. El borrado de la imagen requiere la `imageUrl`. El llamador (`VehicleActionCubit`) recibe el modelo en `archiveVehicle(VehicleModel vehicle)` pero solo el ID en `permanentlyDeleteVehicle`. La fase 2 debe cambiar la firma a `permanentlyDeleteVehicle(VehicleModel vehicle)` o capturar la URL del modelo desde el estado del `VehicleCubit` antes de llamar. Sin este ajuste, el borrado de imagen en eliminación permanente no es factible sin un GET extra de red.

**Esto es un ajuste crítico que el plan no menciona explícitamente** — el implementador debe resolverlo en la fase 2.

### Riesgo 3 — SoatCubit no pasa oldDocumentUrl a delete

`SoatCubit.delete(String vehicleId)` (línea 73) no tiene acceso a la URL del documento en su firma actual. El plan propone `oldDocumentUrl` como parámetro opcional en `DeleteSoatUseCase`, pero el cubit debe capturarlo del estado. Si el estado es `Empty` o `Initial` cuando se llama delete (edge case de doble-tap o race condition), `oldDocumentUrl` será null y el archivo queda huérfano. El plan debe documentar esto como comportamiento aceptado (el archivo no se borra en ese edge case) y no tratar de compensarlo con un GET extra.

### Riesgo 4 — Fase 6 detecta bugs tardíamente

Al separar QA como fase final, los tests de las fases 2–5 se escriben en cada fase pero la integración final se verifica en la fase 6. Si hay un fallo en el orden de operaciones (riesgo de borrado prematuro) que los tests unitarios no cubren por mocking imperfecto de `FirebaseStorage`, se descubre tarde. **Mitigación:** cada fase debe incluir un test de orden (verifyInOrder) — no diferir esto a la fase 6.

### Riesgo 5 — AppEnv.firebaseStorageBucket podría estar vacío en tests

En el entorno de test, `AppEnv` puede fallar al inicializar si no hay `.env` configurado. El método `deleteByUrl` usa el bucket para validar la URL. Si `AppEnv.firebaseStorageBucket` lanza en test, todos los tests del servicio fallan. El implementador de la fase 1 debe considerar pasar el bucket como constructor injection o exponer un override para tests. Verificar cómo `AppEnv` se comporta en tests actualmente.

---

## Ajustes requeridos

### AJ-1 (CRÍTICO) — Cambiar firma de permanentlyDeleteVehicle en el cubit

`VehicleActionCubit.permanentlyDeleteVehicle` debe recibir `VehicleModel` (no solo `String vehicleId`) para tener acceso a `imageUrl`. La firma del use case subyacente puede quedar como `(String id)` — el cubit extrae el id internamente y pasa la URL al repositorio como parámetro adicional. La fase 2 debe documentar y aplicar este cambio de firma.

### AJ-2 (CRÍTICO) — Patrón de captura de URL antes de emit(loading) en fases 4 y 5

Las fases 4 y 5 deben documentar explícitamente que en los cubits afectados (`SoatCubit`, `TecnomecanicaCubit`), la `oldDocumentUrl` se captura del estado **antes** de llamar `emit(const ResultState.loading())`. Este patrón debe quedar en el criterio de aceptación de cada fase, no solo en el riesgo.

### AJ-3 (CRÍTICO) — verifyInOrder en tests de orden de operaciones

Cada fase que llama `deleteByUrl` post-persistencia debe incluir un test de mocktail con `verifyInOrder([serviceCall, deleteByUrlCall])`. No diferir a la fase 6.

### AJ-4 (RECOMENDADO) — Aclarar separación de sub-tareas en fases 2 y 3

Cada una de las fases 2 y 3 debe separar explícitamente: (A) migración de `FirebaseStorage` directo a `ImageStorageService` para los métodos de upload, y (B) integración de `deleteByUrl` en flujos de update/delete. Si el tiempo es limitado, A es diferible pero B requiere que el repositorio inyecte `ImageStorageService`.

### AJ-5 (RECOMENDADO) — Documentar comportamiento de deleteByUrl ante AppEnv en tests

La fase 1 debe verificar cómo se comporta `AppEnv.firebaseStorageBucket` en tests y añadir un mecanismo de override o mock si es necesario. Documentar la solución elegida en el criterio de aceptación de la fase 1.

### AJ-6 (MENOR) — Nota explícita en fases 4 y 5: huérfano en edge case de estado vacío

Las fases 4 y 5 deben documentar como comportamiento conocido y aceptado: si el cubit está en estado `Empty`/`Initial` cuando se llama delete (race condition / doble-tap), `oldDocumentUrl` es null y el archivo de Storage no se borra. No debe compensarse con un GET extra de red — el archivo queda como deuda de basura conocida, cubierta por el disclaimer de barrido retroactivo del plan.

---

## Resumen ejecutivo

El plan está bien fundamentado, el scan es exhaustivo y la propuesta del PO refleja las implicaciones técnicas reales. La separación en 6 fases es apropiada: la utilidad central primero, luego cada feature, QA al final.

Los tres ajustes críticos (AJ-1, AJ-2, AJ-3) no son cambios de diseño sino precisiones de implementación que deben quedar en los criterios de aceptación de las fases correspondientes antes de que el implementador empiece. Sin ellos, la fase 2 puede terminar sin borrar imágenes en eliminaciones permanentes (AJ-1), las fases 4–5 pueden tener race conditions silenciosas (AJ-2), y los tests pueden dar falsos positivos de orden (AJ-3).

No hay impacto en UX visible al usuario. No hay cambios de widget, navegación, ni localization. Los riesgos de scope son gestionables si se aplican los ajustes.
