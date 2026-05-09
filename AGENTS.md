# Agentes de desarrollo — Rideglory (Flutter)

Este repo define **sub-agentes** como reglas en `.cursor/rules/agent-*.mdc`. El modelo las puede cargar según archivos abiertos o puedes **mencionar la regla** en el chat si tu cliente lo permite.

## Roles

| Rol | Regla | Uso típico |
|-----|--------|------------|
| **Flutter dev** | `agent-flutter-developer.mdc` | Pantallas, Cubits, datos, navegación, widgets |
| **Arquitecto** | `agent-architect.mdc` | Revisión de PR, límites de capas, lints, escalabilidad |
| **Senior Code Reviewer (Clean Architecture)** | `agent-clean-architecture-reviewer.mdc` | Modo *Judge*: inconsistencias de capas domain/data/presentation y estándares del repo |
| **DevOps** | `agent-devops.mdc` | YAML de tooling, CI/CD cuando exista |

## Harness implementador ↔ revisor

Para cerrar el ciclo **Implementador (Task) → Revisor → correcciones → …** sin pasos manuales extra:

1. Lanza un subagente **Task** (`generalPurpose`) para la implementación.
2. Al **terminar con éxito**, el hook **`subagentStop`** (`.cursor/hooks.json`) ejecuta `.cursor/hooks/subagent-clean-arch-review.sh` y envía un mensaje de seguimiento automático al agente principal.
3. El agente principal debe adoptar el rol **Senior Code Reviewer** (`agent-clean-architecture-reviewer.mdc`), revisar el diff y emitir veredicto + feedback para el implementador.
4. Si hay **CAMBIOS REQUERIDOS**, vuelve a delegar en el implementador con ese feedback antes de dar por cerrada la tarea.

Requiere **Python 3** en el PATH para el script del hook. El matcher limita el disparo a subagentes `generalPurpose` (no `explore` / `shell`).

El estándar de código Dart está en `.cursor/rules/rideglory-coding-standards.mdc`.

## Backend y contratos

La API y los paquetes compartidos viven en el repo **`rideglory-api`** (gateway, microservicios, `rideglory-contracts`). Para cambios de contrato, coordina con las reglas `agent-backend-developer.mdc` y `agent-architect.mdc` en ese repo.

## Flujo recomendado

1. Contrato / DTOs acordados entre API y app.
2. Implementación backend en `rideglory-api`.
3. Cliente y UI en este repo, cumpliendo estándares Flutter.
