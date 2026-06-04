# PRD — Generación de descripción e imagen de evento con IA (chat interactivo, gratis)

**Tipo:** Feature (frontend Flutter + backend `rideglory-api`)
**Prioridad:** Media-alta (diferencial de producto en el alta de eventos)
**Estimado:** 1–2 iteraciones (backend + app)
**Fecha de creación:** 2026-06-04
**Reemplaza:** el flujo actual `/events/generate-cover` (Claude → Unsplash).

---

## 1. Problema

Al crear un evento, el organizador enfrenta una página en blanco para la **descripción** y depende de subir una **portada** propia. Hoy existe `/events/generate-cover`, pero:

- **No genera imágenes con IA:** `ClaudeService.generateSearchQuery` arma un query y **Unsplash** devuelve una **foto de stock** genérica (no es *tu* rodada).
- **Tiene costo:** la llamada a Claude (Anthropic) cuesta, aunque sea poco.
- **No hay asistencia para la descripción.**

Queremos que el organizador **converse con una IA** para generar tanto la **descripción** (texto enriquecido) como la **portada** (imagen única 16:9), **sin costo para el dev**.

---

## 2. Objetivo

Dos asistentes de IA tipo **chat interactivo** en el formulario de evento:

1. **Descripción:** el usuario escribe lo que quiere; la IA genera texto enriquecido (negritas, listas) que cae en el editor Quill existente. Puede refinar por chat ("más corta", "menciona que es ruta de montaña").
2. **Portada:** el usuario describe la imagen; la IA genera una imagen 16:9. Puede pedir variaciones (nueva imagen) o, con palabras de edición explícitas, editar la imagen vigente. Visor full screen. "Usar esta imagen" la fija como portada.

**Requisito duro: 100% gratuito.** Proveedor único **Google Gemini Developer API (free tier)** para texto e imagen.

**No-objetivos:**
- No se usa Firebase AI Logic / client-side (decisión: todo en backend).
- No se conserva Unsplash ni el query con Claude (se eliminan).
- No se persiste el historial de chat en el servidor (stateless por request).

---

## 3. Solución técnica — Backend (`rideglory-api`)

### 3.1 Arquitectura

- **`AiModule` (NestJS) dentro del `api-gateway`** — donde hoy vive `generate-cover`. Fronteras limpias para poder **extraerlo a un `ai-ms` dedicado** más adelante sin reescribir (hoy un ms aparte sería over-engineering + costo de RAM en EC2).
- **`GeminiService`** análogo al `ClaudeService` existente: cliente `@google/genai`, key `GEMINI_API_KEY` en `.env` (de Google AI Studio), métodos:
  - `generateEventDescription({ userPrompt, history, eventContext })` → Markdown.
  - `generateEventCover({ userPrompt, history, currentImage?, eventContext })` → bytes de imagen.
- **Contador de cuota en `events-ms` (Prisma):** tabla `ai_usage_quota(userId, day, type, count)` (`type` ∈ `image` | `description`). El gateway consulta/incrementa vía mensaje.
- **Storage:** subir la imagen generada a **Firebase Storage** y devolver la URL (mismo contrato `{ imageUrl }` que el front ya consume).
- **Se eliminan** `UnsplashService` y `ClaudeService.generateSearchQuery` (y el secret `UNSPLASH_ACCESS_KEY`) si no se usan en otro lado — verificar antes de borrar.

### 3.2 Endpoints (reemplazan `POST /events/generate-cover`)

```
POST /events/ai/description   → { markdown: string }
POST /events/ai/cover         → { imageUrl: string }   // 16:9, en Storage
```

Request (descripción):
```jsonc
{ "userPrompt": "rodada nocturna a La Calera", "history": [ {"role":"user|model","text":"..."} ], "eventContext": { "type":"...", "city":"...", "date":"...", "difficulty":"..." } }
```
Request (portada): igual + `currentImageUrl?` (la imagen vigente del chat, para edición).

### 3.3 Cuota y Remote Config

- **Topes por usuario/día:** **5 imágenes**, **15 descripciones**. Cada turno del chat que llama al modelo (generar **o** editar) consume 1.
- **El valor del tope vive en Firebase Remote Config** (`ai_image_daily_limit`, `ai_description_daily_limit`) como **fuente única**: el backend lo lee (Firebase Admin) para *enforcement*; la app lo lee para UX (mostrar restantes / deshabilitar el envío). Se cambia sin re-deploy y no se desincroniza.
- Al exceder → error tipado `quota_exceeded` (ver §3.6).

### 3.4 Prompt con contexto propio (constantes en backend)

El prompt del usuario se **envuelve** para que el resultado encaje con Rideglory sin que el usuario lo diga:

- **Descripción** — system prompt: *"Eres el asistente de Rideglory, app de eventos y comunidad motera en Colombia. Redacta en español (es-CO), tono cercano de rider, sin markdown roto. Usa el contexto del evento."* + `eventContext`. Salida en **Markdown** (negritas, listas) acotada (~400–600 caracteres).
- **Portada** — prefijo de estilo + `eventContext`. Ej.: el usuario escribe *"un evento en Pereira"* → backend arma *"Cinematic photo of a motorcycle group ride near Pereira, Colombia, mountain roads, riders on motorcycles, golden hour, dynamic, high detail — {userPrompt}"* + **negativos** (sin texto, sin marca de agua, sin manos/placas deformes). Aspecto **16:9**, JPEG ~85%.

### 3.5 Lógica de imagen: nueva vs. edición

- **Default: GENERAR NUEVA** imagen desde el `userPrompt`, **sin** tocar la anterior.
- **Editar la imagen vigente SOLO** si el mensaje tiene **intención de edición explícita** detectada por **keywords es-CO curadas en backend**: `edita`, `editá`, `cámbiale`, `cambia`, `modifícala`, `modifica`, `a esta imagen`, `hazla más`, `quítale`, `ponle`, etc. → se pasa `currentImage` + instrucción a Gemini (edición multi-turno). Default a *nueva generación* si no hay match.
- La detección de intención vive en una constante/lista ajustable; el front puede mandar también un hint, pero la decisión final es del backend.

### 3.6 Limpieza de Storage (anti-huérfanos)

El usuario puede generar/editar varias veces; las descartadas no deben acumularse:

- Generar a ruta **temporal**: `events/covers/pending/{userId}/{draftId}.jpg`. Si el evento aún no se guardó, `draftId` = id de cliente (uuid) generado por la app.
- En **cada nueva generación/edición del mismo borrador, borrar la anterior** → máx **1 pendiente** por borrador.
- Al **guardar/publicar** el evento: mover la elegida a `events/{eventId}/cover.jpg` y **borrar el pendiente**.
- **Barrido programado (cron):** borrar `pending/` con > **7 días** (borradores abandonados).

> Nota: las imágenes van en **Firebase Storage**, no en Firestore.

### 3.7 Taxonomía de errores (todos → "sube tu propia foto", mensaje distinto)

| `reason` | Mensaje es-CO |
|---|---|
| `quota_exceeded_user` | "Llegaste a tu límite de imágenes por hoy. Vuelve mañana o sube tu propia foto." |
| `quota_exceeded_project` | "El generador está muy solicitado ahora. Intenta más tarde o sube tu propia foto." |
| `safety_blocked` | "No pude crear esa imagen. Prueba otra descripción o sube tu propia foto." |
| `network_error` | "No se pudo conectar. Revisa tu internet o sube tu propia foto." |

---

## 4. Solución técnica — App (Flutter)

- **Capa data:** retrofit client nuevo (o ampliar `EventCoverService`) con `POST /events/ai/description` y `POST /events/ai/cover`; DTOs en `rideglory-contracts`.
- **Capa domain:** `GenerateEventDescriptionUseCase`, `GenerateEventCoverUseCase` (reemplazan `GetGenerateCoverUseCase`).
- **Presentation — chat:**
  - `AiDescriptionChatCubit` / `AiCoverChatCubit` (estado: lista de turnos + `ResultState` del turno en curso + restantes de cuota desde Remote Config).
  - UI de **chat** (burbujas), sin botón "Editar". Imagen: cada respuesta es una burbuja-imagen; tap → **full screen**; "Usar esta imagen" la fija como portada. Descripción: la respuesta cae en el `AppRichTextEditor`.
  - **Descripción rich text:** la IA entrega **Markdown** → convertir a **Quill Delta** antes de insertar (utilidad `MarkdownToDelta`, p. ej. paquete `markdown` + builder de `dart_quill_delta`). El front **no** debe pedirle Delta JSON crudo al modelo.
  - Antes de sobreescribir una descripción ya escrita → confirmar.
- **Cuota en UX:** la app lee `ai_*_daily_limit` de Remote Config y deshabilita el envío al agotarse, mostrando restantes.

---

## 5. Criterios de aceptación

**Backend**
- [ ] `AiModule` + `GeminiService` en api-gateway; `GEMINI_API_KEY` en `.env` y deploy.
- [ ] `POST /events/ai/description` devuelve Markdown con contexto del evento, en es-CO.
- [ ] `POST /events/ai/cover` devuelve URL de imagen 16:9 JPEG subida a Storage.
- [ ] Default = imagen nueva; edición solo con keywords explícitas (test de la detección).
- [ ] Cuota por usuario/día (5 img, 15 desc) leída de Remote Config y enforced; `quota_exceeded` correcto.
- [ ] Limpieza `pending/` (sobrescribe en cada turno) + cron de barrido (>7 días).
- [ ] `UnsplashService` y `generateSearchQuery` eliminados (y `generate-cover` retirado/redirigido); sin referencias colgando.
- [ ] DTOs nuevos en `rideglory-contracts`.

**App**
- [ ] Chat interactivo para descripción e imagen, sin botón "Editar".
- [ ] Descripción: Markdown → Quill Delta insertado en `AppRichTextEditor`; confirma antes de pisar texto existente.
- [ ] Imagen: full screen + "Usar esta imagen" fija la portada; los 4 errores muestran su mensaje y ofrecen subir foto propia.
- [ ] App lee el tope de Remote Config y refleja restantes / deshabilita envío.
- [ ] `dart analyze` sin warnings; `flutter test` al 100%; strings en `app_es.arb`.

---

## 6. Telemetría

- `ai_description_generated` (`turn_index`), `ai_image_generated` (`is_edit` 0/1, `turn_index`)
- `ai_quota_exceeded` (`type`: image|description)
- `ai_generation_failed` (`reason`)
- `ai_cover_used` (cuando el usuario fija la imagen como portada)

---

## 7. Decisiones explícitamente descartadas

| Opción | Razón |
|---|---|
| Reutilizar `ClaudeService` para texto | No es gratis (centavos/token); requisito es $0 |
| Firebase AI Logic / client-side | Se decidió todo en backend; key fuera del cliente |
| `ai-ms` dedicado desde ya | Over-engineering para 2 features + costo RAM en EC2; se deja extraíble |
| Mantener Unsplash como fallback | Fallback acordado = el usuario sube su propia foto |
| Imagen `Imagen 4` de Google | Los modelos Imagen se apagan el 2026-06-24; usar **Gemini 2.5 Flash Image** |
| Persistir historial de chat en server | Innecesario: imagen vigente + mensajes los aporta el cliente |

---

## 8. Riesgos

| Riesgo | Mitigación |
|---|---|
| Free tier de imagen ajustado (10 RPM / 500 RPD del **proyecto**) | Tope por usuario en Remote Config + manejo `quota_exceeded_project`; volumen real bajo |
| Calidad/realismo de la imagen IA | Prompt con estilo + negativos; fallback a foto propia siempre disponible |
| Markdown→Delta con formato inesperado | Acotar el formato pedido al modelo; sanitizar antes de convertir; fallback a texto plano |
| Exposición de cuota (abuso) | Enforcement server-side por `userId` autenticado; no confiar en el cliente |
| Cambio de free tier de Google | `GeminiService` aislado en `AiModule`; tope vía Remote Config para apagar sin redeploy |

---

## 9. Fuera de alcance

- Generar la descripción a partir de la imagen (o viceversa).
- Estilos de marca avanzados (LoRA/fine-tuning) en la imagen.
- Higiene general de Storage al cambiar/eliminar evento/vehículo → **PRD aparte** (`prd-storage-hygiene.md`).

---

## 10. Brief plan (fases)

1. **Backend base** — `AiModule` + `GeminiService` (texto), endpoint `description`, prompt con contexto, DTOs en contracts. Eliminar Unsplash/Claude-query.
2. **Backend imagen** — endpoint `cover`: generación 16:9 → Storage → URL; lógica nueva-vs-edición por keywords; limpieza `pending/` + cron.
3. **Backend cuota** — tabla en `events-ms`, lectura de Remote Config (Admin), enforcement + errores tipados.
4. **App descripción** — `AiDescriptionChatCubit`, UI chat, Markdown→Delta en `AppRichTextEditor`, confirmación de sobreescritura.
5. **App imagen** — `AiCoverChatCubit`, UI chat + full screen + "Usar esta imagen", 4 estados de error, lectura de cuota desde Remote Config.
6. **QA + docs** — analytics, strings es-CO, tests, `docs/features/events.md` actualizado, deploy backend (migración + verificación local antes de desplegar).
