> Slim handoff — read this before docs/exec-runs/event-form-stepper-fase1/handoffs/architect.md

# Backend tasks — event-form-stepper Fase 1

## BLOQUEANTE — confirmar con el humano antes de implementar

**La cadena de portada IA NO existe** en el codebase actual (ni endpoint, ni DTO, ni GeminiService.generateCover). Los archivos que el PRD asumía MODIFY no existen.

**Opción A (recomendada):** sin cambios de backend en Fase 1. Esperar confirmación del humano.

**Opción B (solo si el humano lo confirma):** ver sección "Si se incluye cover (Opción B)" más abajo.

---

## Opción A — Sin cambios de backend

No hay archivos que modificar ni crear en `rideglory-api` durante Fase 1. La cadena de portada se planifica en una Fase separada con el scope completo definido correctamente.

---

## Si se incluye cover (Opción B — requiere confirmación explícita del humano)

### Constraint previo obligatorio

Antes de crear el endpoint, reconciliar con los DTOs preexistentes en `rideglory-contracts`:
- `AiCoverRequestDto` tiene shape `{ prompt: string; draftId: UUID }` — diferente al que el PRD asumía
- `AiCoverResponseDto` tiene shape `{ imageUrl: string; remainingGenerations: number }`
- Decidir: ¿usar el DTO existente o crear uno local en api-gateway? No duplicar el concepto.
- `GeminiService.generateCover()` NO debe retornar `response.text` como `imageUrl` — definir qué representa el campo antes de implementar.

### Files to create/modify (solo Opción B)

| File | Action |
|------|--------|
| `api-gateway/src/events/dto/generate-cover.dto.ts` | **CREATE** |
| `api-gateway/src/ai/ai.controller.ts` | **MODIFY** |
| `api-gateway/src/ai/gemini.service.ts` | **MODIFY** |

### Constraints (Opción B)

- `city` OPTIONAL desde el primer commit (backward-compatible)
- No modificar `rideglory-contracts` en esta fase
- No hay cambios de DB ni Prisma
- No hay env vars nuevos (`GEMINI_API_KEY` y `GEMINI_TEXT_MODEL` ya existen)

> Full detail: docs/exec-runs/event-form-stepper-fase1/handoffs/architect.md
