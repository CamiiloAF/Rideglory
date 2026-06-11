# Backend Handoff — ai-phase06-qa-analytics

**Timestamp:** 2026-06-10T22:18:31Z  
**Agente:** Backend (NestJS / rideglory-api)

---

## Baseline

Antes de cualquier cambio, se corrió la suite de tests del módulo AI:

```
Test Suites: 5 passed, 5 total
Tests:       32 passed, 32 total
```

Todos verdes. Ninguna regresión preexistente.

---

## Archivos cambiados

| Archivo | Operación | Descripción |
|---------|-----------|-------------|
| `rideglory-contracts/src/ai/dto/ai-description-request.dto.ts` | modify | Agregado `@ArrayMaxSize(10)` al campo `history`; import `ArrayMaxSize` añadido |
| `api-gateway/src/ai/ai-description.spec.ts` | create | Spec dedicada con 5 tests cubriendo gaps genuinos no presentes en specs existentes |

**Rebuild de contratos ejecutado:**
```bash
cd rideglory-contracts && npm run build
cd api-gateway && pnpm install
```

---

## Pruebas nuevas

`api-gateway/src/ai/ai-description.spec.ts` — 5 tests, 2 suites:

### Suite A: AiDescriptionRequestDto validation — history > 10

| Test | Resultado |
|------|-----------|
| throws BadRequestException when history has more than 11 turns | PASS |
| accepts history with exactly 10 turns | PASS |

Usa `ValidationPipe({ whitelist: true, transform: true })` para validar el DTO contra `AiDescriptionRequestDto`. El `@ArrayMaxSize(10)` del contrato recién agregado es lo que hace este test verde.

### Suite B: GeminiService.generateDescription — happy path and safety

| Test | Resultado |
|------|-----------|
| returns isDescription: true when model response starts with {{DESCRIPTION}} marker | PASS |
| returns isDescription: false when model response starts with {{QUESTION}} marker | PASS |
| throws Error(AiErrorCode.SAFETY_BLOCKED) when SDK throws safety_blocked error | PASS |

**Notas de implementación:**
- Los mocks de respuesta exitosa incluyen `candidates: [{ finishReason: 'STOP' }]` para pasar la guardia de seguridad del servicio (`!response.candidates` triggea `SAFETY_BLOCKED`).
- El test de SAFETY_BLOCKED usa `new Error(AiErrorCode.SAFETY_BLOCKED)` (valor `'safety_blocked'`) porque el servicio compara `message === AiErrorCode.SAFETY_BLOCKED` exactamente. El valor `'SAFETY'` del handoff del arquitecto caería en `NETWORK_ERROR` — se corrigió para reflejar el comportamiento real del código.
- No se duplicaron los tests de `RESOURCE_EXHAUSTED → quota_exceeded_project` ni `timeout → network_error` ya cubiertos en `gemini.service.spec.ts`.

---

## Resultado final

```
Test Suites: 6 passed, 6 total  (+1 nuevo)
Tests:       37 passed, 37 total  (+5 nuevos)
```

Todos verdes. Cero regresiones.

---

## Verificación manual

```bash
# Correr solo el nuevo spec
cd /Users/cami/Developer/Personal/rideglory-api/api-gateway
npx jest src/ai/ai-description.spec.ts --no-coverage

# Correr todo el módulo AI
npx jest src/ai/ --no-coverage
```

---

## Notas Frontend/QA

- El cambio al DTO `@ArrayMaxSize(10)` es retrocompatible con el cliente Flutter: `AiDescriptionChatCubit` acumula el historial de conversación y, por diseño de UX, no enviará más de 10 turnos (la interfaz acota a ~5 intercambios).
- Si QA prueba con más de 10 turnos en el historial via llamada directa a la API, ahora recibirá 400 en lugar de comportamiento indefinido.
- El campo `isDescription` en la respuesta ya está siendo usado por el cubit Flutter para decidir si mostrar la descripción o una pregunta de clarificación — los nuevos tests confirman que el servicio lo resuelve correctamente vía los marcadores `{{DESCRIPTION}}` / `{{QUESTION}}`.
- Los cambios de Flutter (analytics en `AiDescriptionChatCubit`, constantes en `analytics_events.dart` / `analytics_params.dart`, tests Flutter) son responsabilidad del agente Frontend.
