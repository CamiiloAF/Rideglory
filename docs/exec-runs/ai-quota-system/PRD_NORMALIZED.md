# PRD Normalizado — ai-quota-system

**Generado:** 2026-06-05T23:41:50Z  
**Fuente:** `docs/plans/ai-event-generation/phases/phase-03-backend-sistema-de-cuotas.md`  
**Nivel rg-exec:** normal  
**Depende de:** Fases 1 y 2 del plan `ai-event-generation`

---

## 1 Objetivo

Implementar un sistema de cuota diaria por usuario para las generaciones IA (descripción de evento e imagen de portada) en el backend (`api-gateway`). Cada usuario tiene un límite diario configurable via Firebase Remote Config; superarlo retorna un error tipado `quota_exceeded_user` HTTP 429. Los errores de Gemini API (cuota de proyecto, filtro de seguridad, error de red) se mapean a 4 códigos tipados (`AiErrorCode`) y se exponen como respuestas HTTP estandarizadas. El contador de uso persiste en Firestore con TTL automático de 2 días.

---

## 2 Por qué

- Sin cuota, un usuario malicioso o buggy puede agotar el crédito gratuito del proyecto en Gemini API.
- Los errores de Gemini llegan hoy como excepciones no mapeadas; la app no puede distinguir entre cuota agotada, contenido bloqueado o error de red — lo que impide mostrar mensajes de error útiles en español al usuario.
- Firebase Remote Config permite ajustar los límites en caliente sin redesplegar, manteniendo flexibilidad operativa.

---

## 3 Alcance

### Entra
- `AiQuotaService` en `api-gateway/src/ai/ai-quota.service.ts`:
  - Lee/escribe `ai_usage_quotas/{userId}/days/{YYYY-MM-DD}` en Firestore via transacción atómica (`runTransaction`).
  - Campos del documento: `descriptionCount`, `coverCount`, `createdAt`, `expireAt` (TTL = `createdAt + 2 días`).
  - Método `checkAndIncrement(userId, type)` que lanza `HttpException` 429 si el contador alcanza el límite.
  - Método privado `getLimits()` con caché en memoria de 5 minutos leyendo Remote Config Admin SDK (`getTemplate()`).
  - Fallbacks: `10` para descripción, `5` para portada.
- Completar `AiErrorCode` en `rideglory-contracts/src/ai/enums/ai.enums.ts` con los 4 valores: `quota_exceeded_user`, `quota_exceeded_project`, `safety_blocked`, `network_error`.
- Integración de `checkAndIncrement()` en `AiController` como guard antes de cada llamada a Gemini (`POST /ai/description`, `POST /ai/cover`).
- Mapeo de errores Gemini a `HttpException` tipados: 429 `quota_exceeded_project`, 422 `safety_blocked`, 503 `network_error`.
- Propagación del campo `remainingGenerations` en responses 200.
- Registro de `AiQuotaService` en `AiModule`, listado después de `FirebaseAuthService` para garantizar orden de init.
- Documentación de TTL policy en handoff (`gcloud firestore fields ttls update expireAt --collection-group=days`).
- Nota de handoff en `ai.module.ts` y `docs/features/events.md`: botón legacy "Generar portada con IA" inoperativo para testers entre Fases 3 y 5.

### No entra
- Eliminación de `ClaudeService`, `UnsplashService`, ni `/events/generate-cover` (Fase 5).
- Cambios de schema Prisma.
- Lógica Flutter de cuota (Fases 4 y 5).
- Implementación de `GeminiService.generateDescription()` ni `generateCover()` (Fases 1 y 2).
- Deploy a EC2 (Fase 6).

---

## 4 Áreas afectadas

| Repositorio | Ruta | Tipo de cambio |
|---|---|---|
| `rideglory-api` | `api-gateway/src/ai/ai-quota.service.ts` | CREAR |
| `rideglory-api` | `api-gateway/src/ai/ai.module.ts` | MODIFICAR — agregar `AiQuotaService` a `providers` |
| `rideglory-api` | `api-gateway/src/ai/ai.controller.ts` | MODIFICAR — integrar cuota + mapeo de 4 errores Gemini |
| `rideglory-api` | `rideglory-contracts/src/ai/enums/ai.enums.ts` | MODIFICAR — completar `AiErrorCode` |
| Firestore (infra) | Collection-group `days` dentro de `ai_usage_quotas` | TTL policy manual (comando `gcloud`) |
| Firebase Remote Config | `ai_description_daily_limit`, `ai_cover_daily_limit` | Parámetros a crear antes del deploy |
| Rideglory (Flutter) | — | Sin cambios en esta fase |

---

## 5 Criterios de aceptación

1. `POST /ai/description` con un usuario que ha alcanzado `ai_description_daily_limit` devuelve HTTP 429 con body `{ "error": "quota_exceeded_user", "remaining": 0 }`.
2. `POST /ai/cover` con un usuario que ha alcanzado `ai_cover_daily_limit` devuelve HTTP 429 con body `{ "error": "quota_exceeded_user", "remaining": 0 }`.
3. El mismo usuario con cuota disponible recibe HTTP 200 y el campo `remainingGenerations` refleja `limit - (currentCount + 1)` correctamente.
4. Dos solicitudes concurrentes del mismo usuario para el mismo tipo no superan el límite — la transacción Firestore (`runTransaction` con `transaction.get` + `transaction.set`) garantiza atomicidad sin over-counts.
5. Cuando Gemini responde con error 429 (cuota de proyecto), `AiController` devuelve HTTP 429 con `{ "error": "quota_exceeded_project" }`.
6. Cuando Gemini rechaza por filtro de seguridad, `AiController` devuelve HTTP 422 con `{ "error": "safety_blocked", "message": "..." }`.
7. Cuando Gemini no es alcanzable (timeout / ECONNREFUSED), `AiController` devuelve HTTP 503 con `{ "error": "network_error", "message": "..." }`.
8. Los documentos en `ai_usage_quotas/{userId}/days/{YYYY-MM-DD}` contienen el campo `expireAt` como `Timestamp` = `createdAt + 2 días`; la TTL policy está configurada en el collection-group `days` apuntando al campo `expireAt` (verificable con `gcloud firestore fields ttls describe expireAt --collection-group=days`).
9. Los límites se leen de Remote Config (no están hardcodeados); cambiar `ai_description_daily_limit` en la consola de Firebase se refleja en el servicio en ≤ 5 minutos (ventana de caché).
10. **Cuota ante fallo Gemini:** cuando `checkAndIncrement()` incrementa el contador (`N → N+1`) y la llamada posterior a Gemini falla con cualquiera de los 3 errores (`quota_exceeded_project`, `safety_blocked`, `network_error`), el Firestore confirma el valor `N+1` — no se realiza ningún rollback. El response al cliente es el error tipado correspondiente (429/422/503), y la siguiente llamada del usuario parte desde `N+1`.
11. `tsc --noEmit` limpio en api-gateway y rideglory-contracts; sin regresiones en specs existentes.

---

## 6 Guardrails de regresión

- `firebase-auth.service.ts` no se modifica; `AiQuotaService` accede a la App singleton via `getApps()[0]` sin inyectar `FirebaseAuthService`.
- El endpoint `/events/generate-cover` (flujo legacy Unsplash/Claude) permanece intacto — no se elimina en esta fase.
- Los tests existentes de `AiController` (creados en Fases 1-2) no deben regresar; si se extienden, los nuevos casos son aditivos.
- Sin cambios en `events-ms`, `users-ms`, ni ningún otro microservicio.
- Sin cambios en schema Prisma.
- Sin cambios en `lib/` de Flutter.
- `dart analyze` en Flutter debe seguir limpio (no hay cambios Flutter).

---

## 7 Constraints heredados

- **Orden de providers en `AiModule`:** `FirebaseAuthService` debe estar listado antes de `AiQuotaService` en el array `providers` para garantizar que `initializeApp()` haya corrido antes de `getApps()[0]` sea accedido.
- **Remote Config Admin SDK:** usar `getRemoteConfig(app).getTemplate()` (no `getServerTemplate()`); el service account de `firebase-admin` necesita el rol `remoteConfig.viewer` en GCP IAM.
- **Semántica de cuota:** el intento consume cuota aunque la generación Gemini falle (sin rollback). Comportamiento explícito y documentado.
- **TTL policy Firestore:** apuntar al **collection-group `days`** (no a la colección raíz `ai_usage_quotas`); acción manual única antes del primer deploy.
- **Remote Config params:** `ai_description_daily_limit` y `ai_cover_daily_limit` deben existir en Firebase Remote Config antes del deploy; la app espera Strings numéricos.
- **Fallbacks de límites:** `10` (descripción) y `5` (portada) — hardcodeados como fallback defensivo, no como valores primarios.
- **Sin usuarios reales en producción:** refactors agresivos son aceptables; los tests deben pasar.
- **Código de contratos** en `rideglory-contracts/src/ai/enums/ai.enums.ts` sigue la convención del repo (patrón `maintenances/enums/maintenance.enums.ts`).
