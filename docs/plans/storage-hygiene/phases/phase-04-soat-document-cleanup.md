# Fase 4 — SOAT Document Cleanup

**Timestamp:** 2026-06-19T20:25:14Z
**Plan slug:** `storage-hygiene`
**Nivel rg-exec:** normal

---

## Objetivo

Al reemplazar o eliminar el SOAT de un vehiculo, el documento anterior desaparece de Firebase Storage sin realizar ningun GET extra de red. La URL anterior se captura del estado del cubit (`state.whenOrNull(data: (soat) => soat.documentUrl)`) antes de emitir `loading`, se pasa hacia abajo como parametro opcional en la cadena dominio → datos, y el repositorio lo borra de Storage despues de confirmar la escritura al backend.

---

## Alcance (entra / no entra)

### Entra

- Agregar parametro `String? oldDocumentUrl` a `SoatRepository.saveSoat` (interfaz de dominio).
- Agregar parametro `String? oldDocumentUrl` a `SaveSoatUseCase.call` y propagarlo al repositorio.
- Agregar parametro `String? documentUrl` a `SoatRepository.deleteSoat` (interfaz de dominio).
- Agregar parametro `String? documentUrl` a `DeleteSoatUseCase.call` y propagarlo al repositorio.
- Inyectar `ImageStorageService` en `SoatRepositoryImpl` via constructor DI.
- En `SoatRepositoryImpl.saveSoat`: llamar `unawaited(_imageStorageService.deleteByUrl(oldDocumentUrl))` dentro del closure `function` de `executeService`, inmediatamente despues del `await _soatService.saveSoat(...)` exitoso.
- En `SoatRepositoryImpl.deleteSoat`: mismo patron — `unawaited(...)` dentro del closure `function` despues del `await _soatService.deleteSoat(...)`.
- En `SoatCubit.save`: capturar `final oldUrl = state.whenOrNull(data: (soat) => soat.documentUrl)` **antes** de `emit(const ResultState.loading())` y pasar el valor capturado al use case.
- En `SoatCubit.delete`: capturar `final docUrl = state.whenOrNull(data: (soat) => soat.documentUrl)` **antes** de `emit(const ResultState.loading())` y pasar el valor capturado al use case.
- Tests unitarios del repositorio con `verifyInOrder([soatServiceCall, deleteByUrlCall])`.
- Tests actualizados del cubit que cubren el patron de captura de URL.
- Documentar como comportamiento conocido que si el cubit esta en `Empty`/`Initial` la URL sera null y el archivo no se borra.

### No entra

- Modificaciones al backend (`rideglory-api` / `vehicles-ms`); el contrato HTTP no cambia.
- Migraciones de datos o cambios en Firebase Storage rules.
- Barrido retroactivo de documentos huerfanos preexistentes (deuda tecnica registrada).
- Upload de documentos SOAT (ocurre en `SoatUploadCubit`; fuera de alcance).
- Cambios en la UI de SOAT.
- `deleteByUrl` mismo (implementado en Fase 1; aqui solo se consume).

---

## Que se debe hacer (pasos concretos y ordenados)

Los pasos deben ejecutarse en este orden para respetar la dependencia de compilacion entre capas.

### Paso 1 — Actualizar la interfaz de dominio `SoatRepository`

Modificar `lib/features/soat/domain/repository/soat_repository.dart`:

```dart
Future<Either<DomainException, SoatModel>> saveSoat({
  required String vehicleId,
  required SoatModel soat,
  String? oldDocumentUrl,        // nuevo parametro opcional
});

Future<Either<DomainException, Unit>> deleteSoat(
  String vehicleId, {
  String? documentUrl,           // nuevo parametro opcional nombrado
});
```

### Paso 2 — Actualizar `SaveSoatUseCase`

Modificar `lib/features/soat/domain/usecases/save_soat_usecase.dart`:

- Agregar `String? oldDocumentUrl` como parametro opcional nombrado en `call`.
- Propagarlo a `_repository.saveSoat(...)`.

### Paso 3 — Actualizar `DeleteSoatUseCase`

Modificar `lib/features/soat/domain/usecases/delete_soat_usecase.dart`:

- Agregar `String? documentUrl` como parametro opcional nombrado en `call`.
- Propagarlo a `_repository.deleteSoat(vehicleId, documentUrl: documentUrl)`.

### Paso 4 — Actualizar `SoatRepositoryImpl`

Modificar `lib/features/soat/data/repository/soat_repository_impl.dart`:

1. Agregar `import 'dart:async';` al inicio del archivo (necesario para `unawaited`).
2. Agregar `ImageStorageService` al constructor (DI por injectable; ya es `@injectable`).
3. En `saveSoat`: el borrado ocurre **dentro** del closure `function` de `executeService`, inmediatamente despues del `await _soatService.saveSoat(...)`. Dado que `executeService` solo ejecuta el closure si no lanza, colocar `unawaited` dentro del closure garantiza que el borrado ocurre unicamente en caso de exito del API call:

   ```dart
   @override
   Future<Either<DomainException, SoatModel>> saveSoat({
     required String vehicleId,
     required SoatModel soat,
     String? oldDocumentUrl,
   }) async {
     return executeService(
       function: () async {
         final dto = await _soatService.saveSoat(
           vehicleId,
           soat.toRequestJson(),
         );
         // Solo se llega aqui si saveSoat no lanzo; orden garantizado.
         unawaited(_imageStorageService.deleteByUrl(oldDocumentUrl));
         return dto;
       },
     );
   }
   ```

4. En `deleteSoat`: mismo patron — `unawaited` dentro del closure despues del `await _soatService.deleteSoat(vehicleId)`:

   ```dart
   @override
   Future<Either<DomainException, Unit>> deleteSoat(
     String vehicleId, {
     String? documentUrl,
   }) async {
     return executeService(
       function: () async {
         await _soatService.deleteSoat(vehicleId);
         // Solo se llega aqui si deleteSoat no lanzo; orden garantizado.
         unawaited(_imageStorageService.deleteByUrl(documentUrl));
         return unit;
       },
     );
   }
   ```

**Nota sobre el nombre del metodo `deleteByUrl`:** este metodo es renombrado de `deleteImage` en Fase 1. Si por algun motivo Fase 1 conserva el nombre `deleteImage`, reemplazar `deleteByUrl` por `deleteImage` aqui. La dependencia en el rename es explicita: sin Fase 1 completada con el nuevo nombre, esta fase no compila.

### Paso 5 — Actualizar `SoatCubit`

Modificar `lib/features/soat/presentation/cubit/soat_cubit.dart`:

**En `save`:**
```dart
Future<bool> save({
  required String vehicleId,
  required SoatModel soat,
}) async {
  // CRITICO: capturar ANTES de emit(loading).
  // Despues del emit el estado ya no tiene el modelo anterior.
  // Si el estado es Empty/Initial, oldUrl sera null y el borrado se omite silenciosamente.
  final oldUrl = state.whenOrNull(data: (soat) => soat.documentUrl);
  emit(const ResultState.loading());
  final result = await _saveSoatUseCase(
    vehicleId: vehicleId,
    soat: soat,
    oldDocumentUrl: oldUrl,      // puede ser null — aceptado
  );
  // ... resto igual
}
```

**En `delete`:**
```dart
Future<bool> delete(String vehicleId) async {
  // CRITICO: capturar ANTES de emit(loading).
  // Despues del emit el estado ya no tiene el modelo anterior.
  // Si el estado es Empty/Initial, docUrl sera null y el borrado se omite silenciosamente.
  final docUrl = state.whenOrNull(data: (soat) => soat.documentUrl);
  emit(const ResultState.loading());
  final result = await _deleteSoatUseCase(
    vehicleId,
    documentUrl: docUrl,         // puede ser null — aceptado
  );
  // ... resto igual
}
```

**Atencion:** `ResultState` es una union `freezed`. El idioma correcto para extraer `documentUrl` sin lanzar es `state.whenOrNull(data: (soat) => soat.documentUrl)`, que retorna `null` en cualquier variante distinta de `Data`. No usar `.dataOrNull` salvo que ese getter exista explicitamente en la clase (no esta definido en el repo actualmente).

### Paso 6 — Correr code generation

```bash
dart run build_runner build --delete-conflicting-outputs
# Si falla en entorno fresco, usar:
dart run build_runner build --force-jit --delete-conflicting-outputs
```

No hay clases `@freezed` ni Retrofit nuevos; el code-gen reconstruye solo los archivos de injectable afectados por el cambio de constructor de `SoatRepositoryImpl`.

### Paso 7 — Escribir tests del repositorio

Crear `test/features/soat/data/repository/soat_repository_impl_test.dart`:

- Importar `test/helpers/storage_mocks.dart` (creado en Fase 1).
- Grupo `saveSoat — Storage cleanup`:
  - `verifyInOrder([() => mockSoatService.saveSoat(...), () => mockImageStorageService.deleteByUrl(oldUrl)])` — confirma que el API call ocurre ANTES del borrado.
  - Con `oldDocumentUrl: null` → `deleteByUrl` se llama con null (la utilidad lo ignora silenciosamente).
  - Con `oldDocumentUrl: 'https://...'` y API falla → `deleteByUrl` NO se llama.
- Grupo `deleteSoat — Storage cleanup`:
  - `verifyInOrder([() => mockSoatService.deleteSoat(...), () => mockImageStorageService.deleteByUrl(docUrl)])`.
  - API falla → `deleteByUrl` NO se llama.

### Paso 8 — Actualizar tests del cubit

Modificar `test/features/soat/presentation/cubit/soat_cubit_test.dart`:

- Agregar tests que verifican que `oldDocumentUrl` capturado del estado es pasado al use case (via `verify(... oldDocumentUrl: capturedUrl)`).
- Agregar test: cubit en estado `Empty` al llamar `delete` → use case recibe `documentUrl: null`.
- Actualizar stubs existentes de `mockSaveSoatUseCase` y `mockDeleteSoatUseCase` para aceptar los nuevos parametros opcionales (usar `any(named: 'oldDocumentUrl')` y `any(named: 'documentUrl')`).

### Paso 9 — Verificar lint

```bash
dart analyze
```

Sin errores nuevos. Los tests existentes del cubit deben pasar sin cambios de comportamiento observable.

---

## Archivos a crear/modificar (rutas reales)

| Ruta | Accion | Que cambia |
|------|--------|-----------|
| `lib/features/soat/domain/repository/soat_repository.dart` | Modificar | Agregar `String? oldDocumentUrl` a `saveSoat`; agregar `String? documentUrl` a `deleteSoat` |
| `lib/features/soat/domain/usecases/save_soat_usecase.dart` | Modificar | Propagar `String? oldDocumentUrl` al repositorio |
| `lib/features/soat/domain/usecases/delete_soat_usecase.dart` | Modificar | Propagar `String? documentUrl` al repositorio |
| `lib/features/soat/data/repository/soat_repository_impl.dart` | Modificar | Agregar `import 'dart:async'`; inyectar `ImageStorageService`; llamar `unawaited(deleteByUrl(...))` dentro del closure `function` post-exito en `saveSoat` y `deleteSoat` |
| `lib/features/soat/presentation/cubit/soat_cubit.dart` | Modificar | Capturar URL con `state.whenOrNull(data: ...)` antes de `emit(loading)` en `save` y `delete`; pasar al use case |
| `test/features/soat/data/repository/soat_repository_impl_test.dart` | Crear | Tests unitarios de repositorio con `verifyInOrder` |
| `test/features/soat/presentation/cubit/soat_cubit_test.dart` | Modificar | Actualizar stubs y agregar tests de captura de URL |

---

## Contratos / API rideglory-api

Ninguno. Los endpoints HTTP no cambian:

- `POST /vehicles/{vehicleId}/soat` — mismo contrato; el body no incluye `oldDocumentUrl` (es un parametro interno Flutter, nunca viaja al backend).
- `DELETE /vehicles/{vehicleId}/soat` — mismo contrato.

El backend no gestiona Firebase Storage en ningun endpoint. Las URLs se persisten como strings; el ciclo de vida del archivo en Storage es 100% responsabilidad del cliente Flutter.

---

## Cambios de datos / migraciones

Ninguno. No hay cambios de schema en Firestore, Postgres, ni Firebase Storage rules.

---

## Criterios de aceptacion

1. **[Repositorio - save con reemplazo]** Cuando `SoatRepositoryImpl.saveSoat` se llama con `oldDocumentUrl` no nulo y el API responde con exito, `ImageStorageService.deleteByUrl` es invocado exactamente una vez con ese URL, y el llamado ocurre **despues** del llamado al servicio HTTP (verificado con `verifyInOrder`).

2. **[Repositorio - save sin documento previo]** Cuando `saveSoat` se llama con `oldDocumentUrl: null`, `deleteByUrl` se llama con `null` (la utilidad `deleteByUrl` de Fase 1 lo absorbe silenciosamente; no lanza excepcion).

3. **[Repositorio - save falla]** Cuando el API devuelve error en `saveSoat`, `deleteByUrl` **no** es invocado.

4. **[Repositorio - delete con documento]** Cuando `SoatRepositoryImpl.deleteSoat` se llama con `documentUrl` no nulo y el API responde con exito, `deleteByUrl` es invocado exactamente una vez con ese URL, despues del llamado al servicio HTTP.

5. **[Repositorio - delete falla]** Cuando el API devuelve error en `deleteSoat`, `deleteByUrl` **no** es invocado.

6. **[Cubit - patron de captura]** En `SoatCubit.save`, la URL anterior se extrae con `state.whenOrNull(data: (soat) => soat.documentUrl)` antes de emitir `loading`; el use case recibe el valor que tenia el estado en ese momento, no el valor post-emit.

7. **[Cubit - delete con estado Data]** Cuando el cubit esta en `ResultState.data(data: soat)` al llamar `delete`, `DeleteSoatUseCase` recibe `documentUrl: soat.documentUrl`.

8. **[Cubit - delete con estado Empty]** Cuando el cubit esta en `ResultState.empty()` al llamar `delete`, `DeleteSoatUseCase` recibe `documentUrl: null`. No se realiza ningun GET compensatorio. Comportamiento conocido y aceptado.

9. **[Cubit - save con estado Empty/Initial (creacion)]** Cuando el cubit esta en `Empty` o `Initial` al llamar `save` (alta de nuevo SOAT), `SaveSoatUseCase` recibe `oldDocumentUrl: null`. No se realiza ningun GET compensatorio. Comportamiento conocido y aceptado.

10. **[Sin regresion]** Todos los tests existentes del cubit (`soat_cubit_test.dart`) pasan sin modificar su comportamiento observable.

11. **[Lint]** `dart analyze` no reporta errores ni warnings nuevos introducidos por esta fase.

---

## Pruebas

### Tests unitarios — repositorio (crear)

Archivo: `test/features/soat/data/repository/soat_repository_impl_test.dart`

**Mocks a importar de `test/helpers/storage_mocks.dart` (Fase 1):**
- `MockImageStorageService`

**Grupo `saveSoat`:**
- `verifyInOrder` que el servicio HTTP precede a `deleteByUrl` cuando hay `oldDocumentUrl`.
- `deleteByUrl` llamado con `null` cuando `oldDocumentUrl` es null (no lanza).
- `deleteByUrl` no llamado cuando el API falla.

**Grupo `deleteSoat`:**
- `verifyInOrder` que el servicio HTTP precede a `deleteByUrl` cuando hay `documentUrl`.
- `deleteByUrl` no llamado cuando el API falla.

### Tests unitarios — cubit (modificar)

Archivo: `test/features/soat/presentation/cubit/soat_cubit_test.dart`

**Stubs a actualizar:**
- `mockSaveSoatUseCase`: agregar `any(named: 'oldDocumentUrl')` a la firma del stub.
- `mockDeleteSoatUseCase`: agregar `any(named: 'documentUrl')` a la firma del stub.

**Tests nuevos a agregar:**

- `save() — captura oldDocumentUrl del estado Data antes de emit(loading)`: pre-cargar cubit con soat que tiene `documentUrl = 'gs://...'`, llamar `save()`, verificar que el use case recibio `oldDocumentUrl: 'gs://...'`.
- `save() — pasa oldDocumentUrl: null cuando estado es Empty`: cubit en `Empty`, llamar `save()`, verificar `oldDocumentUrl: null`.
- `delete() — captura documentUrl del estado Data antes de emit(loading)`: pre-cargar cubit con soat con `documentUrl`, llamar `delete()`, verificar que el use case recibio `documentUrl: <url>`.
- `delete() — pasa documentUrl: null cuando estado es Empty`: cubit en `Empty`, llamar `delete()`, verificar `documentUrl: null`.

### Tests de integracion

No aplica para esta fase. El borrado de Storage se prueba con unit tests de repositorio usando mocks.

---

## Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigacion |
|---|--------|-----------|-----------|
| R1 | **Borrado prematuro:** `deleteByUrl` llamado antes de confirmar persistencia en el backend → archivo borrado con modelo inconsistente | Alta | Orden estricto documentado en Paso 4: `unawaited(deleteByUrl(...))` va dentro del closure `function` de `executeService`, despues del `await _soatService.saveSoat/deleteSoat(...)`. Si el servicio lanza, el closure falla antes de llegar a `deleteByUrl` y `executeService` captura el error. Verificado con `verifyInOrder` en tests (CA 1 y CA 4). |
| R2 | **URL anterior no disponible en cubit (estado Empty/Initial):** usuario llega a save/delete sin haber cargado el SOAT → `oldDocumentUrl` es null → archivo queda huerfano | Media | Comportamiento conocido y aceptado (ajuste AJ-6 del plan). La UI debe garantizar que `load()` complete antes de exponer acciones de save/delete. No se compensa con GET. Documentado en comentario de codigo y en CA 8/9. |
| R3 | **Firma de `deleteSoat` cambia de posicional a mixta (posicional + nombrado opcional):** llamadores existentes con `_repository.deleteSoat(vehicleId)` compilaran sin cambios porque `documentUrl` es opcional | Baja | Verificar con `dart analyze` que no quedan llamadas sin compilar. |
| R4 | **`unawaited` fire-and-forget bloquea CI:** si el test espera a que `deleteByUrl` complete y el mock no tiene `thenAnswer`, el test puede colgarse | Baja | Los mocks de `ImageStorageService.deleteByUrl` en tests siempre responden con `thenAnswer((_) async {})` (no lanza, no cuelga). El `storage_mocks.dart` de Fase 1 incluye este setup por defecto. |
| R5 | **build_runner en entorno fresco:** puede fallar por build hooks de `objective_c` | Baja | Usar `--force-jit` o copiar `pubspec.lock` de main (ver MEMORY.md). |
| R6 | **Nombre del metodo `deleteByUrl` depende del rename de Fase 1:** si Fase 1 conserva el nombre `deleteImage` en lugar de renombrarlo a `deleteByUrl`, esta fase no compila | Baja | Prerequisito explicito: Fase 1 debe completarse con el rename. Si por algun motivo el nombre no cambia, reemplazar `deleteByUrl` por `deleteImage` en `soat_repository_impl.dart`. Verificado automaticamente en compilacion. |

---

## Dependencias (fases prerequisito y por que)

| Fase | Titulo | Por que es prerequisito |
|------|--------|------------------------|
| **Fase 1** | Storage Delete Utility | Provee `ImageStorageService.deleteByUrl` (renombrado de `deleteImage`) con validacion de bucket, idempotencia 404, y logging correcto. Esta fase lo consume directamente en `SoatRepositoryImpl`. Tambien provee `test/helpers/storage_mocks.dart` con `MockImageStorageService` que los tests del repositorio importan. Sin Fase 1 completada, `deleteByUrl` no existe y los tests no tienen los mocks necesarios. |

No hay dependencia en Fases 2, 3 ni 5. La Fase 5 (RTM) puede ejecutarse en paralelo con esta fase si se coordinan los merges, pero para simplicidad se serializa despues.

---

## Ejecucion recomendada (nivel rg-exec: normal)

**Nivel: normal**

**Justificacion:** Esta fase toca tres capas de Clean Architecture en cascada:

1. **Dominio:** Cambia dos interfaces abstractas (`SoatRepository`) y dos use cases (`SaveSoatUseCase`, `DeleteSoatUseCase`). Cualquier implementacion del repositorio que no actualice sus firmas rompe en compile time — esto es por diseno, pero requiere que el implementador actualice todas las capas en un solo sweep coherente.

2. **Datos:** Inyecta un nuevo servicio (`ImageStorageService`) en `SoatRepositoryImpl` y agrega logica post-exito dentro del closure `function` de `executeService`. La logica de orden (backend primero, Storage despues) es critica y debe verificarse con `verifyInOrder`. Se requiere importar `dart:async` para `unawaited`.

3. **Presentacion:** El patron de captura de URL en `SoatCubit` es el punto mas fragil: si la captura ocurre despues de `emit(loading)`, el estado anterior ya no esta disponible y `oldDocumentUrl`/`docUrl` siempre sera null. El idioma correcto es `state.whenOrNull(data: (soat) => soat.documentUrl)` — no `state.dataOrNull?.documentUrl`, que no existe en `ResultState`. El auditor debe verificar explicitamente este orden y este idioma en el codigo generado.

El blast radius (dominio + datos + presentacion) y el patron de captura temporal hacen que el nivel `lite` sea insuficiente. El nivel `full` seria excesivo dado que no hay UI nueva ni cambios de contrato con el backend. `normal` provee el nivel de revision adecuado para cambios de interfaz de dominio con patron de captura critico.
