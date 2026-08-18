---
name: new-feature
description: Crea la estructura Clean Architecture (domain/data/presentation) para una nueva feature de Rideglory en lib/features/<nombre>/, con DI injectable, ruta en go_router y keys en app_es.arb, y la revisa con rideglory-code-reviewer antes de darla por lista.
---

# new-feature

Uso: `/new-feature <nombre>` (ej. `/new-feature tracking`).

Objetivo: dejar creada la estructura minima y correcta de una feature nueva, sin que Claude tenga que redescubrir la convencion cada vez.

## Pasos

1. Lee `CLAUDE.md` en la raiz del repo (arquitectura y reglas de tolerancia cero) si no lo tienes ya en contexto.
2. Si el argumento `<nombre>` no viene, pregunta cual es antes de continuar. El nombre de la carpeta va en **ingles** (`events`, `vehicles`, `tracking`), aunque toda la UI sea en espanol.
3. Verifica si `lib/features/<nombre>/` ya existe con contenido mas alla de `.gitkeep`. Si es asi, no sobrescribas — reporta lo que ya hay y pregunta si continuar.
4. Delega la generacion completa al subagente `feature-scaffolder` (via Agent, subagent_type: `feature-scaffolder`), pasandole el nombre de la feature y cualquier detalle de dominio que el usuario haya dado (campos, relaciones con otras tablas, acciones de negocio esperadas). El scaffold cubre las tres capas: modelos puros e interfaces con `Either<DomainException, T>` en `domain/`, DTOs y datasources de Supabase en `data/`, y cubit `@injectable` sobre `ResultState<T>` mas pagina minima en `presentation/`, con el registro de DI, la ruta en `go_router` y las keys en `lib/l10n/app_es.arb`.
5. Cuando el subagente termine, revisa su resultado con el subagente `rideglory-code-reviewer` (via Agent, subagent_type: `rideglory-code-reviewer`) antes de reportar exito al usuario. Es de solo lectura: si reporta violaciones, las correcciones las aplica `feature-scaffolder` o `flutter-dev`, no el reviewer.
6. Resume al usuario: archivos creados, y los pendientes tipicos — la migracion SQL con sus politicas RLS en `supabase/migrations/` (via `/db-migration`), el diseno de las pantallas en Pencil (via `/pencil-screen`, sin el cual no se implementa UI real), los tests, y si la feature toca SOS, ubicacion o datos sensibles, sugerir tambien `/safety-check`.

No implementes la logica de negocio real de la feature en este flujo — el scaffold es boilerplate estructural (modelos, interfaces, casos de uso con TODOs razonables, cubit con estados basicos). La logica especifica se construye despues, con `/feature-dev`, sobre esta base.
