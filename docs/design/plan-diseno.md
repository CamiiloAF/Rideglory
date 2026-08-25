# Plan de diseño v2 — orden de trabajo

> Escrito el 2026-08-20. Ordena lo que falta para cerrar el diseño de Rideglory v2 y pasar a implementación.
>
> El criterio del orden no es "por feature" sino **por costo de rehacer**: primero lo que, si se cambia después, obliga a revisar todo lo demás.

## Dónde estamos

| Feature | Estado |
|---|---|
| **Mantenimiento** | Decidido: M5 (pantalla), F2 (registrar), recordatorio en el paso 3 + hoja, D3+ (detalle). **Faltan estados.** |
| **Garaje** | Galería y sus 5 estados, aprobados |
| **Moto — detalle** | `POD7C` aprobada |
| **Moto — alta** | **Sin decidir**: A1 / A2 / A3. Selector de marca ya decidido (S1) |
| **Documentos** | Flujo de subida decidido (elegir origen → cámara → confirmar). Falta el estado de documento vencido |
| **Autenticación** | **Sin decidir**: L1 / L2 |
| **Perfil y cuenta** | **Sin decidir**: P1 / P2. Borrado de cuenta dibujado en 4 pantallas |
| **Eventos** | Sin diseñar, a propósito |
| **Tema oscuro** | Nada. Todo está solo en claro |
| **Identidad** | Sin cerrar formalmente. Todo asume dirección C en dosis baja |

Auditoría del `ui-ux-reviewer` del 2026-08-20 sobre el flujo de Mantenimiento: **veredicto `blocked`**, 4 bloqueantes y 16 sugerencias.

---

## Fase 0 · Lo que contamina todo lo demás

**Por qué primero:** son cambios de sistema, no de pantalla. Hacerlos después obliga a revisar las 70 pantallas otra vez.

1. **Contraste de superficies (S6).** `$c-surface` sobre `$c-bg` da **1.09:1** y `$c-border` sobre blanco **1.26:1**. Toda la estructura de cards se apoya en esa separación y bajo sol directo desaparece. Es cambio de token: se corrige una vez y se propaga a todo.
2. **Urgencia sin depender del color (B1).** En M5 lo vencido, lo de este mes y lo de más adelante se distinguen solo por el color de la cifra: rojo vs ámbar es **1.25:1 entre sí**, y los fondos de sus iconos **1.00:1**. Además «+2.400 km» en español se lee como *faltan*, no como *vencido hace*. Corregir con palabra («Vencido hace 2.400 km» / «En 12 días») e icono distinto para lo vencido.
3. **Contraste del chip de duración (S7).** `$c-accent-soft` sobre `$c-surface`: **1.02:1**. El elemento más valioso del historial no se lee como chip.
4. **Arreglar el subnodo Error del componente de campo (S10).** Hoy tiene bounds 0×624 y `fully clipped` en las 10 instancias. Está desactivado, así que no se nota — el día que se encienda, el mensaje de error no aparece. Es un defecto latente en un componente compartido.

## Fase 1 · Cerrar Mantenimiento

**Por qué segundo:** es la única feature con uso real y recurrente, ya está decidida, y es la que va a validar la arquitectura cuando se implemente.

1. **Estados de M5**: vacío, carga (skeleton, nunca spinner), error accionable, sin conexión. Es el primer destino de la barra: la pantalla que más veces se abre sin datos listos, y el estado vacío es lo primero que ve quien instala la app.
2. **Confirmación de borrado de un registro (B3)**, advirtiendo que se va también su recordatorio.
3. **Caso sin anteriores** en el detalle: con un solo registro del ítem, «ANTES, EN ESTA MOTO» queda vacío. Es el estado normal al empezar.
4. **Rehacer 3 estados sobre el layout de F2**: kilometraje anterior al odómetro, guardando y error al guardar. Hoy están dibujados sobre F3, la variante descartada. El contenido está aprobado; cambia el envoltorio.
5. **Definir el catálogo de ítems de mantenimiento.** No es una pantalla, es la decisión que sostiene la regla «un registro = un ítem»: qué se agrupa (aceite y filtro) y qué se separa (llanta delantera y trasera). Si un ítem agrupa cosas que duran distinto, el chip vuelve a mentir.

**Al terminar esta fase, Mantenimiento se puede implementar** mientras el diseño sigue en las fases siguientes.

## Fase 2 · Decisiones pendientes sin diseño nuevo

**Por qué:** son elegir entre variantes ya dibujadas. Baratas, y desbloquean la Fase 3.

- **Agregar moto**: A1 / A2 / A3 → recomendada A3 (catálogo), que además es la que hace consistente el selector S1 ya aprobado
- **Perfil**: P1 / P2 → recomendada P2
- **Autenticación**: L1 / L2 → recomendada L2

## Fase 3 · Completar lo que gane

- Estados faltantes de las pantallas elegidas en Fase 2
- **Documento vencido** en el visor (hoy solo hay vigente y por vencer)
- Casos vacíos de las filas del garaje con muchas motos (los chips de filtro no escalan a 8 motos, S9)
- Qué hace el icono de filtros del encabezado de M5 (S9)

## Fase 4 · Identidad y tema oscuro

**Por qué al final:** el tema oscuro se hace una sola vez sobre pantallas que ya no van a cambiar. Hacerlo antes es diseñar dos veces.

1. Cerrar formalmente la dirección C y borrar A, B y las pruebas de dosis
2. Tema oscuro de **todo** lo aprobado
3. Verificar en oscuro los mismos contrastes de la Fase 0 — los tokens oscuros son otros valores

## Fase 5 · Eventos

**Bloqueada por producto, no por diseño.** Sigue sin respuesta: *¿qué hace un evento en Rideglory que no haga un mensaje de WhatsApp con hora, punto y link?* Y el tracking en marcha depende del experimento 1 de `docs/product/validacion.md`. Diseñar un CRUD de eventos antes de responder eso es trabajo botado.

## Fase 6 · Escribir el sistema de diseño

`design-system/rideglory/MASTER.md` y `pages/<pantalla>.md` **no existen en disco**. Mientras falten, el `.pen` es la única fuente. Se escriben a medida que cada pantalla queda aprobada; hoy vamos con deuda de todo lo aprobado esta semana.

---

## Cómo proceder

- **Secuencial hasta terminar la Fase 1.** Fases 0 y 1 son cortas y desbloquean todo.
- **Desde la Fase 2, en paralelo:** implementar Mantenimiento mientras se deciden y completan las demás pantallas.
- **Regla que se mantiene:** ninguna pantalla se implementa sin estar aprobada en el `.pen`, y si Pencil no abre, el desarrollo de esa UI se detiene.
