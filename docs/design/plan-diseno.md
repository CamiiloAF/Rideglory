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

## Fase 0 · Lo que contamina todo lo demás — HECHA el 2026-08-20

**Por qué primero:** son cambios de sistema, no de pantalla. Hacerlos después obliga a revisar las 70 pantallas otra vez.

**Lo que se hizo:**

- **`$c-border` se dividió en dos tokens.** `c-border` (#D6D2CD claro / #3A3A3A oscuro) para divisores internos, donde solo hay que separar filas. **`c-border-strong`** (#9A948E claro / #626262 oscuro) para el límite exterior de cards y controles: ambos valores están calculados para dar **exactamente 3:1** contra su fondo, en su tema. Antes el único borde daba 1.26:1.
- **Contorno aplicado a 60 nodos de superficie** — las pantallas aprobadas y, sobre todo, los componentes reusables, que lo propagan solos. Antes la estructura de cards se sostenía en 1.09:1 de relleno y desaparecía bajo sol.
- **Urgencia con palabra, no solo color.** El subtítulo de cada fila de PRÓXIMOS ahora dice «Honda XR 150 · Vencido» / «· Este mes» / «· Más adelante», y lo vencido cambia su icono de pieza por `triangle-alert`. Se descartó «+2.400 km», que en español se lee como *faltan*. **No se devolvieron los encabezados de grupo**: la palabra cabe en el subtítulo y no cuesta altura, que era el precio que M5 había pagado por fusionarse.
- **Chip de duración con borde de acento.** Separaba de la card por 1.02:1; se leía el texto pero no se percibía como chip.
- **Nodo Error del componente de campo, arreglado.** Tenía `fill_container(0)` y sin `alignItems`, así que colapsaba a 0px de ancho. Verificado: la instancia habilitada ahora mide 350×32 y renderiza.

## Fase 1 · Cerrar Mantenimiento — HECHA el 2026-08-26

**Por qué segundo:** es la única feature con uso real y recurrente, ya está decidida, y es la que va a validar la arquitectura cuando se implemente.

1. **Estados de M5 — HECHO el 2026-08-20.** Vacío (`c3w4HW`), carga con skeleton (`vpUgh`), error accionable (`j45TOh`), sin conexión (`P222KC`). El vacío usa CTA de ancho completo en el cuerpo, no el FAB — mismo patrón que el garaje (`rgLwm`), consistente con el resto de la app: la primera vez, el llamado a la acción va grande y centrado, no en un botón flotante que hay que descubrir. Carga y error reutilizan la convención de skeleton ya establecida en garaje (`pBdbp`).

   *Corregida el 2026-08-26:* el skeleton de carga (`vpUgh`) tenía tres cards sueltas del mismo tamaño y una etiqueta sin agrupar, sin relación con la estructura real de la pantalla. Se rehizo para espejar exactamente los dos grupos de M5: una sola card con tres filas para PRÓXIMOS, y una card por mes para HISTORIAL.

   Se evaluó apilado vs. side-by-side para el vacío. Confirmado apilado, por consistencia con las otras 4 pantallas vacías/error/carga ya aprobadas y porque a 390px de ancho el icono lado a lado tiene que competir por espacio con el texto y baja de 72px a 56px, identificándose más despacio justo en la primera pantalla que ve alguien que instala la app.
2. **Confirmación de borrado de un registro (B3) — HECHA el 2026-08-20.** `eRpHn`, hoja desde «Eliminar registro» en el menú de tres puntos. Advierte explícitamente que se va también el recordatorio asociado: «Se borra Cambio de aceite y filtro del 12 ago 2026, y con él el recordatorio del próximo cambio. No se puede deshacer.» Sin casilla de «entiendo»: esa fricción se reservó para borrar la cuenta completa (`H69H3`), que es legal e irreversible a otra escala; un registro de mantenimiento no necesita el mismo peso.
3. **Caso sin anteriores — HECHO el 2026-08-20.** `wuUsj`. La sección «ANTES, EN ESTA MOTO» se reemplaza por una card con icono y un texto de dos líneas: «Este es el primer registro de este ítem en esta moto. Cuando registres el próximo, aquí verás cuánto te duró.» — dice qué falta y por qué, en vez de dejar el espacio en blanco.
4. **Rehacer 3 estados sobre el layout de F2 — HECHO el 2026-08-20.** Kilometraje anterior (`ljdLM`), guardando (`PPgFL`), error al guardar (`mgxIO`). Corrección de fondo, no solo de envoltorio: el kilometraje anterior no va en el paso 3 como estaba, va en el **paso 2** — es donde vive el campo. Guardando y error sí van en el paso 3, donde está el botón Guardar.
5. **Definir el catálogo de ítems de mantenimiento — CRITERIO CERRADO el 2026-08-26.** No es una pantalla, es la decisión que sostiene la regla «un registro = un ítem»: si dos cosas siempre se cambian juntas y duran lo mismo, son un ítem; si pueden durar distinto, son dos. Aceite + filtro → un ítem. Pastillas de freno delanteras + traseras → un ítem, decisión explícita de Cami. Llanta → **un ítem**, también decisión explícita de Cami: aunque delantera y trasera duran distinto, mantener el catálogo simple pesa más que la precisión del chip en este caso. Queda anotado en el detalle del punto 4 (arriba) el costo aceptado y la salida si algún día molesta.

   **Pendiente, fuera de este plan de diseño:** la lista completa de ítems para motos y repuestos comunes en Colombia. Depende del conocimiento de producto de Cami, no es trabajo de Pencil — es insumo para quien implemente el catálogo en Supabase.

**Al terminar esta fase, Mantenimiento se puede implementar** mientras el diseño sigue en las fases siguientes.

## Fase 2 · Decisiones pendientes sin diseño nuevo

**Por qué:** son elegir entre variantes ya dibujadas. Baratas, y desbloquean la Fase 3.

- **Agregar moto — RESUELTA el 2026-08-26, estados completos.** Gana A2, con el selector S1 integrado. Se descubrió que «Guardando» estaba construido sobre el layout de A1 (ya descartado) y se reconstruyó sobre el layout real de A2; se agregó «Error al guardar», que no existía; se corrigió «Editar moto», que también usaba texto libre para la marca. Falta la limpieza final del canvas (borrar screenshots viejos si quedó alguno, reordenar) — pendiente hasta que no queden más ajustes sueltos.
- **Perfil — RESUELTA el 2026-08-26.** Gana P2 (ficha del rider). Pendiente: estados de P2 y limpieza de P1.
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
