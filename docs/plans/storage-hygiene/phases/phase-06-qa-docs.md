# Fase 6 — QA & Docs

**Timestamp:** 2026-06-19T20:24:54Z
**Slug:** `storage-hygiene`
**Depende de:** Fases 2, 3, 4 y 5
**Nivel rg-exec:** lite

---

## Objetivo

Garantizar que las fases 2–5 entregaron un sistema coherente y sin regresiones: los helpers de test centralizados son completos, la suite pasa limpia, el analizador no reporta errores nuevos, y los cuatro documentos de feature reflejan el ciclo de vida de Storage que ahora existe en el código.

---

## Alcance (entra / no entra)

### Entra

- Verificar que `test/helpers/storage_mocks.dart` expone todos los helpers creados en Fase 1 y requeridos por los tests de Fases 2–5: `MockFirebaseStorage`, `MockReference`, `setupStorageDeleteSuccess()`, `setupStorageDeleteNotFound()`, `setupStorageDeleteError()`.
- Correr `flutter test` y confirmar que no hay tests fallidos ni regresiones respecto al estado anterior al plan.
- Correr `dart analyze` y confirmar que no hay errores nuevos introducidos por las fases 2–5 (warnings pre-existentes no cuentan).
- Documentar el gotcha de build_runner (`--force-jit` / `pubspec.lock`) si el CI corre en entorno fresco.
- Actualizar `docs/features/vehicles.md` — sección de ciclo de vida de imagen.
- Actualizar `docs/features/events.md` — sección de ciclo de vida de portada.
- Actualizar `docs/features/soat.md` — sección de ciclo de vida de documento.
- Actualizar `docs/features/tecnomecanica.md` — sección de ciclo de vida de documento.

### No entra

- Barrido retroactivo de archivos huérfanos preexistentes en Firebase Storage (deuda técnica conocida, fuera del plan completo).
- Cambios de código de producción de ningún tipo.
- Nuevos tests más allá de verificar que los existentes pasen.
- Documentar features distintos a los cuatro listados.
- Modificar reglas de seguridad de Firebase Storage.

---

## Que se debe hacer (pasos concretos y ordenados)

### Paso 1 — Verificar completitud de `test/helpers/storage_mocks.dart`

Abrir el archivo y confirmar que contiene exactamente los siguientes elementos. Las firmas deben coincidir con las definidas en la Fase 1:

1. `class MockFirebaseStorage extends Mock implements FirebaseStorage` — mock principal del SDK.
2. `class MockReference extends Mock implements Reference` — mock de referencia de Storage.
3. `void setupStorageDeleteSuccess(MockFirebaseStorage storage, MockReference ref)` — configura el stub `when(() => storage.refFromURL(any())).thenReturn(ref)` y `when(() => ref.delete()).thenAnswer((_) => Future.value())`.
4. `void setupStorageDeleteNotFound(MockFirebaseStorage storage, MockReference ref)` — configura `when(() => storage.refFromURL(any())).thenReturn(ref)` y `when(() => ref.delete()).thenThrow(FirebaseException(plugin: 'storage', code: 'object-not-found'))`. **El plugin es `'storage'`, no `'firebase_storage'`** — usar el valor exacto de Fase 1 (línea 57) para que los tests de verificación no fallen por discrepancia de cadena.
5. `void setupStorageDeleteError(MockFirebaseStorage storage, MockReference ref)` — configura `when(() => storage.refFromURL(any())).thenReturn(ref)` y `when(() => ref.delete()).thenThrow(FirebaseException(plugin: 'storage', code: 'unauthorized', message: 'Permission denied'))`.

**Nota sobre `refFromURL`:** el stub `when(() => storage.refFromURL(any())).thenReturn(ref)` se configura **dentro** de cada función helper (`setupStorageDeleteSuccess`, `setupStorageDeleteNotFound`, `setupStorageDeleteError`), no como un helper independiente. Si alguna Fase 2–5 declaró un stub de `refFromURL` por separado fuera de los helpers, consolidarlo dentro del helper correspondiente.

Si alguno de estos elementos falta o tiene firma incorrecta, corregirlo en este mismo archivo (no crear otro).

### Paso 2 — Correr `flutter test`

```bash
flutter test
```

Confirmar salida limpia (todos los tests pasan). Si hay fallos, identificar si son regresiones introducidas por las fases anteriores o tests preexistentes que ya fallaban (documentar cualquier hallazgo antes de continuar).

### Paso 3 — Correr `dart analyze`

```bash
dart analyze
```

Confirmar que no hay errores (`error`) nuevos. Los warnings (`warning`) o infos pre-existentes se ignoran. Si hay errores nuevos originados en cambios de Fases 2–5, registrarlos en este documento con su ruta y descripción — no corregir código de producción en esta fase.

Si las fases anteriores modificaron archivos DI (`@Injectable`) y `build_runner` no se ejecutó, correr primero:

```bash
dart run build_runner build --delete-conflicting-outputs
# En entorno fresco (worktree / CI):
dart run build_runner build --delete-conflicting-outputs --force-jit
```

### Paso 4 — Actualizar `docs/features/vehicles.md`

Localizar la sección de archivado/borrado (§8 "Archivado y borrado") y agregar una subsección "Ciclo de vida de imagen en Storage" con:

- **`updateVehicle` con imagen nueva:** la imagen anterior se borra de Firebase Storage via `ImageStorageService.deleteByUrl(oldImageUrl)` en `VehicleFormCubit._saveExistingVehicle`, después de que el backend confirma el update (bloque de éxito del `fold`). La UI recibe `ResultState.data` antes del borrado (fire-and-forget). Nota: el servicio expone `deleteByUrl` — renombrado desde `deleteImage` en Fase 1 del plan storage-hygiene.
- **`permanentlyDeleteVehicle`:** la imagen se borra de Storage en `VehicleActionCubit` después del delete exitoso. La firma del método recibe `VehicleModel` (no solo `vehicleId`) para tener acceso a `imageUrl`.
- **`archiveVehicle` (`isArchived=true`):** la imagen **no** se borra. El archivado es semántico; el modelo conserva `imageUrl` intacta.
- **Precondición:** `deleteByUrl` ignora silenciosamente URLs `null`, vacías, o externas al bucket de Firebase Storage propio (por ejemplo, portadas de Unsplash).

### Paso 5 — Actualizar `docs/features/events.md`

Agregar o actualizar la sección de gestión de portada con "Ciclo de vida de portada en Storage":

- **`updateEvent` con nueva portada:** la portada anterior se borra de Storage en el cubit de evento después del update exitoso, via `ImageStorageService.deleteByUrl(oldImageUrl)`. Nota: el método es `deleteByUrl`, renombrado desde `deleteImage` en storage-hygiene Fase 1.
- **`deleteEvent`:** la portada se borra de Storage en el cubit después del delete exitoso al backend.
- **Portadas generadas por IA (Unsplash):** `deleteByUrl` las rechaza silenciosamente (URL externa, no pertenece al bucket). No hay archivo en Firebase Storage que borrar.
- **Upload pre-creación** (`events/{ownerId}-{timestamp}/cover.jpg` antes de que exista `eventId`): si el evento se abandona, la imagen queda huérfana. Registrado como deuda técnica conocida; fuera del alcance del plan storage-hygiene.

### Paso 6 — Actualizar `docs/features/soat.md`

Agregar o actualizar la sección de subida del documento con "Ciclo de vida de documento en Storage":

- **`saveSoat` (upsert) con nuevo documento:** si el SOAT ya existía con `documentUrl` distinta, el repositorio (`SoatRepositoryImpl`) borra el documento anterior de Storage via `ImageStorageService.deleteByUrl(oldDocumentUrl)` después del save exitoso. El cubit extrae `oldDocumentUrl` del estado **antes** de llamar al use case (antes de `emit(loading)`) y lo pasa como parámetro opcional. Nota: el método de servicio usado es `deleteByUrl` (nombre introducido en storage-hygiene Fase 1, no el `deleteImage` que podía estar presente en el código anterior).
- **`deleteSoat`:** el repositorio borra el documento de Storage después del DELETE exitoso al backend. El cubit pasa `documentUrl` del estado como parámetro opcional.
- **Edge case `Empty` / `Initial`:** si el cubit no tiene el modelo cargado cuando se dispara save o delete, `oldDocumentUrl` llega como `null` y el borrado se omite silenciosamente. El archivo eventualmente queda huérfano. Comportamiento conocido y aceptado (degradación controlada sin GET compensatorio).
- **Precondición de UI:** las acciones de save y delete solo deben estar disponibles en UI cuando `state is Data`. Si el estado es `Empty` o `Error`, la UI no debe exponer dichas acciones — esto es lo que garantiza que `oldDocumentUrl` siempre sea válida en el flujo normal.

### Paso 7 — Actualizar `docs/features/tecnomecanica.md`

Agregar o actualizar la sección equivalente con "Ciclo de vida de documento en Storage" con la misma estructura que el Paso 6, reemplazando referencias a `SoatRepositoryImpl` / `saveSoat` / `deleteSoat` por sus equivalentes RTM (`TecnomecanicaRepositoryImpl` / `saveTecnomecanica` / `deleteTecnomecanica`):

- **`saveTecnomecanica` (upsert) con nuevo documento:** el repositorio (`TecnomecanicaRepositoryImpl`) borra el documento anterior via `ImageStorageService.deleteByUrl(oldDocumentUrl)` después del save exitoso. El cubit extrae `oldDocumentUrl` del estado antes de `emit(loading)` y lo pasa como parámetro opcional. El nombre del método de servicio es `deleteByUrl` (storage-hygiene Fase 1).
- **`deleteTecnomecanica`:** el repositorio borra el documento de Storage después del DELETE exitoso. El cubit pasa `documentUrl` del estado como parámetro opcional.
- **Edge case `Empty` / `Initial`:** idéntico a SOAT — si el cubit no tiene el modelo cargado, `oldDocumentUrl` llega como `null` y el borrado se omite silenciosamente. Degradación controlada aceptada.
- **Precondición de UI:** las acciones de save y delete solo deben estar disponibles en UI cuando `state is Data`, igual que en SOAT. Esto garantiza que `oldDocumentUrl` sea válida en el flujo normal.

### Paso 8 — Verificar build_runner en entorno fresco (si aplica)

Si se ejecuta en un worktree o entorno CI fresco, verificar:

```bash
# Si build_runner falla con hooks de objective_c:
dart run build_runner build --delete-conflicting-outputs --force-jit
# O copiar pubspec.lock de main antes de correr build_runner
cp ../main-worktree/pubspec.lock .
dart run build_runner build --delete-conflicting-outputs
```

Este gotcha está documentado en el MEMORY.md del proyecto. No requiere cambios de código.

---

## Archivos a crear/modificar (rutas reales, una línea de "que cambia")

| Ruta | Acción | Qué cambia |
|------|--------|------------|
| `test/helpers/storage_mocks.dart` | Verificar / completar | Asegurar firmas de dos argumentos en los tres helpers (`MockFirebaseStorage storage, MockReference ref`); confirmar que el plugin en `setupStorageDeleteNotFound` es `'storage'` (no `'firebase_storage'`); agregar los elementos que falten |
| `docs/features/vehicles.md` | Modificar | Agregar subsección "Ciclo de vida de imagen en Storage" en §8 con los tres flujos (update, permanentDelete, archive) y la distinción fire-and-forget |
| `docs/features/events.md` | Modificar | Agregar subsección "Ciclo de vida de portada en Storage" con los flujos update/delete, la exención de portadas Unsplash y el upload huérfano como deuda técnica |
| `docs/features/soat.md` | Modificar | Agregar subsección de ciclo de vida: save-con-reemplazo, deleteSoat, edge case estado Empty, precondición de UI |
| `docs/features/tecnomecanica.md` | Modificar | Espejo de soat.md para RTM: mismos flujos, mismas precondiciones de UI, misma nota de degradación controlada |

---

## Contratos / API rideglory-api

Ninguno. Esta fase no toca ningún contrato de backend. El backend no gestiona Firebase Storage.

---

## Cambios de datos / migraciones

Ninguno.

---

## Criterios de aceptacion (numerados, observables, testeables)

1. `test/helpers/storage_mocks.dart` existe y contiene `MockFirebaseStorage`, `MockReference`, `setupStorageDeleteSuccess(MockFirebaseStorage storage, MockReference ref)`, `setupStorageDeleteNotFound(MockFirebaseStorage storage, MockReference ref)` y `setupStorageDeleteError(MockFirebaseStorage storage, MockReference ref)` con sus firmas de dos argumentos. Ninguno de estos elementos está duplicado en archivos de test individuales de las fases 2–5.

2. El plugin en `FirebaseException` dentro de `setupStorageDeleteNotFound` es el string `'storage'` (no `'firebase_storage'`), coincidiendo con la implementación de Fase 1.

3. `flutter test` termina con 0 tests fallidos. Si hay fallos, están documentados como preexistentes (no introducidos por las fases del plan).

4. `dart analyze` termina con 0 errores nuevos (`error`). Los warnings/infos preexistentes no bloquean.

5. `docs/features/vehicles.md` contiene una sección que describe explícitamente: (a) update borra Storage post-éxito via `ImageStorageService.deleteByUrl`, (b) permanentDelete borra Storage post-éxito con el `VehicleModel` completo como parámetro, (c) archive NO borra Storage.

6. `docs/features/events.md` contiene una sección que describe: (a) update borra portada anterior post-éxito, (b) delete borra portada post-éxito, (c) portadas Unsplash exentas (skip silencioso), (d) upload pre-creación como deuda técnica conocida.

7. `docs/features/soat.md` contiene una sección que describe: (a) save con reemplazo borra documento anterior via repositorio, (b) delete borra documento via repositorio, (c) edge case estado `Empty`/`Initial` → `oldDocumentUrl` null → skip silencioso, (d) precondición de UI explícita: acciones de save/delete solo disponibles cuando `state is Data`.

8. `docs/features/tecnomecanica.md` contiene la misma estructura que `soat.md` (criterio 7) con las referencias correctas a RTM, incluyendo la precondición de UI: acciones de save/delete solo disponibles cuando `state is Data`.

9. Ningún archivo de código de producción (bajo `lib/`) fue modificado en esta fase.

---

## Pruebas (unitarias/widget/integración)

Esta fase no agrega tests nuevos. Los tests relevantes ya fueron escritos en las fases anteriores:

- **Fase 1:** tests unitarios de `ImageStorageService.deleteByUrl` cubriendo los cuatro casos (null, URL externa, 404, error de red) en `test/core/services/image_storage_service_delete_test.dart`.
- **Fases 2–5:** tests de repositorios y cubits con `verifyInOrder([backendCall, deleteByUrlCall])` por flujo de update y delete.

La verificación en esta fase es de completitud: asegurar que `test/helpers/storage_mocks.dart` no tiene huecos que obliguen a duplicación en tests individuales, y que `flutter test` pasa la suite completa.

---

## Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigacion |
|---|--------|-----------|------------|
| R1 | `flutter test` detecta fallos pre-existentes no relacionados con el plan; el agente los escala como si fueran regresiones | Baja | Antes de correr la suite, comparar con el estado de `main` antes del plan. Si los fallos existían antes, documentarlos y no bloquear la fase. |
| R2 | `dart analyze` reporta errores en imports generados (`.g.dart`) por `build_runner` no re-ejecutado después de Fases 2–5 | Baja | Correr `dart run build_runner build --delete-conflicting-outputs` antes del analyze si hay archivos DI modificados. En entorno fresco usar `--force-jit`. |
| R3 | `test/helpers/storage_mocks.dart` tiene helpers con firma de un solo argumento (solo `MockReference ref`) en lugar de los dos argumentos correctos (`MockFirebaseStorage storage, MockReference ref`), causando que la verificación de completitud de este Paso 1 reporte una discrepancia aunque los tests de Fases 2–5 pasen localmente con sus propios stubs | Media | El Paso 1 de esta fase detecta y corrige las firmas. La fuente de verdad son las firmas definidas en Fase 1 (líneas 56–58 de `phase-01-storage-delete-utility.md`). |
| R4 | El plugin string en `setupStorageDeleteNotFound` es `'firebase_storage'` en lugar de `'storage'`, causando que los tests que verifican el código del error no capturen el `FirebaseException` como esperado | Media | El Paso 1 ítem 4 exige verificar y corregir el valor al string `'storage'`. Un test que pase con el plugin incorrecto puede dar falso positivo si el catch es genérico — verificar que el catch en `deleteByUrl` filtra por `code` y no por `plugin`. |
| R5 | Los docs de features tienen estructura diferente entre sí; la sección "ciclo de vida" no tiene un lugar obvio donde insertarse | Baja | Insertar al final de la sección más cercana al tema (upload/borrado) o crear subsección nueva. No reorganizar secciones existentes. |
| R6 | Confusión entre `deleteByUrl` (nombre introducido en Fase 1) y `deleteImage` (nombre anterior, ya eliminado) en la redacción de los docs | Baja | Los pasos 4–7 incluyen una nota explícita indicando que el método de servicio es `deleteByUrl`. El redactor debe verificar que `grep -r 'deleteImage' lib/` retorne cero resultados antes de documentar. |

---

## Dependencias (fases prerequisito y por que)

| Fase | Titulo | Por que es prerequisito |
|------|--------|------------------------|
| 2 | Vehicle Image Cleanup | Los tests de `VehicleFormCubit` y `VehicleActionCubit` deben existir para que `flutter test` los ejecute; los docs de vehicles deben describir el comportamiento ya implementado. |
| 3 | Event Cover Cleanup | Los tests de `EventRepositoryImpl` y el cubit de evento deben existir; los docs de events deben describir el comportamiento ya implementado. |
| 4 | SOAT Document Cleanup | Los tests de `SoatRepositoryImpl` con firmas actualizadas deben existir; el doc de soat.md describe el comportamiento implementado. |
| 5 | RTM Document Cleanup | Los tests de `TecnomecanicaRepositoryImpl` con firmas actualizadas deben existir; el doc de tecnomecanica.md describe el comportamiento implementado. |

Esta fase no puede ejecutarse parcialmente sobre un subconjunto de fases previas: requiere que las cuatro estén completas para que `flutter test` sea representativo y los docs sean coherentes.

---

## Ejecucion recomendada (nivel rg-exec: lite)

**Nivel:** `lite`

**Por que lite:** sin cambios de producción. Solo verificación de completitud de helpers de test, ejecución de suite existente y actualización de cuatro archivos de documentación. Sin riesgo de regresión. Bajo blast radius.

Las únicas modificaciones son:

1. Verificación y posible corrección de firmas en `test/helpers/storage_mocks.dart` (un archivo de test auxiliar, no código de producción).
2. Ejecución de comandos de validación (`flutter test`, `dart analyze`).
3. Edición de cuatro archivos de documentación en `docs/features/`.

No hay lógica de negocio que pueda regresar, no hay cambios de firmas ni de DI, no hay UI, no hay contratos de API. El blast radius es mínimo: el peor caso es que un doc quede mal redactado o que un helper tenga firma incorrecta, ambos corregibles sin impacto en la app en producción.
