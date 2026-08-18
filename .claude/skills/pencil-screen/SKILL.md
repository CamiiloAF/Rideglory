---
name: pencil-screen
description: Disena una pantalla de Rideglory dentro de rideglory.pen - pencil-designer la construye reusando el sistema Asphalt, ui-ux-reviewer la audita y anota el canvas, se itera hasta que el USUARIO apruebe explicitamente, y solo entonces se retira la marca de trabajo en curso y se escribe design-system/rideglory/pages/<pantalla>.md.
---

# pencil-screen

Uso: `/pencil-screen <pantalla>` (ej. `/pencil-screen detalle de rodada`, `/pencil-screen SOS activo`).

Nada se implementa en Flutter sin pasar por aqui: el orden del proyecto es toma de requerimientos → diseno en Pencil → implementacion. `rideglory.pen` es la fuente de verdad; los `.md` la describen.

## Antes de empezar

- **Si el MCP de Pencil no responde, detente y avisale al usuario.** No inventes mockups en HTML, ni specs en `.md`, ni "avanzo con una descripcion". Esto ya paso en este proyecto y produjo deriva real.
- `rideglory.pen` esta encriptado: se lee y se escribe **solo** con las herramientas MCP de Pencil, nunca con `Read` ni `Grep`.
- Diseno nuevo, archivo existente: **todas** las pantallas van dentro del `rideglory.pen` que ya existe. Nunca crees un `.pen` nuevo.
- Si la pantalla no corresponde a un problema del backlog de producto (`docs/product/backlog.md`), preguntale al usuario que problema resuelve antes de dibujar nada.

## Pasos

1. Lee el contexto de diseno: `design-system/rideglory/MASTER.md` (globales) y `design-system/rideglory/pages/<pantalla>.md` si ya existe. Precedencia: `pages/<pantalla>.md` → `MASTER.md` → y si cualquiera difiere del `.pen`, **manda el `.pen`** y se corrige el `.md`.
2. **Construye** — delega a `pencil-designer` (via Agent, subagent_type: `pencil-designer`), pasandole la pantalla, el problema que resuelve y cualquier detalle que el usuario haya dado. Exigencias que el skill no negocia:
   - Reusa los componentes `reusable:true` del `.pen` en vez de duplicar estructura, y usa las **variables** del archivo — nunca un hex escrito a mano.
   - Dark-only, paleta Asphalt. No existe tema claro y no se disena ninguno.
   - **Todos los estados obligatorios**, no solo el feliz: contenido, vacio, carga con skeleton (nunca spinner), error accionable con boton de reintentar, y los tres propios de esta app cuando apliquen: sin permiso de ubicacion, sin GPS, sin conexion.
   - Contexto moto: legible bajo sol directo, targets ≥48dp para usar con guantes, comprensible en menos de dos segundos con el casco puesto, operable a una mano, y ninguna interaccion compleja pensada para usarse en marcha.
   - Deja el frame marcado con 🔖 mientras este en curso.
3. **Audita** — delega a `ui-ux-reviewer` (via Agent, subagent_type: `ui-ux-reviewer`): audita la pantalla dentro de Pencil (jerarquia visual, consistencia con Asphalt, WCAG AA, patrones mobile, contexto de uso en moto) y **deja las anotaciones sobre el canvas**, ademas del reporte con veredicto.
4. **Itera.** Los hallazgos del paso 3 vuelven a `pencil-designer`. Repite 2↔3 hasta que el reviewer no tenga hallazgos bloqueantes.
5. **Espera la aprobacion explicita del usuario.** El veredicto del reviewer no es la aprobacion: muestrale al usuario el screenshot del frame y preguntale directamente si lo aprueba. Un "ok, sigue" ambiguo no cuenta — si no es claro, vuelve a preguntar. **No pases a implementacion sin esto.**
6. **Cierra el diseno**, solo despues de la aprobacion:
   - Retira la marca 🔖 del frame (deja de ser trabajo en curso).
   - Escribe `design-system/rideglory/pages/<pantalla>.md` con la tabla de frames y sus `nodeId` — es lo que despues usa `pencil-fidelity-reviewer` para resolver cada golden contra su diseno. Sin esa tabla, la auditoria de fidelidad no tiene como comparar.
   - Si el diseno introdujo un token, un componente reusable o una regla global nueva, actualiza tambien `MASTER.md`, o quedara la deriva `.md` ↔ `.pen` que `/design-system-sync` termina reportando.
7. Cierra diciendole al usuario que la pantalla quedo lista para implementar y que la implementacion se lanza con `/feature-dev`.

## Notas

- `flutter-dev` tiene acceso de **solo lectura** al `.pen`. Escribir en el archivo es exclusivo de `pencil-designer`: si el usuario pide "ajusta el diseno mientras implementas", eso es otra corrida de este skill.
- No implementes Flutter en este flujo, ni siquiera un widget de muestra.
- Los frames muy altos (≈1445px o mas) pueden fallar al exportar por encima de 1x, y `export_nodes` acepta un nodo por llamada. Si un export falla, reintenta antes de concluir que el diseno esta roto.
