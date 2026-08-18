---
name: e2e-run
description: Corre las suites Patrol e2e ya escritas de Rideglory (integration_test/) contra un emulador o simulador booteado, delegando en patrol-e2e-runner, y deja al dia docs/patrol-e2e-tracking.md. Nunca contra la base de produccion.
---

# e2e-run

Uso: `/e2e-run [feature]` (ej. `/e2e-run`, `/e2e-run events`). Sin argumento, corre todas las suites Patrol existentes.

## Antes de empezar: la regla que aborta

**Si la corrida fuera a apuntar a produccion, detente.** Verificalo tu, antes de delegar: la app debe correr con el flavor `dev` y contra **Supabase local** (`supabase start`). Una suite e2e contra produccion no "ensucia datos": crea eventos, inscripciones y usuarios reales, y en esta app puede disparar notificaciones a personas de verdad. Si la configuracion apunta al proyecto remoto, o no puedes confirmar a donde apunta, **aborta y avisale al usuario** — no corras "solo para ver".

## Pasos

1. Confirma que hay un device disponible: `adb devices` para Android, `xcrun simctl list devices booted` para iOS. Si no hay ninguno booteado, intenta arrancar uno (`flutter emulators`, `flutter emulators --launch <id>`) antes de concluir que no se puede.
2. Confirma el destino de datos (flavor `dev`, Supabase local corriendo). Ver la regla de arriba.
3. Delega la ejecucion al subagente `patrol-e2e-runner` (via Agent, subagent_type: `patrol-e2e-runner`), indicandole el alcance (feature o todas) y el device. Ese agente **solo ejecuta y reporta**: no escribe tests nuevos ni toca `lib/` — escribir suites es trabajo de `qa-automator`.
4. Presenta el resultado por feature y por escenario: `pass` / `fail` / `skip`, con el device usado. Para cada fallo, distingue si es un **defecto de la app** o una **suite fragil** (timing, dato de prueba faltante, permiso no concedido). No los mezcles: un e2e fragil reportado como bug quema tiempo, y un bug reportado como fragilidad se queda en el codigo.
5. Un `skip` nunca pasa en silencio: di por que se salto y que haria falta para correrlo.
6. **Actualiza `docs/patrol-e2e-tracking.md`** (obligatorio): estado por suite, fecha (`date -u +%Y-%m-%d`), device usado y notas de los fallos. Si esta corrida resuelve un pendiente listado ahi, quitalo en vez de dejarlo duplicado. Si el archivo no existe todavia, crealo con esa tabla.
7. **No corrijas los fallos en esta corrida.** Presentalos y pregunta al usuario si quiere que se arreglen: los defectos de la app son de `flutter-dev`, las suites fragiles son de `qa-automator`.

## Notas

- Si no existe ninguna suite Patrol para el alcance pedido, dilo tal cual y sugiere `/feature-dev` (que escribe e2e como parte de su fase de Test) o una corrida de `qa-automator`. No improvises una suite aqui.
- Los permisos de ubicacion son parte del flujo real de esta app: si una suite falla por un dialogo de permisos del sistema, eso es Patrol haciendo su trabajo — revisa como los maneja la suite antes de marcarlo como bug.
