---
name: design-fidelity-check
description: Valida que TODAS las pantallas de una feature de Rideglory coincidan con su diseno en rideglory.pen, usando golden tests como referencia deterministica en vez de un emulador en vivo. qa-automator completa los goldens faltantes y pencil-fidelity-reviewer compara cada uno contra su nodeId. No corrige nada; deja al dia docs/fidelidad-visual-tracking.md.
---

# design-fidelity-check

Uso: `/design-fidelity-check <feature>` (ej. `/design-fidelity-check events`, `/design-fidelity-check vehicles`).

Reemplaza la revision manual en emulador (screenshots por `adb`, comparacion a ojo contra Pencil) por un flujo deterministico: golden tests de Flutter (renderizado real, sin emulador, sin ADB) comparados contra los frames de `rideglory.pen`. Un emulador en vivo es fragil — `adb input tap` deja de responder de forma persistente pese a reinicios completos, y eso ya bloqueo una verificacion visual durante casi toda una corrida. Un golden no depende de ningun dispositivo, corre en segundos y es repetible en CI.

## Pasos

1. **Completar goldens** — delega a `qa-automator` (via Agent, subagent_type: `qa-automator`): generar/actualizar los golden tests de la feature indicada, cubriendo **cada** pagina y sheet bajo `presentation/`, con todos sus estados distinguibles (contenido, vacio, carga, error, y sin permiso de ubicacion / sin GPS / sin conexion cuando apliquen). La app es **dark-only**: no se genera variante clara. Dos condiciones que no son opcionales:
   - Usar el helper compartido `test/support/golden_helpers.dart`, nunca uno duplicado por feature. Ese helper es el que desactiva la descarga en runtime de `google_fonts`; **sin eso los goldens salen con una fuente de fallback en vez de Space Grotesk y toda esta auditoria queda invalidada sin que ningun test falle** — el modo de fallo mas caro de este flujo, porque se ve verde.
   - Correr `flutter test --update-goldens` sobre esa carpeta y confirmar que todo pasa antes de continuar.
2. **Comparar contra Pencil** — delega a `pencil-fidelity-reviewer` (via Agent, subagent_type: `pencil-fidelity-reviewer`): revisar cada `.png` generado en el paso 1 contra su `nodeId` en `design-system/rideglory/pages/<pantalla>.md`, y entregar el reporte por severidad (`CRITICO` / `IMPORTANTE` / `MENOR`) que ya sabe producir. Si el `.pen` no es accesible, **el skill se detiene aqui y lo reporta** — no se aprueba a ciegas contra el `.md` solo (misma regla del gate de Pencil de `feature-dev`).
3. **Presentar el resultado**: un resumen unico, agrupado por pantalla, con los hallazgos del paso 2 mas los dos gaps explicitos que entrega el reviewer (goldens sin fila en el `.md`, pantallas en el `.md` sin golden). Las pantallas con Mapbox son un gap conocido y documentado: el SDK no renderiza el mapa en goldens, asi que se auditan sus overlays aislados (banner de SOS, tarjetas de rider, controles) y el mapa se reporta como gap, no como hallazgo.
4. **No corrijas nada automaticamente** — este flujo es de verificacion, igual que `/safety-check`. Pregunta al usuario si quiere que se apliquen los fixes encontrados; si los pide, es trabajo de `flutter-dev`, no de este skill.
5. Cierra con un veredicto claro por feature: **"fiel a Pencil"** / **"N hallazgos, M gaps de cobertura"** — no dejes la conclusion ambigua.
6. **Actualizar `docs/fidelidad-visual-tracking.md`** (obligatorio: es el unico lugar que consolida el estado de fidelidad entre features): edita la fila de la feature revisada con el veredicto del paso 5.
   - Sin hallazgos `CRITICO`/`IMPORTANTE` pendientes y sin gaps de cobertura → Estado `✅ Aprobada`, fecha de hoy, Fuente apuntando al dev-run/reporte de esta corrida.
   - Con hallazgos aun sin corregir, o con gaps de cobertura → Estado `🟡 Parcial`, y anota en Notas que sigue pendiente.
   - Si el usuario pidio los fixes y `flutter-dev` los aplico dentro de la misma corrida, refleja el resultado *final* (post-fix), no el hallazgo original.
   - Si esta corrida resuelve un pendiente listado en "Pendientes activos" de ese mismo doc, quitalo de esa lista en vez de dejarlo duplicado.
   - Si no existe todavia una fila para la feature, agregala en vez de omitir el paso.

## Notas

- No se engancha automaticamente al workflow `feature-dev` — se invoca a demanda, por feature, cuando se quiera esa garantia extra. `feature-dev` ya trae su propia fase de fidelidad al final; este skill sirve para features viejas, para re-auditar tras un cambio de diseno, o antes de un release.
- Si la pantalla aun no tiene `design-system/rideglory/pages/<pantalla>.md`, dilo como bloqueo antes de invocar a `pencil-fidelity-reviewer`: sin esa tabla no hay como resolver `nodeId` de forma confiable. Cerrar ese `.md` es trabajo de `/pencil-screen`.
- El paso 6 lo hace este skill, no `pencil-fidelity-reviewer` — ese agente es de solo lectura a proposito (nunca escribe el `.pen`, `lib/` ni `test/`). Si la auditoria se corre por fuera de este skill, quien la cierre es igual de responsable de dejar la tabla al dia.
