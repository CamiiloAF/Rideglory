# PRD — Higiene de Firebase Storage: borrar imágenes huérfanas (vehículos y eventos)

**Tipo:** Mantenimiento / ahorro de costos (Storage)
**Prioridad:** Media (no bloqueante, pero el free tier es limitado)
**Estimado:** 1 iteración corta (~1–2 días)
**Fecha de creación:** 2026-06-04
**Relación:** complementa `prd-ai-event-generation.md` (que ya define la limpieza de las imágenes IA en `pending/`). Este PRD cubre el **ciclo de vida normal** de las imágenes de vehículos y eventos.

---

## 1. Problema

Cuando se **reemplaza** la foto de un vehículo o de un evento, o cuando se **elimina** la entidad, la imagen anterior **queda huérfana en Firebase Storage** y nunca se borra. Con el tiempo esto:

- Consume el **free tier de Storage** (Spark ≈ 1 GB almacenado / 10 GB descarga al mes).
- Deja basura imposible de rastrear (URLs sin dueño).

Hoy `ImageStorageService` sube imágenes pero no hay una ruta sistemática que las **borre** al cambiar/eliminar.

---

## 2. Objetivo

Garantizar que toda imagen en Storage tenga dueño vivo: al **reemplazar** o **eliminar**, borrar el objeto anterior.

**Alcance:**
- Foto de **vehículo** (`VehicleModel.imageUrl`).
- Portada de **evento** (`EventModel` cover).

**No-objetivos:**
- No es un barrido retroactivo de huérfanos ya existentes (se puede hacer como script aparte una vez).
- No cubre imágenes IA en `pending/` (ya las maneja el PRD de IA).

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

> Decisión de capa: el borrado se dispara desde la **capa data (RepositoryImpl/UseCase)**, nunca desde UI. El orden recomendado: primero persistir el cambio/borrado lógico exitoso, luego borrar en Storage (un fallo de Storage no debe abortar la operación de negocio).

### 3.3 Consideración backend vs. app

Las imágenes hoy se suben desde la **app** (`ImageStorageService`, Firebase Storage SDK), así que el borrado natural también vive en la **app**. Si en el futuro la subida/borrado se centraliza en backend (p. ej. junto al `AiModule`), migrar esta lógica allí. Por ahora: **app**.

---

## 4. Criterios de aceptación

- [ ] `ImageStorageService.deleteByUrl` implementado, idempotente y tolerante a errores (no rompe el flujo).
- [ ] Al reemplazar la foto de un vehículo, la anterior se borra de Storage.
- [ ] Al eliminar un vehículo, su foto se borra de Storage.
- [ ] Al reemplazar la portada de un evento, la anterior se borra.
- [ ] Al eliminar un evento, su portada se borra.
- [ ] Archivar un vehículo NO borra su imagen.
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
4. **QA** — tests de caminos, `flutter test`/`dart analyze`, actualizar docs de los features afectados.
