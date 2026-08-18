---
name: design-system-sync
description: Valida que design-system/rideglory/MASTER.md y los pages/*.md sigan describiendo lo que de verdad hay en rideglory.pen - variables del archivo contra la tabla de tokens, componentes reusable:true contra el inventario, y frames del canvas contra las tablas de pantallas con sus nodeId. Detecta la deriva .md ↔ .pen antes de que alguien implemente contra una descripcion desactualizada.
---

# design-system-sync

Uso: `/design-system-sync` (todo el sistema) o `/design-system-sync <pantalla>` (solo esa pagina).

El `.md` **describe** el diseno; el `.pen` **es** el diseno. Cuando difieren, manda el `.pen` y se corrige el `.md` — nunca al reves. Este flujo encuentra esas diferencias a proposito, en vez de descubrirlas cuando `flutter-dev` implementa contra un token que ya no existe o `pencil-fidelity-reviewer` no puede resolver un `nodeId`.

## Antes de empezar

**Si el MCP de Pencil no responde, detente y avisale al usuario.** Sin leer el `.pen` este flujo no tiene contra que comparar, y "revisar solo los `.md`" produce exactamente la falsa confianza que viene a eliminar. `rideglory.pen` esta encriptado: nunca lo abras con `Read` ni `Grep`.

## Pasos

1. Lee el estado real del archivo con `mcp__pencil__get_app_state` (`include_schema:true`, `include_canvas_design:true`). Ahi salen las variables, los componentes y los frames del canvas.
2. Lee `design-system/rideglory/MASTER.md` y los `design-system/rideglory/pages/*.md` (o solo el de la pantalla indicada).
3. Compara **tres ejes**, y reporta cada diferencia en las dos direcciones (esta en el `.pen` y no en el `.md`, o al reves):
   - **Variables vs. tabla de tokens.** Cada variable de color, tipografia, espaciado y radio del `.pen` debe estar en la tabla de `MASTER.md` con el mismo valor. Presta atencion especial a la paleta Asphalt (`#0A0A0A`, `#161616`, `#1F1F1F`, `#2D2D2D`, primario `#f98c1f`, textos, semanticos) y a los radios 8/12/16/24: un valor que difiere en un digito es la deriva mas cara, porque nadie la nota hasta que un golden falla.
   - **Componentes `reusable:true` vs. inventario.** Cada componente reusable del archivo debe estar inventariado en `MASTER.md` con su proposito. Un componente reusable sin documentar termina duplicado a mano en la siguiente pantalla; un componente documentado que ya no existe manda a `pencil-designer` a buscar algo que no esta.
   - **Frames del canvas vs. tablas de `pages/*.md`.** Cada frame de pantalla debe tener su fila con el `nodeId` correcto en el `.md` de su pagina. Verifica los `nodeId` uno por uno: un `nodeId` obsoleto no rompe nada visible, pero deja la auditoria de fidelidad comparando contra el frame equivocado. Reporta tambien los frames aun marcados 🔖 (trabajo en curso) que ya tienen fila en un `.md`, porque significan un diseno sin aprobar tratado como aprobado.
4. Presenta el resultado agrupado por eje, con las diferencias concretas (nombre, valor en el `.pen`, valor en el `.md`). Cierra con un veredicto claro: **"sincronizado"** o **"N derivas: X tokens, Y componentes, Z frames"** — nada ambiguo.
5. Pregunta al usuario si quiere que se corrijan los `.md`. Este flujo es de verificacion; si acepta, corrige **solo los `.md`** para que reflejen el `.pen`. **Nunca edites el `.pen` para que cuadre con el `.md`**: cambiar el diseno es trabajo de `pencil-designer` via `/pencil-screen`, con aprobacion del usuario.

## Notas

- Si una pantalla del `.pen` no tiene `pages/<pantalla>.md` todavia, no es una deriva: es un diseno sin cerrar. Reportalo como pendiente de `/pencil-screen`, no como error.
- Si aparece una diferencia que parece un cambio de diseno deliberado y no un olvido de documentacion (un componente rediseñado, una pantalla reestructurada), no la absorbas en el `.md` en silencio: senalasela al usuario y deja que decida.
- Corre este flujo antes de una tanda de implementacion de UI, y despues de cualquier cambio grande en el sistema de diseno.
