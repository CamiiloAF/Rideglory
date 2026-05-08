# Agentes de desarrollo — Rideglory (Flutter)

Este repo define **sub-agentes** como reglas en `.cursor/rules/agent-*.mdc`. El modelo las puede cargar según archivos abiertos o puedes **mencionar la regla** en el chat si tu cliente lo permite.

## Roles

| Rol | Regla | Uso típico |
|-----|--------|------------|
| **Flutter dev** | `agent-flutter-developer.mdc` | Pantallas, Cubits, datos, navegación, widgets |
| **Arquitecto** | `agent-architect.mdc` | Revisión de PR, límites de capas, lints, escalabilidad |
| **DevOps** | `agent-devops.mdc` | YAML de tooling, CI/CD cuando exista |

El estándar de código Dart está en `.cursor/rules/rideglory-coding-standards.mdc`.

## Backend y contratos

La API y los paquetes compartidos viven en el repo **`rideglory-api`** (gateway, microservicios, `rideglory-contracts`). Para cambios de contrato, coordina con las reglas `agent-backend-developer.mdc` y `agent-architect.mdc` en ese repo.

## Flujo recomendado

1. Contrato / DTOs acordados entre API y app.
2. Implementación backend en `rideglory-api`.
3. Cliente y UI en este repo, cumpliendo estándares Flutter.
