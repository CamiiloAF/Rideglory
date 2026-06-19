# PRD — Higiene de Firebase Storage: borrar archivos huérfanos (vehículos, eventos, SOAT y RTM)

**Tipo:** Mantenimiento / ahorro de costos (Storage)
**Prioridad:** Media (no bloqueante, pero el free tier es limitado)
**Estimado:** 1–2 iteraciones cortas (~2–3 días)
**Fecha de creación:** 2026-06-04

---

## 1. Problema

Cuando se **reemplaza** la foto de un vehículo, de un evento, o el archivo de un documento legal (SOAT, RTM), o cuando se **elimina** la entidad, el archivo anterior **queda huérfano en Firebase Storage** y nunca se borra. Con el tiempo esto:

- Consume el **free tier de Storage** (Spark ≈ 1 GB almacenado / 10 GB descarga al mes).
- Deja basura imposible de rastrear (URLs sin dueño).

Hoy `ImageStorageService` sube imágenes pero no hay una ruta sistemática que las **borre** al cambiar/eliminar.

---

## 2. Objetivo

Garantizar que todo archivo en Storage tenga dueño vivo: al **reemplazar** o **eliminar**, borrar el objeto anterior.

**Alcance:**
- Foto de **vehículo** (`VehicleModel.imageUrl`).
- Portada de **evento** (`EventModel` cover).
- Foto/escaneo del **SOAT** (`SoatModel.documentUrl`).
- Foto/escaneo de la **Técnico Mecánica / RTM** (`TecnomecanicaModel.documentUrl`).

**No-objetivos:**
- No es un barrido retroactivo de huérfanos ya existentes (se puede hacer como script aparte una vez).

---

## 3. Solución técnica

### 3.1 Utilidad de borrado

Añadir a `ImageStorageService` (core) un método:
```dart
Future<void> deleteByUrl(String url); // resuelve la ref de Storage desde la URL y borra; no-op si no es una URL de nuestro bucket
```
Debe ser **idempotente y tolerante a fallos**: si el objeto no existe o la URL es externa, no rompe el flujo principal (log + continuar).

### 3.2 Puntos de integración

**Vehículos** (`vehicle_repository_impl.dart`)
- **Reemplazo:** en `updateVehicle`, si la imagen cambió (URL nueva ≠ anterior y la anterior es de nuestro bucket) → `deleteByUrl(oldImageUrl)` tras confirmar el guardado.
- **Eliminación:** en `DeleteVehicleUseCase` / repo → borrar `imageUrl` del vehículo antes/después de eliminar el registro.
- *(Archivar no borra la imagen — solo eliminar definitivo.)*

**Eventos** (`event_repository_impl.dart`)
- **Reemplazo:** en el update del evento, si la portada cambió → borrar la anterior.
- **Eliminación:** en `EventDeleteCubit`/repo → borrar la portada.

**SOAT** (`soat_repository_impl.dart`)
- **Reemplazo:** en `saveSoat`, si `documentUrl` cambió (nueva ≠ anterior) → borrar la anterior tras confirmar el guardado. *(SOAT usa UPSERT: no hay método update separado.)*
- **Eliminación:** en `deleteSoat` → borrar `documentUrl` del documento antes de eliminar el registro.

**Técnico Mecánica / RTM** (`tecnomecanica_repository_impl.dart`)
- **Reemplazo:** en `saveTecnomecanica`, si `documentUrl` cambió (nueva ≠ anterior) → borrar la anterior tras confirmar el guardado. *(Mismo patrón UPSERT.)*
- **Eliminación:** en `deleteTecnomecanica` → borrar `documentUrl` del documento antes de eliminar el registro.

> Decisión de capa: el borrado se dispara desde la **capa data (RepositoryImpl/UseCase)**, nunca desde UI. El orden recomendado: primero persistir el cambio/borrado lógico exitoso, luego borrar en Storage (un fallo de Storage no debe abortar la operación de negocio).

### 3.3 Consideración backend vs. app

Las imágenes hoy se suben desde la **app** (`ImageStorageService`, Firebase Storage SDK), así que el borrado natural también vive en la **app**. Si en el futuro la subida/borrado se centraliza en el backend, migrar esta lógica allí. Por ahora: **app**.

---

## 4. Criterios de aceptación

- [ ] `ImageStorageService.deleteByUrl` implementado, idempotente y tolerante a errores (no rompe el flujo).
- [ ] Al reemplazar la foto de un vehículo, la anterior se borra de Storage.
- [ ] Al eliminar un vehículo, su foto se borra de Storage.
- [ ] Al reemplazar la portada de un evento, la anterior se borra.
- [ ] Al eliminar un evento, su portada se borra.
- [ ] Archivar un vehículo NO borra su imagen.
- [ ] Al reemplazar el archivo de SOAT, el anterior se borra de Storage.
- [ ] Al eliminar un SOAT, su archivo se borra de Storage.
- [ ] Al reemplazar el archivo de Técnico Mecánica, el anterior se borra de Storage.
- [ ] Al eliminar una Técnico Mecánica, su archivo se borra de Storage.
- [ ] URLs externas o inexistentes no provocan error (log + continuar).
- [ ] Tests unitarios del parseo URL→ref y de los caminos de borrado (mock de Storage).
- [ ] `dart analyze` sin warnings; `flutter test` al 100%.

---

## 5. Riesgos

| Riesgo | Mitigación |
|---|---|
| Borrar una imagen aún referenciada | Borrar solo tras confirmar persistencia del cambio; comparar URL nueva vs anterior |
| Fallo de red al borrar deja huérfano puntual | Tolerar el fallo (log); un barrido futuro opcional lo recoge |
| URLs que no son de nuestro bucket | `deleteByUrl` valida el host/bucket antes de intentar |

---

## 6. Fuera de alcance (futuro)

- Script de **barrido retroactivo** de huérfanos ya existentes (one-off, comparando objetos de Storage vs. URLs vivas en BD).
- Versionado/CDN de imágenes.

---

## 7. Brief plan (fases)

1. **Utilidad** — `deleteByUrl` en `ImageStorageService` + tests del parseo URL→ref.
2. **Vehículos** — integrar borrado en update (reemplazo) y delete; respetar archivar.
3. **Eventos** — integrar borrado en update (reemplazo) y delete.
4. **SOAT** — integrar borrado en update (reemplazo) y delete.
5. **Técnico Mecánica / RTM** — integrar borrado en update (reemplazo) y delete.
6. **QA** — tests de caminos, `flutter test`/`dart analyze`, actualizar docs de los features afectados.
