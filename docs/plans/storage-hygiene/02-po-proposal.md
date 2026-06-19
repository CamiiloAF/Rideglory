# 02 — PO Proposal: storage-hygiene

**Timestamp:** 2026-06-19T20:12:01Z
**Slug:** `storage-hygiene`

---

## Fases propuestas

| # | Título | Goal (valor de negocio) | Resumen |
|---|--------|------------------------|---------|
| 1 | Storage Delete Utility | El equipo tiene una utilidad central, robusta e idempotente para borrar archivos de Firebase Storage sin romper flujos de negocio | Refactorizar `deleteImage` en `ImageStorageService` a `deleteByUrl`: añadir validación de pertenencia al bucket propio, logging explícito en errores, e idempotencia ante 404. Crear tests unitarios con mocks mocktail de `FirebaseStorage`/`Reference`. Este servicio es el cimiento de todas las fases posteriores. |
| 2 | Vehicle Image Cleanup | Al reemplazar o eliminar un vehículo, la imagen anterior desaparece de Storage — sin basura acumulada y sin tocar vehículos archivados | Integrar `deleteByUrl` en `VehicleRepositoryImpl` para los flujos de actualización (reemplazo de imagen) y eliminación permanente. Respetar explícitamente que archivar un vehículo no borra su imagen. Añadir tests de repositorio. |
| 3 | Event Cover Cleanup | Al editar o eliminar un evento, la foto de portada anterior se borra de Storage sin afectar el flujo de creación del organizador | Integrar `deleteByUrl` en `EventRepositoryImpl` para los flujos de actualización (reemplazo de portada) y eliminación de evento. Añadir tests de repositorio. |
| 4 | SOAT Document Cleanup | Al reemplazar o eliminar el SOAT de un vehículo, el documento anterior desaparece de Storage — sin GET extra de red | Extender las interfaces de `SoatRepository` y `SaveSoatUseCase` para recibir `oldDocumentUrl` como parámetro opcional. Integrar `deleteByUrl` en `SoatRepositoryImpl` para save (reemplazo) y delete. Añadir tests de repositorio. |
| 5 | RTM Document Cleanup | Al reemplazar o eliminar la Técnico Mecánica de un vehículo, el documento anterior desaparece de Storage — sin GET extra de red | Extender las interfaces de `TecnomecanicaRepository` y `SaveTecnomecanicaUseCase` para recibir `oldDocumentUrl` como parámetro opcional. Integrar `deleteByUrl` en `TecnomecanicaRepositoryImpl` para save (reemplazo) y delete. Añadir tests de repositorio. |
| 6 | QA & Docs | Todos los flujos de borrado están verificados, el análisis estático pasa limpio y la documentación refleja el comportamiento real | Consolidar helpers de test reutilizables en `test/helpers/` para mocks de Storage. Correr `flutter test` y `dart analyze` con cero errores. Actualizar `docs/features/vehicles.md`, `docs/features/events.md`, `docs/features/soat.md`, `docs/features/tecnomecanica.md`. |

---

## Supuestos

- `AppEnv.firebaseStorageBucket` expone el nombre del bucket y está disponible en la capa de datos para validar pertenencia de URLs antes de borrar.
- La estrategia para SOAT y RTM es **Opción A** (pasar `oldDocumentUrl` como parámetro opcional): el llamador — cubit o use case — ya tiene el modelo en memoria con la URL anterior, por lo que no se requiere un GET adicional de red.
- El borrado de Storage ocurre siempre **después** de confirmar la persistencia del cambio o eliminación en el backend: Storage no puede abortar ni revertir la operación de negocio.
- `VehicleRepositoryImpl` y `EventRepositoryImpl` se refactorizarán para usar `ImageStorageService` (en lugar de `FirebaseStorage` inyectado directamente), consolidando el patrón de upload/delete en un único servicio.
- Archivar un vehículo (`isArchived=true`) es semánticamente distinto a eliminarlo: la imagen se preserva. Esta distinción ya está modelada en dominio y se mantiene sin cambios.
- No existe `firebase_storage_mocks` como dependencia; los tests crean mocks manuales con `mocktail`.
- El cleanup de deuda de `VehicleRepositoryImpl` (body de update construido como `Map<String, dynamic>` en lugar de `.toJson()`) está **fuera del alcance** de este plan y se registra para un cleanup posterior.
- Las fases son puramente de capa de datos; no requieren cambios de UI ni de localization.

---

## Riesgos

- **Borrado prematuro:** si `deleteByUrl` se invoca antes de confirmar que el backend persistió el cambio, se pierde el archivo y el modelo queda inconsistente. Mitigación: garantizar orden estricto — primero el write al API, luego el borrado de Storage.
- **URL de SOAT/RTM no disponible en el llamador:** si el cubit no tiene el modelo cargado en estado cuando dispara save/delete, `oldDocumentUrl` llega como `null` y el borrado se omite silenciosamente (archivo huérfano persiste). Mitigación: el cubit debe asegurarse de cargar el modelo antes de disparar save; documentarlo como precondición en los use cases.
- **URLs pre-creación de evento (upload anónimo):** eventos pueden subir la portada antes de tener `eventId`, generando paths como `events/{timestamp}/cover.jpg`. Si el evento se abandona tras el upload, la imagen queda huérfana fuera del alcance de este plan (barrido retroactivo está explícitamente fuera de alcance).
- **Consistencia en tests sin firebase_storage_mocks:** los mocks manuales con mocktail pueden ser frágiles ante cambios internos del SDK de Firebase Storage. Mitigación: centralizar los mocks en `test/helpers/` para facilitar mantenimiento.
- **Reemplazo parcial de imagen en vehículo sin campo `oldImageUrl` explícito:** si `updateVehicle` recibe el modelo nuevo sin la URL anterior, el repositorio no puede borrar. Mitigación: el use case o el cubit deben obtener el modelo previo y pasarlo como parámetro; definir esto en la firma de la fase.
- **Errores de Storage no deben propagar como fallo de negocio:** un error en `deleteByUrl` (ej. permisos, red) no debe hacer fallar el flujo principal. Mitigación: el método loguea y absorbe la excepción; la operación de negocio ya fue exitosa.

---

## Criterios de éxito globales

- Ningún flujo de reemplazo o eliminación de imagen/documento deja un archivo huérfano en Firebase Storage en condiciones normales de red.
- Archivar un vehículo no borra ningún archivo de Storage.
- `deleteByUrl` es idempotente: invocarla sobre una URL ya borrada o inexistente no lanza error.
- `deleteByUrl` rechaza silenciosamente URLs externas (fuera del bucket propio).
- `flutter test` pasa sin errores en todos los repositorios afectados.
- `dart analyze` no reporta ningún error nuevo introducido por este plan.
- Los docs de features (`vehicles.md`, `events.md`, `soat.md`, `tecnomecanica.md`) describen el comportamiento de borrado de Storage como parte del ciclo de vida de la entidad.
- El barrido retroactivo de huérfanos preexistentes queda explícitamente fuera del alcance y registrado como deuda técnica conocida.
