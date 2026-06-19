# Fase 1 — Storage Delete Utility

**Timestamp:** 2026-06-19T20:21:31Z
**Slug:** `storage-hygiene`
**Nivel rg-exec:** lite

---

## Objetivo

Proveer a todo el proyecto una utilidad central, robusta e idempotente para borrar archivos de Firebase Storage a partir de una URL. El método `deleteByUrl` reemplaza al `deleteImage` actual y maneja explícitamente cuatro casos de borde sin propagar errores al flujo de negocio. Los helpers de mocktail que se crean aquí serán importados directamente por las Fases 2–5.

---

## Alcance (entra / no entra)

### Entra

- Refactorizar `ImageStorageService.deleteImage` → `deleteByUrl(String? imageUrl)` con los cuatro casos documentados.
- Crear `test/helpers/storage_mocks.dart` con `MockFirebaseStorage`, `MockReference` y las funciones helper `setupStorageDeleteSuccess`, `setupStorageDeleteNotFound`, `setupStorageDeleteError`.
- Crear `test/core/services/image_storage_service_delete_test.dart` con un test unitario por caso.
- Documentar en el criterio de aceptación la solución para el acceso a `AppEnv.firebaseStorageBucket` en entornos de test.

### No entra

- Integración de `deleteByUrl` en ningún repositorio ni cubit (eso es Fases 2–5).
- Modificar `uploadImage`, `pickImageFromGallery` ni `pickImageFromCamera`.
- Barrido retroactivo de archivos huérfanos preexistentes.
- Cambios en reglas de seguridad de Firebase Storage.
- Cambios en `rideglory-api`.

---

## Que se debe hacer (pasos concretos y ordenados)

1. **Leer el servicio actual** (`lib/core/services/image_storage_service.dart`) para confirmar la firma de `deleteImage` y los imports existentes.

2. **Determinar la estrategia para `AppEnv.firebaseStorageBucket` en tests.** `AppEnv` usa `envied` con `app_env.g.dart` generado desde `.env`. En tests unitarios el archivo generado puede no existir o tener valor `null`. Dos opciones:
   - **Opción A (recomendada):** inyectar el `bucketName` como parámetro de constructor con valor por defecto `AppEnv.firebaseStorageBucket ?? ''`. En tests se instancia `ImageStorageService` pasando un bucket fijo (`'test-bucket.appspot.com'`), sin depender de `AppEnv`. Esto también hace el servicio más testeable en general.
   - **Opción B:** leer `_storage.bucket` (getter del SDK) en lugar de `AppEnv`, que siempre estará disponible en el mock.
   El implementador elige la opción que resulte en tests más limpios y documenta la decisión en un comentario dentro del archivo de test.

3. **Refactorizar `ImageStorageService`:**
   - Añadir el parámetro de constructor (si se elige Opción A) o el getter (Opción B) para la validación de bucket.
   - Renombrar `deleteImage` a `deleteByUrl` con firma `Future<void> deleteByUrl(String? imageUrl)`.
   - Implementar los cuatro casos en orden de evaluación:
     1. `imageUrl` es `null` o vacía → retornar inmediatamente sin log.
     2. `imageUrl` no comienza con `https://firebasestorage.googleapis.com` → retornar inmediatamente sin log.
     3. Llamar `_storage.refFromURL(imageUrl).delete()`. Si la excepción tiene código `object-not-found` → log debug y retornar (idempotente).
     4. Cualquier otro error (red, permisos) → log warning con el código y mensaje, absorber sin propagar.
   - Eliminar el método `deleteImage` obsoleto.

4. **Crear `test/helpers/storage_mocks.dart`:**
   - `class MockFirebaseStorage extends Mock implements FirebaseStorage {}`
   - `class MockReference extends Mock implements Reference {}`
   - `void setupStorageDeleteSuccess(MockFirebaseStorage storage, MockReference ref)` — configura stubs para que `refFromURL(any)` devuelva `ref` y `ref.delete()` devuelva `Future.value()`.
   - `void setupStorageDeleteNotFound(MockFirebaseStorage storage, MockReference ref)` — configura stubs para que `ref.delete()` lance `FirebaseException(plugin: 'storage', code: 'object-not-found')`.
   - `void setupStorageDeleteError(MockFirebaseStorage storage, MockReference ref)` — configura stubs para que `ref.delete()` lance `FirebaseException(plugin: 'storage', code: 'unauthorized', message: 'Permission denied')`.

5. **Crear `test/core/services/image_storage_service_delete_test.dart`** con cuatro grupos de test (uno por caso). Ver sección **Pruebas** para el detalle de cada test.

6. **Verificar** que no quedan referencias a `deleteImage` en el proyecto (`grep -r 'deleteImage' lib/ test/`). Si las hay (Fases 2–5 aún no implementadas), la búsqueda debe arrojar cero resultados — en este punto `deleteImage` no estaba siendo llamado desde ningún sitio, según el scan.

7. **Correr `dart analyze`** y asegurarse de cero errores/warnings nuevos.

8. **Correr `flutter test test/core/services/image_storage_service_delete_test.dart`** — todos los tests deben pasar en verde.

---

## Archivos a crear/modificar (rutas reales, una línea de "que cambia")

| Acción | Ruta | Qué cambia |
|--------|------|------------|
| Modificar | `lib/core/services/image_storage_service.dart` | `deleteImage` → `deleteByUrl(String?)` con los cuatro casos explícitos y validación de bucket; opcionalmente nuevo parámetro de constructor `bucketName`. |
| Crear | `test/helpers/storage_mocks.dart` | `MockFirebaseStorage`, `MockReference` y tres funciones helper reutilizables (`setupStorageDeleteSuccess/NotFound/Error`). |
| Crear | `test/core/services/image_storage_service_delete_test.dart` | Cuatro tests unitarios, uno por caso de borde de `deleteByUrl`. |

---

## Contratos / API rideglory-api

Ninguno. Este cambio es 100% cliente Flutter. El backend no gestiona Firebase Storage en ningún endpoint.

---

## Cambios de datos / migraciones

Ninguno.

---

## Criterios de aceptación (numerados, observables, testeables)

1. **Firma pública:** `ImageStorageService` expone `Future<void> deleteByUrl(String? imageUrl)`. El método `deleteImage` ya no existe en el archivo.

2. **Caso URL null/vacía:** llamar `deleteByUrl(null)` y `deleteByUrl('')` completa sin error y sin llamar a `_storage` (verificable con `verifyNever(() => mockStorage.refFromURL(any()))`).

3. **Caso URL externa:** llamar `deleteByUrl('https://images.unsplash.com/photo-abc')` completa sin error y sin llamar a `_storage`.

4. **Caso 404 / object-not-found:** llamar `deleteByUrl` con una URL del bucket propio cuando el archivo no existe → completa sin lanzar excepción y sin propagar el error. El test verifica que `ref.delete()` fue llamado exactamente una vez.

5. **Caso error de red/permisos:** llamar `deleteByUrl` con una URL del bucket cuando `ref.delete()` lanza `FirebaseException(code: 'unauthorized')` → completa sin lanzar excepción. El test verifica que `ref.delete()` fue llamado exactamente una vez.

6. **Acceso a bucket en test documentado:** el archivo `test/core/services/image_storage_service_delete_test.dart` tiene un comentario en el `setUp` que explica cómo se resuelve `AppEnv.firebaseStorageBucket` en entorno de test (ya sea constructor injection con valor fijo, o uso de `_storage.bucket` del mock). Ningún test depende de que exista el archivo `.env` ni de `app_env.g.dart`.

7. **Helpers reutilizables:** `test/helpers/storage_mocks.dart` existe y exporta `MockFirebaseStorage`, `MockReference`, `setupStorageDeleteSuccess`, `setupStorageDeleteNotFound`, `setupStorageDeleteError`. Cualquier test de las Fases 2–5 puede importar este archivo sin redefinir mocks.

8. **Sin regresiones:** `flutter test` completo pasa en verde. `dart analyze` no introduce errores ni warnings nuevos.

9. **Sin referencias a `deleteImage`:** `grep -r 'deleteImage' lib/ test/` retorna cero resultados.

---

## Pruebas (unitarias/widget/integración)

**Tipo:** unitarias puras (sin Firebase real, sin Flutter widgets).
**Archivo:** `test/core/services/image_storage_service_delete_test.dart`

```
group('ImageStorageService.deleteByUrl', () {

  TC-storage-01: URL null → skip silencioso, storage no es tocado
    - Arrange: MockFirebaseStorage sin stubs
    - Act: await service.deleteByUrl(null)
    - Assert: completes (sin throw); verifyNever(() => mockStorage.refFromURL(any()))

  TC-storage-02: URL vacía → skip silencioso, storage no es tocado
    - Arrange: MockFirebaseStorage sin stubs
    - Act: await service.deleteByUrl('')
    - Assert: completes; verifyNever(() => mockStorage.refFromURL(any()))

  TC-storage-03: URL externa (Unsplash) → skip silencioso, storage no es tocado
    - Arrange: MockFirebaseStorage sin stubs
    - Act: await service.deleteByUrl('https://images.unsplash.com/photo-xyz')
    - Assert: completes; verifyNever(() => mockStorage.refFromURL(any()))

  TC-storage-04: URL del bucket propio, archivo existente → delete() llamado, sin throw
    - Arrange: setupStorageDeleteSuccess(mockStorage, mockRef)
    - Act: await service.deleteByUrl('https://firebasestorage.googleapis.com/v0/b/test-bucket.appspot.com/o/vehicles%2F1%2Fcover.jpg?alt=media')
    - Assert: completes; verify(() => mockRef.delete()).called(1)

  TC-storage-05: URL del bucket propio, archivo no existe (object-not-found) → idempotente, sin throw
    - Arrange: setupStorageDeleteNotFound(mockStorage, mockRef)
    - Act: await service.deleteByUrl('<url-del-bucket-propio>')
    - Assert: completes; verify(() => mockRef.delete()).called(1)

  TC-storage-06: URL del bucket propio, error de permisos → absorbido, sin throw
    - Arrange: setupStorageDeleteError(mockStorage, mockRef)
    - Act: await service.deleteByUrl('<url-del-bucket-propio>')
    - Assert: completes; verify(() => mockRef.delete()).called(1)
});
```

> Nota: TC-storage-03 cubre el caso de portadas generadas por IA (Unsplash) que aparecerá en Fase 3. No requiere test adicional en esa fase para este comportamiento.

---

## Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigación |
|---|--------|-----------|------------|
| R1 | `AppEnv.firebaseStorageBucket` es `null` en entorno de test (`.env` ausente o `app_env.g.dart` no generado) → la validación de bucket nunca rechaza URLs externas | Media | Resolver con constructor injection (Opción A) o `_storage.bucket` (Opción B). El criterio de aceptación CA-6 exige que ningún test dependa de `AppEnv` en tiempo de ejecución. |
| R2 | `FirebaseStorage` y `Reference` son clases del SDK externo; si el SDK cambia la interfaz, los mocks manuales se rompen | Baja | Los mocks están centralizados en `test/helpers/storage_mocks.dart` — un solo archivo a actualizar. La versión del SDK (`firebase_storage: ^13.1.0`) está anclada en `pubspec.yaml`. |
| R3 | `build_runner` falla en entorno fresco por build hooks de `objective_c` | Baja | Esta fase no requiere `build_runner` — no hay nuevas clases `@freezed` ni Retrofit clients. Si se agrega `bucketName` al constructor de `ImageStorageService` (Opción A), `injectable` lo resolverá con el módulo Firebase existente sin regenerar código ya que el valor viene de `AppEnv`, no de un nuevo `@module`. |
| R4 | Confusión entre el prefijo de URL de Storage (`firebasestorage.googleapis.com`) y variantes regionales o de emulador | Baja | Documentar en el código que la validación usa el prefijo estándar. El emulador de Storage usa `localhost` — las URLs del emulador no tienen el prefijo y serán rechazadas silenciosamente. Aceptable en tests unitarios; los tests de integración con emulador están fuera de alcance de este plan. |

---

## Dependencias (fases prerequisito y por qué)

Ninguna. Esta es la fase raíz del plan. Las Fases 2–5 dependen de ella porque `deleteByUrl` y `test/helpers/storage_mocks.dart` deben existir antes de que cualquier repositorio o cubit los utilice.

---

## Ejecución recomendada (nivel rg-exec: lite)

**Nivel:** `lite`

**Por qué este nivel:** cambio mecánico en un único servicio de infraestructura existente (`ImageStorageService`) — refactorizar un método y añadir validaciones de borde. Un solo archivo de producción modificado más dos archivos de test nuevos. Sin contratos de API, sin UI, sin migraciones, sin `build_runner`, sin cambios de firma que afecten capas superiores. Blast radius mínimo (el método `deleteImage` no tiene callers en el momento de ejecutar esta fase). Completamente reversible con un `git revert`.
