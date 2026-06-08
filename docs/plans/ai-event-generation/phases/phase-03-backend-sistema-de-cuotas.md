# Fase 3 — Backend — Sistema de cuotas

**Slug:** ai-event-generation  
**Fecha:** 2026-06-05T21:55:49Z (corregido por Auditor Opus)  
**Nivel rg-exec:** normal  
**Depende de:** Fases 1 y 2

---

## Objetivo

Cada usuario tiene un límite diario de generaciones (texto e imagen) configurable desde Firebase Remote Config. Superar ese límite devuelve un error tipado (`quota_exceeded_user` 429) manejable por la app. Los errores Gemini de cuota de proyecto, filtro de seguridad y red también se mapean a códigos tipados en esta fase.

---

## Alcance (entra / no entra)

### Entra
- `AiQuotaService` en `api-gateway/src/ai/` que lee y escribe la colección Firestore `ai_usage_quotas/{userId}/days/{YYYY-MM-DD}` via `firebase-admin` (sin TCP).
- Campos del documento de cuota: `descriptionCount`, `coverCount`, `createdAt`, `expireAt` (campo objetivo de TTL policy = `createdAt + 2 días`).
- Configuración de TTL policy en el **collection-group `days`** (donde viven los documentos con `expireAt`), apuntando al campo `expireAt`.
- Lectura de límites `ai_description_daily_limit` y `ai_cover_daily_limit` desde Remote Config Admin SDK (`firebase-admin/remote-config`), con caché en memoria de 5 minutos.
- Integración de `AiQuotaService.checkAndIncrement()` en `AiController` como guard (antes de llamar a Gemini) para `POST /ai/description` y `POST /ai/cover`.
- Mapeo de errores Gemini a los 4 códigos tipados: `quota_exceeded_user` (429), `quota_exceeded_project` (429), `safety_blocked` (422), `network_error` (503), usando excepciones NestJS (`HttpException`) con `{ error: AiErrorCode, remaining?, message? }` como body.
- Verificación de que `AiErrorCode` en `rideglory-contracts/src/ai/enums/` incluye los 4 valores (coherente con lo que crea la Fase 1).
- Nota de handoff en `ai.module.ts` / README: el botón "Generar portada con IA" del flujo legacy quedará inoperativo para testers entre Fases 3 y 5 (sin afectar usuarios reales).

### No entra
- Eliminación de `ClaudeService`, `UnsplashService` ni `/events/generate-cover` (se hace en Fase 5).
- Cambios de schema Prisma (AJ-2 lo eliminó).
- Lógica Flutter de cuota (Fases 4 y 5).
- Implementación de `GeminiService.generateDescription()` ni `generateCover()` (Fases 1 y 2).
- Deploy a EC2 (Fase 6).

---

## Que se debe hacer (pasos concretos y ordenados)

1. **Verificar acceso Firestore** — en entorno local, instanciar `getFirestore(getApps()[0])` y leer/escribir un documento de prueba en `ai_usage_quotas`; confirmar que la credencial de `firebase-admin` tiene permisos de lectura/escritura. Esta verificación es el gate de inicio de la fase.

2. **Completar `AiErrorCode` en `rideglory-contracts`** — abrir `rideglory-contracts/src/ai/enums/ai.enums.ts` (creado en Fase 1, siguiendo la convención del repo: `maintenances/enums/maintenance.enums.ts`, `users/enums/user.enums.ts`). Verificar que el enum `AiErrorCode` incluye los 4 valores: `quota_exceeded_user`, `quota_exceeded_project`, `safety_blocked`, `network_error`. Agregar los que falten. El archivo `rideglory-contracts/src/ai/dto/ai-error-response.dto.ts` importa `AiErrorCode` desde `../enums/ai.enums`.

3. **Crear `AiQuotaService`** en `api-gateway/src/ai/ai-quota.service.ts`:

   a. **Obtener la App singleton** — `AiQuotaService` NO inyecta `FirebaseAuthService` (su campo `app` es privado y accederlo no aportaría nada más allá del orden de inicialización). En cambio, accede a la App singleton a través de `getApps()[0]` de `firebase-admin/app`. Para garantizar que `FirebaseAuthService` ya la haya inicializado antes de que `AiQuotaService` la use, se lista `FirebaseAuthService` antes de `AiQuotaService` en el array `providers` del `AiModule` (NestJS inicializa providers en orden de declaración dentro del módulo). **`firebase-auth.service.ts` no se toca.**

   b. **Método privado `getLimits()`** — implementación:
   ```typescript
   private async getLimits(): Promise<{ descriptionLimit: number; coverLimit: number }> {
     if (this.limitsCache && Date.now() - this.limitsCachedAt < 5 * 60 * 1000) {
       return this.limitsCache;
     }
     const template = await getRemoteConfig(getApps()[0]).getTemplate();
     const parseLimit = (key: string, fallback: number): number => {
       const raw = (template.parameters[key]?.defaultValue as { value?: string } | undefined)?.value;
       const parsed = parseInt(raw ?? '', 10);
       return Number.isFinite(parsed) ? parsed : fallback;
     };
     const descriptionLimit = parseLimit('ai_description_daily_limit', 10);
     const coverLimit = parseLimit('ai_cover_daily_limit', 5);
     this.limitsCache = { descriptionLimit, coverLimit };
     this.limitsCachedAt = Date.now();
     return this.limitsCache;
   }
   ```
   Usar `getRemoteConfig(app).getTemplate()` (no `getServerTemplate()`). El helper `parseLimit` cubre tres casos de degradación sin lanzar: parámetro ausente en `parameters`, `defaultValue` es `undefined`, y `value` es una cadena no numérica (e.g. `'abc'` → `NaN` → fallback). Fallbacks: `10` para descripción, `5` para portada.

   c. **Método `checkAndIncrement(userId, type)`** — mecánica de la transacción:
   ```typescript
   async checkAndIncrement(
     userId: string,
     type: 'description' | 'cover',
   ): Promise<{ remaining: number }> {
     const { descriptionLimit, coverLimit } = await this.getLimits();
     const limit = type === 'description' ? descriptionLimit : coverLimit;
     const countField = type === 'description' ? 'descriptionCount' : 'coverCount';
     const today = new Date().toISOString().split('T')[0]; // 'YYYY-MM-DD'
     const firestore = getFirestore(getApps()[0]);
     const ref = firestore.doc(`ai_usage_quotas/${userId}/days/${today}`);

     return firestore.runTransaction(async (transaction) => {
       const snap = await transaction.get(ref);   // lectura dentro de la transacción
       const data = snap.data();

       const currentCount: number = data?.[countField] ?? 0;

       if (currentCount >= limit) {
         throw new HttpException(
           { error: AiErrorCode.quota_exceeded_user, remaining: 0 },
           HttpStatus.TOO_MANY_REQUESTS,
         );
       }

       const newCount = currentCount + 1;           // count+1 directo; FieldValue.increment innecesario
       const now = Timestamp.now();
       const expireAt = Timestamp.fromDate(
         new Date(Date.now() + 2 * 24 * 60 * 60 * 1000),
       );

       if (!snap.exists) {
         // Primera generación del día: crear documento con ambos contadores y TTL
         transaction.set(ref, {
           descriptionCount: 0,
           coverCount: 0,
           [countField]: newCount,
           createdAt: now,
           expireAt,
         });
       } else {
         // Documento existente: actualizar solo el contador y asegurar expireAt
         transaction.set(ref, { [countField]: newCount, expireAt }, { merge: true });
       }

       return { remaining: limit - newCount };      // remaining = limit - (count+1)
     });
   }
   ```
   Dentro de `runTransaction` se usa siempre `transaction.get(ref)` y `transaction.set(ref, ...)` — nunca llamadas sueltas a `ref.set()` o `ref.update()` fuera de la transacción. `FieldValue.increment` es redundante porque el valor actual ya se leyó dentro de la transacción; escribir `count + 1` directamente es correcto y más explícito. `remaining = limit - newCount` (donde `newCount = currentCount + 1`) es la fórmula definitiva.

4. **Actualizar `AiModule`** — agregar `AiQuotaService` al array `providers` de `ai.module.ts`, listado después de `FirebaseAuthService` (si ya está presente como provider) para garantizar orden de inicialización.

5. **Integrar en `AiController`** — en cada handler (`generateDescription`, `generateCover`):

   - Extraer `userId` usando `@Req() request: AuthenticatedRequest` y `request.user.uid` (mismo patrón que usa el guard en `firebase-auth.guard.ts`). Ejemplo de firma del handler:
     ```typescript
     @Post('description')
     @UseGuards(FirebaseAuthGuard)
     async generateDescription(
       @Body() dto: AiDescriptionRequestDto,
       @Req() request: AuthenticatedRequest,
     ) {
       const userId = request.user.uid;
       // ...
     }
     ```

   - **Decisión sobre cuota ante fallo de Gemini:** el intento **consume cuota aunque la generación falle** (opción b). Esta es la elección explícita de esta fase. Justificación: evita la complejidad de un rollback y los riesgos de estado inconsistente ante errores en el propio rollback; es el comportamiento estándar de APIs con rate-limit (OpenAI, Gemini). El usuario ve el error tipado y sabe que su cuota se decrementó; puede reintentar el siguiente intento dentro de su cuota restante.

   - Llamar `const { remaining } = await this.aiQuotaService.checkAndIncrement(userId, type)` antes de invocar `GeminiService`. Si `checkAndIncrement` lanza `HttpException` 429, el handler lo propaga directamente sin llamar a Gemini.

   - Capturar errores Gemini en un bloque `try/catch` dentro del handler (o en `GeminiService`). En todos los casos de error Gemini el contador ya fue incrementado (no se hace rollback):
     - Error 429 de Gemini API → `HttpException({ error: AiErrorCode.quota_exceeded_project }, 429)`.
     - Respuesta con `finishReason === 'SAFETY'` (o similar) → `HttpException({ error: AiErrorCode.safety_blocked, message: '...' }, 422)`.
     - Error de red / timeout (`ECONNREFUSED`, `ENOTFOUND`, `AbortError`) → `HttpException({ error: AiErrorCode.network_error, message: '...' }, 503)`.

   - Incluir `remainingGenerations: remaining` en el body del response 200 (campo ya declarado en `AiDescriptionResponseDto` y `AiCoverResponseDto`).

6. **Configurar TTL policy en Firestore** — la TTL policy se aplica al **collection-group `days`** (la subcollección donde viven los documentos de cuota diaria con el campo `expireAt`), no a la colección raíz `ai_usage_quotas`.

   > **Nota de coherencia con 05-sintesis.md:** el archivo de síntesis del plan menciona en el texto de Fase 3 "colección `ai_usage_quotas/{userId}/days/{YYYY-MM-DD}`" y en la tabla de estructura Firestore (sección de Contratos del Architect Review) la TTL policy apuntando al collection-group `days`. Esta fase adopta conscientemente el collection-group `days` como objetivo de la TTL policy — no la colección raíz `ai_usage_quotas` — porque la TTL policy de Firestore opera sobre los documentos que contienen el campo `expireAt`, que viven en la subcollección `days`, no en el documento raíz de `ai_usage_quotas`. Cualquier referencia en la síntesis a la "colección raíz" como objetivo de la TTL se considera un error tipográfico corregido aquí.

   Documentar el siguiente comando en el handoff para que el dev de backend lo ejecute manualmente una sola vez antes del deploy:
   ```bash
   gcloud firestore fields ttls update expireAt \
     --collection-group=days \
     --enable-ttl \
     --project=<FIREBASE_PROJECT_ID>
   ```
   Firestore puede tardar hasta 24 h en activar la TTL policy; no bloqueante para la funcionalidad.

7. **Agregar nota de handoff** — comentario en `ai.module.ts` y entrada en `docs/features/events.md` (sección de asistente IA): "Fase 3 activa: el endpoint `/events/generate-cover` (flujo legacy Unsplash) sigue activo pero el botón en la app quedará inoperativo para testers entre Fases 3 y 5. Sin usuarios reales en producción."

---

## Archivos a crear/modificar (rutas reales)

| Ruta (relativa a `/Users/cami/Developer/Personal/rideglory-api/`) | Acción | Qué cambia |
|---|---|---|
| `api-gateway/src/ai/ai-quota.service.ts` | **CREAR** | Servicio completo: `checkAndIncrement()` con transacción Firestore + `getLimits()` con caché Remote Config |
| `api-gateway/src/ai/ai.module.ts` | **MODIFICAR** | Agregar `AiQuotaService` a `providers`; listado después de `FirebaseAuthService` para garantizar orden de init |
| `api-gateway/src/ai/ai.controller.ts` | **MODIFICAR** | Llamar `checkAndIncrement()` antes de Gemini; capturar y mapear 4 errores tipados; propagar `remainingGenerations` en response 200 |
| `rideglory-contracts/src/ai/enums/ai.enums.ts` | **MODIFICAR** | Verificar/completar `AiErrorCode` con los 4 valores |

> Los archivos `ai.module.ts`, `ai.controller.ts` y `ai.enums.ts` son creados en Fases 1-2; esta fase los modifica.  
> El DTO `rideglory-contracts/src/ai/dto/ai-error-response.dto.ts` importa `AiErrorCode` desde `../enums/ai.enums` — no se modifica en esta fase si Fase 1 lo creó correctamente con esa importación.  
> `firebase-auth.service.ts` **no se toca**: `getFirestore()` y `getRemoteConfig()` funcionan con la App singleton ya inicializada vía `getApps()[0]`; no se expone ningún campo público.

---

## Contratos / API rideglory-api

No hay endpoints nuevos en esta fase. Los endpoints existentes de `AiController` cambian su comportamiento:

**Respuestas de error nuevas (aplica a `POST /ai/description` y `POST /ai/cover`):**

```
429 — quota_exceeded_user
{ "error": "quota_exceeded_user", "remaining": 0 }

429 — quota_exceeded_project
{ "error": "quota_exceeded_project" }

422 — safety_blocked
{ "error": "safety_blocked", "message": "Content was blocked by safety filters." }

503 — network_error
{ "error": "network_error", "message": "Unable to reach Gemini API." }
```

**Response 200 actualizado** (campo `remainingGenerations` ya declarado en Fases 1-2, ahora se propaga correctamente):
```
POST /ai/description → { markdown: string, remainingGenerations: number }
POST /ai/cover       → { imageUrl: string, draftId: string, remainingGenerations: number }
```

**Firebase Remote Config — parámetros esperados:**

| Parámetro | Tipo en RC | Extracción en código | Fallback en código |
|---|---|---|---|
| `ai_description_daily_limit` | String (número) | `template.parameters['ai_description_daily_limit'].defaultValue.value` → `parseInt(value, 10)` | `10` |
| `ai_cover_daily_limit` | String (número) | `template.parameters['ai_cover_daily_limit'].defaultValue.value` → `parseInt(value, 10)` | `5` |

Estos parámetros deben existir en la consola de Firebase Remote Config antes del deploy de esta fase.

---

## Cambios de datos / migraciones

No hay migración Prisma (AJ-2 eliminó la tabla de cuota de events-ms).

**Firestore — acción manual única:**
- La colección `ai_usage_quotas` se crea implícitamente con el primer documento escrito por `AiQuotaService`.
- La TTL policy se configura en el **collection-group `days`** (subcollección donde viven los documentos con `expireAt`), no en la colección raíz `ai_usage_quotas`. Esta fase corrige conscientemente cualquier referencia en `05-sintesis.md` que pudiera leerse como apuntar la TTL a la colección raíz: el campo `expireAt` vive en documentos de la subcollección `days`, por lo que el collection-group correcto para la TTL policy es `days`. Comando a ejecutar una sola vez antes del primer deploy:
  ```bash
  gcloud firestore fields ttls update expireAt \
    --collection-group=days \
    --enable-ttl \
    --project=<FIREBASE_PROJECT_ID>
  ```
  Firestore puede tardar hasta 24 h en activar la policy; no bloqueante. Documentar en handoff.

---

## Criterios de aceptación (numerados, observables, testeables)

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

## Pruebas

### Unitarias (NestJS / Jest)

**`ai-quota.service.spec.ts`** — ubicación: `api-gateway/src/ai/ai-quota.service.spec.ts`

| Caso | Setup | Assert |
|---|---|---|
| Primera generación del día — descripción | `transaction.get` devuelve snapshot vacío (`exists: false`) | `transaction.set` crea doc con `descriptionCount=1`, `expireAt ≈ createdAt + 2 días`; devuelve `remaining = limit - 1` |
| N-ésima generación dentro del límite | Snapshot con `descriptionCount = limit - 1` | `transaction.set` escribe `descriptionCount = limit`; devuelve `remaining = 0` |
| Límite superado — descripción | Snapshot con `descriptionCount = limit` | Lanza `HttpException` 429 con `error: quota_exceeded_user`; sin llamar `transaction.set` |
| Límite superado — cover | Snapshot con `coverCount = limit` | Lanza `HttpException` 429 con `error: quota_exceeded_user` |
| `remaining` = `limit - newCount` | Snapshot con `descriptionCount = 3`, límite = 10 | Devuelve `{ remaining: 6 }` |
| `expireAt` calculado correctamente | Primera escritura | `expireAt` ≈ `createdAt + 2 días` (delta verificable con tolerancia de ±1 s) |
| Caché de límites | Llamada doble a `getLimits()` dentro de 5 min | `getRemoteConfig().getTemplate()` se invoca una sola vez |
| `getLimits()` — parámetro ausente en Remote Config | `template.parameters` no contiene `ai_description_daily_limit` (la key no existe) | Devuelve `descriptionLimit = 10` (fallback); no lanza ninguna excepción |
| `getLimits()` — `defaultValue` es `undefined` | `template.parameters['ai_description_daily_limit']` existe pero `defaultValue` es `undefined` | Devuelve `descriptionLimit = 10` (fallback); no lanza |
| `getLimits()` — `value` es string no numérico | `defaultValue.value = 'abc'` | `parseInt('abc', 10)` produce `NaN`; la lógica defensiva aplica fallback 10/5; no lanza |
| Gemini falla tras `checkAndIncrement` (no rollback) | `checkAndIncrement` retorna `{ remaining: 7 }` (contador pasó de 2 a 3, límite 10); `GeminiService.generateDescription` lanza `Error('ECONNREFUSED')` | Handler devuelve 503 con `{ error: 'network_error' }`; en Firestore el documento tiene `descriptionCount = 3` (el incremento persiste, no hay rollback) |

> Mockear `getFirestore()` y `getApps()` con jest mocks. El mock de `runTransaction` debe recibir la callback y ejecutarla con un objeto `transaction` stub que exponga `get(ref)` retornando un snapshot controlado y `set(ref, data, opts?)` espíable. Mockear `getRemoteConfig().getTemplate()` para devolver un template con `parameters` controlados.

**`ai.controller.spec.ts`** — extender los specs creados en Fases 1-2:

| Caso | Setup | Assert |
|---|---|---|
| `checkAndIncrement` lanza 429 | Mock `AiQuotaService.checkAndIncrement` → throw `HttpException(429)` | Controller propaga el 429 sin llamar a GeminiService |
| Gemini lanza error 429 | Mock `GeminiService` → throw con status 429 | Controller responde `{ error: 'quota_exceeded_project' }` HTTP 429 |
| Gemini rechaza por seguridad | Mock `GeminiService` → simular `finishReason: 'SAFETY'` | Controller responde `{ error: 'safety_blocked' }` HTTP 422 |
| Gemini no alcanzable | Mock `GeminiService` → throw `Error('ECONNREFUSED')` | Controller responde `{ error: 'network_error' }` HTTP 503 |
| Response 200 incluye `remainingGenerations` | Mock `checkAndIncrement` → `{ remaining: 7 }` | Response body contiene `remainingGenerations: 7` |

### Integración / e2e

- Test e2e manual (o supertest): llamar `POST /ai/description` con un usuario de prueba tantas veces como `ai_description_daily_limit` + 1; verificar que la última retorna 429 con `error: quota_exceeded_user`.

### No aplican (fuera de alcance)
- Tests Flutter (Fases 4-5).
- TTL policy (imposible testear en Jest; se verifica en consola de Firebase / salida de `gcloud`).

---

## Riesgos y mitigaciones

| ID | Riesgo | Prob | Impacto | Mitigación |
|----|--------|------|---------|------------|
| R-Q1 | Remote Config Admin SDK falla si el service account de `firebase-admin` no tiene el rol `remoteConfig.viewer` en GCP IAM | Media | Alto | Verificar permisos en GCP IAM al inicio de la fase; si faltan, añadirlos al service account. Fallback de desarrollo: si `getTemplate()` lanza, devolver los valores hardcodeados (10/5) y loguear el error; nunca silenciar la excepción en producción |
| R-Q2 | `getApps()[0]` devuelve `undefined` si `AiQuotaService` se inicializa antes de que `FirebaseAuthService` haya llamado a `initializeApp()` | Baja | Alto | Listar `FirebaseAuthService` antes de `AiQuotaService` en el array `providers` de `AiModule` (NestJS inicializa providers en orden de declaración). NO se inyecta `FirebaseAuthService` como dependencia declarada (su campo `app` es privado; inyectarlo solo forzaría el orden sin dar acceso real). **`firebase-auth.service.ts` no se modifica.** Si el problema persiste, envolver el acceso a `getApps()[0]` en un getter lazy que verifique `getApps().length > 0` y lance un error descriptivo en caso contrario |
| R-Q3 | Carrera entre dos requests simultáneos del mismo usuario pueden ambos leer el mismo count antes de que alguno escriba | Baja | Medio | Resuelto con `runTransaction()` de Firestore: `transaction.get()` + `transaction.set()` dentro de la misma transacción garantizan lectura + escritura atómica; Firestore reintenta automáticamente en caso de conflicto |
| R-Q4 | TTL policy de Firestore tarda hasta 24 h en entrar en vigor tras ser creada | Baja | Bajo | No bloqueante para la funcionalidad; solo afecta la limpieza automática. Documentar en handoff |
| R-Q5 | Caché de Remote Config (5 min) hace que límites recién cambiados no sean inmediatos | Baja | Bajo | Aceptable para la UX; documentado en handoff |
| R-Q6 | `finishReason` de Gemini para filtro de seguridad puede variar entre modelos/versiones del SDK `@google/genai` | Media | Bajo | En el catch de seguridad, inspeccionar tanto `finishReason === 'SAFETY'` como el mensaje de error; agregar logging de `finishReason` para detectar valores inesperados en producción |

---

## Dependencias (fases prerequisito y por que)

| Fase | Razón |
|------|-------|
| **Fase 1 — Backend: Base de texto IA** | Crea `AiModule`, `AiController`, `GeminiService.generateDescription()`, y los artefactos en `rideglory-contracts/src/ai/` incluyendo `rideglory-contracts/src/ai/dto/ai-error-response.dto.ts` y `rideglory-contracts/src/ai/enums/ai.enums.ts` con `AiErrorCode`. Fase 3 modifica estos artefactos; no puede crearlos de cero. |
| **Fase 2 — Backend: Portada IA con Storage** | Crea `GeminiService.generateCover()` y el handler `POST /ai/cover` en `AiController`. La integración de cuota en ese handler requiere que el handler exista. Además, Fase 2 confirma que la App singleton de `firebase-admin` está completamente inicializada (con `storageBucket`), lo que valida que `getApps()[0]` es fiable antes de que `AiQuotaService` lo utilice. |

---

## Ejecucion recomendada (nivel rg-exec: normal)

**Nivel:** `normal`

**Justificación:** Esta fase introduce una nueva colección Firestore (sin migración Prisma), lógica de cuota con transacciones atómicas, lectura de Remote Config Admin SDK vía `getTemplate()`, y mapeo de 4 errores tipados. El Remote Config Admin SDK ya está disponible vía el paquete `firebase-admin` v13 (que ya está en `api-gateway/package.json`); no se instala nada nuevo. El blast radius está acotado a `api-gateway` y la colección Firestore `ai_usage_quotas`; no hay cambios en events-ms ni en otros microservicios. La integración de `checkAndIncrement()` en el controller es quirúrgica (2 líneas por handler + bloque try/catch). El nivel `full` no se justifica porque no hay modelos Gemini inestables (solo Firestore y Remote Config, ambos maduros), no hay escrituras a Storage, y no hay eliminación de código legacy. El nivel `lite` sería insuficiente porque la atomicidad de la transacción y el mapeo correcto de los 4 errores requieren tests unitarios y validación cuidadosa del comportamiento concurrente.
