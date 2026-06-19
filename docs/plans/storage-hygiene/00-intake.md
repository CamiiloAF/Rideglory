# 00 — Intake: storage-hygiene

**Timestamp:** 2026-06-19T20:07:56Z
**Slug:** `storage-hygiene`

---

## Fuente

`docs/prds/prd-storage-hygiene.md` — PRD "Higiene de Firebase Storage: borrar archivos huérfanos (vehículos, eventos, SOAT y RTM)"

---

## Objetivo

Garantizar que todo archivo en Firebase Storage tenga dueño vivo: al **reemplazar** o **eliminar** una entidad (vehículo, evento, SOAT, RTM), el archivo anterior en Storage se borra de forma idempotente y tolerante a fallos, sin afectar el flujo de negocio.

---

## Alcance percibido

### Componentes afectados

| Entidad | Campo | Repositorio / UseCase |
|---|---|---|
| Vehículo | `VehicleModel.imageUrl` | `VehicleRepositoryImpl` |
| Evento | cover URL | `EventRepositoryImpl` |
| SOAT | `SoatModel.documentUrl` | `SoatRepositoryImpl` |
| Técnico Mecánica | `TecnomecanicaModel.documentUrl` | `TecnomecanicaRepositoryImpl` |

### Nuevo código core

- `ImageStorageService.deleteByUrl(String url)` — método nuevo, idempotente, tolerante a errores; valida que la URL pertenezca al bucket propio antes de borrar; hace log y continúa si no existe o es URL externa.

### Reglas de negocio clave

- El borrado ocurre **después** de confirmar la persistencia del cambio o eliminación lógica (Storage no puede abortar la operación de negocio).
- Archivar un vehículo **NO** borra su imagen (solo eliminar definitivo lo hace).
- Toda la lógica vive en **capa data** (RepositoryImpl / UseCase), nunca en UI.
- La integración es **app-side** (Firebase Storage SDK), no backend.

### Fases propuestas (del PRD)

1. **Utilidad** — `deleteByUrl` en `ImageStorageService` + tests del parseo URL→ref.
2. **Vehículos** — borrado en update (reemplazo) y delete; respetar archivar.
3. **Eventos** — borrado en update (reemplazo) y delete.
4. **SOAT** — borrado en update (reemplazo) y delete.
5. **Técnico Mecánica / RTM** — borrado en update (reemplazo) y delete.
6. **QA** — tests de caminos, `flutter test` / `dart analyze`, actualizar docs de features afectados.

### Fuera de alcance

- Barrido retroactivo de huérfanos ya existentes.
- Versionado / CDN de imágenes.
- Mover la lógica al backend.

---

## Preguntas abiertas

1. **¿`ImageStorageService` tiene ya algún método de borrado parcial?** Conviene leer el archivo antes de diseñar la firma exacta de `deleteByUrl` para no duplicar helpers internos.
2. **¿Cómo se distingue una URL de "nuestro bucket" vs. externa?** Necesita conocer el bucket name (viene de `.env` / `AppEnv`). Hay que verificar si `AppEnv` expone `storageBucket` o si hay que parsearlo desde la URL del SDK.
3. **Eventos — ¿existe `EventDeleteCubit`/repo con lógica de eliminación de portada ya iniciada?** El PRD lo menciona; revisar el estado actual del `EventRepositoryImpl` para confirmar el punto de integración exacto.
4. **SOAT y RTM — patrón UPSERT:** en `saveSoat`/`saveTecnomecanica`, ¿se recibe la URL anterior como parámetro o hay que leer el registro existente primero para compararla? Determina si la fase necesita un GET previo o si el llamador ya pasa `oldDocumentUrl`.
5. **Tests:** ¿hay mocks de Firebase Storage ya configurados en el proyecto de tests, o hay que crearlos desde cero (e.g., `firebase_storage_mocks`)?
6. **Fase QA / docs:** ¿qué archivos `docs/features/*.md` existen para vehículos, eventos, SOAT y RTM que deban actualizarse al final?
