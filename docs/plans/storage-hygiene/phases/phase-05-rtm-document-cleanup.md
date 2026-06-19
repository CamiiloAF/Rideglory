# Fase 5 — RTM Document Cleanup

**Plan:** storage-hygiene  
**Timestamp:** 2026-06-19T20:21:39Z  
**Depende de:** Fase 1 (Storage Delete Utility)  
**Nivel rg-exec recomendado:** normal

---

## Objetivo

Al reemplazar o eliminar la Técnico Mecánica (RTM) de un vehículo, el documento anterior desaparece de Firebase Storage sin ningún GET extra de red. El cubit extrae la URL del documento previo del estado en memoria antes de disparar la operación, y la pasa hacia abajo como parámetro opcional. El repositorio ejecuta el borrado de Storage solo tras confirmar que el write al backend fue exitoso.

---

## Alcance (entra / no entra)

**Entra:**
- Agregar `String? oldDocumentUrl` como parámetro opcional a `TecnomecanicaRepository.saveTecnomecanica` y `SaveTecnomecanicaUseCase.call`.
- Agregar `String? documentUrl` como parámetro opcional a `TecnomecanicaRepository.deleteTecnomecanica` y `DeleteTecnomecanicaUseCase.call`.
- Inyectar `ImageStorageService` en `TecnomecanicaRepositoryImpl` y llamar `deleteByUrl` después del write al API exitoso (en el bloque `fold` de éxito).
- Actualizar `TecnomecanicaCubit.save` para extraer `oldDocumentUrl` del estado ANTES de `emit(loading)` y propagarlo al use case.
- Actualizar `TecnomecanicaCubit.delete` para extraer `documentUrl` del estado ANTES de `emit(loading)` y propagarlo al use case.
- Tests unitarios para `TecnomecanicaRepositoryImpl` (repositorio) y actualizaciones a los tests del cubit.
- Documentar como comportamiento conocido y aceptado: si el cubit está en `Empty`/`Initial` al disparar save/delete, `oldDocumentUrl`/`documentUrl` es null y el archivo no se borra (sin GET compensatorio).

**No entra:**
- Barrido retroactivo de documentos huérfanos preexistentes en Storage.
- Cambios en `TecnomecanicaService` (Retrofit client) ni en los endpoints del backend.
- Migración de la lógica de upload de documentos (sigue ocurriendo en la capa de presentación via `SoatUploadCubit` o su equivalente RTM — este plan no mueve esa responsabilidad).
- Cambios en `TecnomecanicaDto`, `CreateTecnomecanicaRequestDto` ni en el serialization/deserialization.
- Cambios en `GetTecnomecanicaUseCase`.
- Cambios de UI/widgets.

---

## Qué se debe hacer (pasos concretos y ordenados)

### Paso 1 — Actualizar la interfaz de dominio `TecnomecanicaRepository`

En `lib/features/tecnomecanica/domain/repository/tecnomecanica_repository.dart`:

1. Agregar `String? oldDocumentUrl` como parámetro nombrado opcional a `saveTecnomecanica`.
2. Agregar `String? documentUrl` como parámetro nombrado opcional a `deleteTecnomecanica`.

Firmas resultantes:

```dart
Future<Either<DomainException, TecnomecanicaModel>> saveTecnomecanica({
  required String vehicleId,
  required TecnomecanicaModel tecnomecanica,
  String? oldDocumentUrl,
});

Future<Either<DomainException, Unit>> deleteTecnomecanica(
  String vehicleId, {
  String? documentUrl,
});
```

### Paso 2 — Actualizar `SaveTecnomecanicaUseCase`

En `lib/features/tecnomecanica/domain/usecases/save_tecnomecanica_usecase.dart`:

Propagar `oldDocumentUrl` desde el `call` al repositorio sin ninguna lógica adicional (dominio no toca Storage).

```dart
Future<Either<DomainException, TecnomecanicaModel>> call({
  required String vehicleId,
  required TecnomecanicaModel tecnomecanica,
  String? oldDocumentUrl,
}) {
  return _repository.saveTecnomecanica(
    vehicleId: vehicleId,
    tecnomecanica: tecnomecanica,
    oldDocumentUrl: oldDocumentUrl,
  );
}
```

### Paso 3 — Actualizar `DeleteTecnomecanicaUseCase`

En `lib/features/tecnomecanica/domain/usecases/delete_tecnomecanica_usecase.dart`:

Propagar `documentUrl` desde el `call` al repositorio.

```dart
Future<Either<DomainException, Unit>> call(
  String vehicleId, {
  String? documentUrl,
}) {
  return _repository.deleteTecnomecanica(vehicleId, documentUrl: documentUrl);
}
```

### Paso 4 — Actualizar `TecnomecanicaRepositoryImpl`

En `lib/features/tecnomecanica/data/repository/tecnomecanica_repository_impl.dart`:

1. Inyectar `ImageStorageService` en el constructor (agregar parámetro; DI sin code-gen extra ya que `ImageStorageService` es `@injectable`).
2. En `saveTecnomecanica`: después del write al API exitoso (en el `Right` del `fold` implícito de `executeService`), llamar `_imageStorageService.deleteByUrl(oldDocumentUrl)` como fire-and-forget.
3. En `deleteTecnomecanica`: después del `await _tecnomecanicaService.deleteTecnomecanica(vehicleId)` exitoso, llamar `_imageStorageService.deleteByUrl(documentUrl)` como fire-and-forget.

Orden de operaciones en `saveTecnomecanica` (crítico — no invertir):
```
1. Construir CreateTecnomecanicaRequestDto con datos del nuevo RTM
2. await _tecnomecanicaService.saveTecnomecanica(vehicleId, requestDto.toJson())  ← backend primero
3. En éxito: unawaited(_imageStorageService.deleteByUrl(oldDocumentUrl))           ← Storage después
4. return dto
```

Orden de operaciones en `deleteTecnomecanica` (crítico — no invertir):
```
1. await _tecnomecanicaService.deleteTecnomecanica(vehicleId)  ← backend primero
2. En éxito: unawaited(_imageStorageService.deleteByUrl(documentUrl))  ← Storage después
3. return unit
```

### Paso 5 — Actualizar `TecnomecanicaCubit`

En `lib/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit.dart`:

En `save`:
1. Capturar `oldDocumentUrl` del estado actual ANTES de `emit(const ResultState.loading())`.
2. Pasar `oldDocumentUrl` al use case.

```dart
Future<bool> save({
  required String vehicleId,
  required TecnomecanicaModel tecnomecanica,
}) async {
  // Capturar URL ANTES de emit(loading) — el estado se pierde con el emit
  final oldDocumentUrl = state.maybeWhen(
    data: (rtm) => rtm.documentUrl,
    orElse: () => null,
  );
  emit(const ResultState.loading());
  final result = await _saveTecnomecanicaUseCase(
    vehicleId: vehicleId,
    tecnomecanica: tecnomecanica,
    oldDocumentUrl: oldDocumentUrl,
  );
  // ... resto del fold sin cambios
}
```

En `delete`:
1. Capturar `documentUrl` del estado actual ANTES de `emit(const ResultState.loading())`.
2. Pasar `documentUrl` al use case.

```dart
Future<bool> delete(String vehicleId) async {
  // Capturar URL ANTES de emit(loading) — el estado se pierde con el emit
  final documentUrl = state.maybeWhen(
    data: (rtm) => rtm.documentUrl,
    orElse: () => null,
  );
  emit(const ResultState.loading());
  final result = await _deleteTecnomecanicaUseCase(
    vehicleId,
    documentUrl: documentUrl,
  );
  // ... resto del fold sin cambios
}
```

### Paso 6 — Escribir tests de repositorio

Crear `test/features/tecnomecanica/data/repository/tecnomecanica_repository_impl_test.dart` usando mocks de `test/helpers/storage_mocks.dart` (creado en Fase 1). Cubrir los casos detallados en la sección de Pruebas.

### Paso 7 — Actualizar tests del cubit

Actualizar `test/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit_test.dart` para:
- Agregar mock de `SaveTecnomecanicaUseCase` con el nuevo parámetro `oldDocumentUrl`.
- Agregar mock de `DeleteTecnomecanicaUseCase` con el nuevo parámetro `documentUrl`.
- Agregar casos que verifican que `oldDocumentUrl`/`documentUrl` se extraen del estado antes del emit.

### Paso 8 — Ejecutar análisis y tests

```bash
dart analyze
flutter test test/features/tecnomecanica/
```

Cero errores nuevos, cero regresiones.

---

## Archivos a crear/modificar (rutas reales)

| Acción | Ruta | Qué cambia |
|--------|------|------------|
| Modificar | `lib/features/tecnomecanica/domain/repository/tecnomecanica_repository.dart` | Agregar `String? oldDocumentUrl` a `saveTecnomecanica` y `String? documentUrl` a `deleteTecnomecanica` |
| Modificar | `lib/features/tecnomecanica/domain/usecases/save_tecnomecanica_usecase.dart` | Propagar `oldDocumentUrl` opcional al repositorio |
| Modificar | `lib/features/tecnomecanica/domain/usecases/delete_tecnomecanica_usecase.dart` | Propagar `documentUrl` opcional al repositorio |
| Modificar | `lib/features/tecnomecanica/data/repository/tecnomecanica_repository_impl.dart` | Inyectar `ImageStorageService`; llamar `deleteByUrl` post-write-exitoso en save y delete |
| Modificar | `lib/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit.dart` | Capturar `oldDocumentUrl`/`documentUrl` del estado ANTES de `emit(loading)`; propagar al use case |
| Crear | `test/features/tecnomecanica/data/repository/tecnomecanica_repository_impl_test.dart` | Tests unitarios del repositorio con `verifyInOrder` y mocks de Storage |
| Modificar | `test/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit_test.dart` | Actualizar firmas de mocks; agregar casos de captura de URL previa al emit |

> `test/helpers/storage_mocks.dart` **no se crea aquí** — lo crea la Fase 1. Esta fase lo importa.

---

## Contratos / API rideglory-api

**Ninguno.** El backend (`vehicles-ms`) no gestiona Firebase Storage. Los endpoints `POST /vehicles/{vehicleId}/tecnomecanica` y `DELETE /vehicles/{vehicleId}/tecnomecanica` no cambian. Solo se agrega lógica del lado cliente después de recibir respuesta exitosa del backend.

---

## Cambios de datos / migraciones

**Ninguno.** El campo `documentUrl` ya existe en `TecnomecanicaModel` y en la base de datos del backend. No se modifica el schema de la BD ni los DTOs de serialización.

---

## Criterios de aceptación (numerados, observables, testeables)

1. **CA-01 — Reemplazo de documento borra el anterior:** al llamar `TecnomecanicaCubit.save(...)` cuando el cubit está en estado `Data` con un RTM que tiene `documentUrl != null` y el nuevo RTM tiene una URL diferente, el documento anterior en Firebase Storage se elimina (sin error de negocio) y el cubit emite `ResultState.data` con el nuevo modelo.

2. **CA-02 — Eliminación del RTM borra el documento:** al llamar `TecnomecanicaCubit.delete(vehicleId)` cuando el cubit está en estado `Data` con `documentUrl != null`, el documento en Firebase Storage se elimina (sin error de negocio) y el cubit emite `ResultState.empty()`.

3. **CA-03 — Backend primero, Storage después:** el call al `TecnomecanicaService` (save o delete) ocurre antes que `deleteByUrl`. Si el backend falla, `deleteByUrl` NO se llama. Verificado con `verifyInOrder` en tests de repositorio.

4. **CA-04 — Captura de URL antes del emit:** el cubit extrae `oldDocumentUrl`/`documentUrl` del estado antes de `emit(const ResultState.loading())`. Si se extrae después, el estado ya es `Loading` y la URL se pierde. Verificado con un test de cubit donde el estado inicial es `Data` con `documentUrl`.

5. **CA-05 — Estado Empty/Initial: oldDocumentUrl null, sin GET:** si el cubit está en estado `Empty`, `Initial`, `Loading` o `Error` cuando se dispara save/delete, `oldDocumentUrl`/`documentUrl` es `null` y `deleteByUrl` no se llama. No se hace ningún GET compensatorio. Comportamiento documentado como aceptado (degradación controlada).

6. **CA-06 — Fallo de Storage no afecta el flujo de negocio:** si `deleteByUrl` lanza una excepción interna (error de red o permisos), el repositorio no la propaga; el cubit ya emitió `ResultState.data`/`empty` correctamente. El fallo se absorbe con logging (responsabilidad de `deleteByUrl` en Fase 1).

7. **CA-07 — Save con mismo documento (URL sin cambio):** si `saveTecnomecanica` se llama con `oldDocumentUrl == tecnomecanica.documentUrl` (misma URL), `deleteByUrl` se llama con esa URL. Esto es aceptable porque `deleteByUrl` maneja el caso de archivo no encontrado idempotentemente (Fase 1). No se debe comparar URLs en el repositorio para evitar lógica adicional.

8. **CA-08 — Sin cambios de contrato de `TecnomecanicaService`:** el Retrofit client no recibe ningún parámetro adicional. Los parámetros nuevos (`oldDocumentUrl`, `documentUrl`) son internos al repositorio y no viajan al backend.

9. **CA-09 — dart analyze sin errores nuevos:** `dart analyze` no reporta warnings ni errores en ninguno de los archivos modificados.

10. **CA-10 — Tests pasan sin regresiones:** `flutter test test/features/tecnomecanica/` verde completo, incluyendo tests previos de cubit (analytics, estados de carga) y los nuevos de repositorio.

---

## Pruebas (unitarias/widget/integración)

### Tests de repositorio (nuevos) — `test/features/tecnomecanica/data/repository/tecnomecanica_repository_impl_test.dart`

Usar `MockImageStorageService` de `test/helpers/storage_mocks.dart` (Fase 1).

| ID | Descripción | Verificación clave |
|----|-------------|-------------------|
| TC-repo-01 | `saveTecnomecanica` exitoso con `oldDocumentUrl` no nula → llama a `deleteByUrl` después del service call | `verifyInOrder([mockTecnomecanicaService.saveTecnomecanica(...), mockImageStorageService.deleteByUrl(oldUrl)])` |
| TC-repo-02 | `saveTecnomecanica` exitoso con `oldDocumentUrl == null` → `deleteByUrl` NO se llama | `verifyNever(() => mockImageStorageService.deleteByUrl(any()))` |
| TC-repo-03 | `saveTecnomecanica` falla (error de red) → `deleteByUrl` NO se llama | `verifyNever(() => mockImageStorageService.deleteByUrl(any()))` |
| TC-repo-04 | `deleteTecnomecanica` exitoso con `documentUrl` no nula → llama a `deleteByUrl` después del service call | `verifyInOrder([mockTecnomecanicaService.deleteTecnomecanica(...), mockImageStorageService.deleteByUrl(docUrl)])` |
| TC-repo-05 | `deleteTecnomecanica` exitoso con `documentUrl == null` → `deleteByUrl` NO se llama | `verifyNever(() => mockImageStorageService.deleteByUrl(any()))` |
| TC-repo-06 | `deleteTecnomecanica` falla (DioException) → `deleteByUrl` NO se llama | `verifyNever(() => mockImageStorageService.deleteByUrl(any()))` |

### Tests de cubit (actualizaciones) — `test/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit_test.dart`

| ID | Descripción | Verificación clave |
|----|-------------|-------------------|
| TC-cubit-08 | `save()` con estado `Data` (RTM con `documentUrl`) → `SaveTecnomecanicaUseCase.call` recibe `oldDocumentUrl` igual al del estado previo | `verify(() => mockSaveUseCase(vehicleId: any, tecnomecanica: any, oldDocumentUrl: 'https://storage.../old-doc.pdf')).called(1)` |
| TC-cubit-09 | `save()` con estado `Empty` → `SaveTecnomecanicaUseCase.call` recibe `oldDocumentUrl: null` | `verify(() => mockSaveUseCase(..., oldDocumentUrl: null)).called(1)` |
| TC-cubit-10 | `delete()` con estado `Data` (RTM con `documentUrl`) → `DeleteTecnomecanicaUseCase.call` recibe `documentUrl` igual al del estado previo | `verify(() => mockDeleteUseCase(any, documentUrl: 'https://storage.../doc.pdf')).called(1)` |
| TC-cubit-11 | `delete()` con estado `Empty` → `DeleteTecnomecanicaUseCase.call` recibe `documentUrl: null` | `verify(() => mockDeleteUseCase(any, documentUrl: null)).called(1)` |

Los tests TC-cubit-01 a TC-cubit-a8 existentes deben seguir pasando con las firmas actualizadas de los mocks.

---

## Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigación |
|---|--------|-----------|------------|
| R1 | **Borrado prematuro:** `deleteByUrl` llamado antes de confirmar éxito del backend → archivo borrado con estado inconsistente | Alta | Orden estricto en el repositorio: backend call primero, `deleteByUrl` solo en bloque de éxito. Verificado con `verifyInOrder` en TC-repo-01 y TC-repo-04. |
| R2 | **URL no disponible (estado Empty/Initial):** si el cubit no tiene el RTM cargado, `oldDocumentUrl` es null y el archivo queda huérfano | Media | Comportamiento aceptado (AJ-6 del plan). Documentado en CA-05. La UI no debe exponer acciones de save/delete sin haber cargado el estado. Sin GET compensatorio. |
| R3 | **Captura de URL después del emit:** si el implementador captura `state.data.documentUrl` después de `emit(loading)`, el estado ya perdió la URL | Media | CA-04 y TC-cubit-08/TC-cubit-10 verifican este patrón explícitamente. El comentario de código documenta el orden requerido. |
| R4 | **`ImageStorageService` no inyectado en TecnomecanicaRepositoryImpl:** el repositorio actual no tiene `ImageStorageService` — si se olvida agregarlo al constructor, el DI falla en runtime | Baja | El test de repositorio (TC-repo-01) falla si `ImageStorageService` no está inyectado. `dart analyze` detecta el parámetro sin usar si se declara pero no se llama. |
| R5 | **build_runner en entornos frescos:** puede fallar por build hooks de `objective_c` | Baja | Usar `--force-jit` o copiar `pubspec.lock` de main (documentado en MEMORY.md). No hay nuevas clases `@freezed` ni Retrofit clients en esta fase. |

---

## Dependencias (fases prerrequisito y por qué)

| Fase | Título | Por qué es prerrequisito |
|------|--------|--------------------------|
| **Fase 1** — Storage Delete Utility | Requerida | Provee `ImageStorageService.deleteByUrl(String? url)` con validación de bucket, idempotencia 404 y logging. Sin este método robusto, `TecnomecanicaRepositoryImpl` no tiene una API segura para borrar. También crea `test/helpers/storage_mocks.dart` que los tests de esta fase importan directamente. |

Las Fases 2, 3 y 4 no son prerrequisito de esta fase. Se ejecutan antes por orden de serialización del plan (para evitar conflictos de merge), pero no existe dependencia técnica entre ellas y Fase 5. Fases 4 (SOAT) y 5 (RTM) son estructuralmente independientes.

---

## Ejecución recomendada (nivel rg-exec: normal)

**Por qué normal:** esta fase es un espejo estructural exacto de Fase 4 (SOAT Document Cleanup), con idéntico nivel de riesgo y complejidad:

1. **Cambios de firma de dominio:** `TecnomecanicaRepository` y ambos use cases reciben nuevos parámetros opcionales. Cualquier error de compilación en capas que implementan la interfaz es capturado por `dart analyze`, pero el blast radius incluye dominio + datos + presentación.

2. **Inyección de servicio en repositorio:** `TecnomecanicaRepositoryImpl` actualmente no inyecta `ImageStorageService`. Agregar un nuevo parámetro al constructor requiere que el implementador verifique que GetIt/injectable lo resuelve correctamente en runtime (no solo en tests).

3. **Patrón crítico de captura antes de emit(loading):** el orden `capturar URL → emit(loading) → llamar use case` es no obvio y propenso a errores de posicionamiento. Un test específico (TC-cubit-08/TC-cubit-10) es necesario para garantizarlo.

4. **verifyInOrder en tests de repositorio:** el orden backend-primero-Storage-después debe verificarse con `verifyInOrder`, no con verificaciones independientes.

Se podría ejecutar en paralelo con Fase 4 si se usan worktrees separados, pero se serializa para evitar conflictos de merge en capas compartidas (por ejemplo, si ambas fases tocaran un archivo común, lo cual no ocurre aquí — pero la serialización es la política del plan para simplificar el proceso).
