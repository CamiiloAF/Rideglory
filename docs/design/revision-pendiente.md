# Revisión de diseño — pendiente de decisión

> **El canvas se reorganizó el 2026-08-20.** Ya no es una sola tira horizontal: hay **nueve filas, una por feature**, cada una rotulada a la izquierda. De arriba abajo: Identidad · Autenticación · Garaje · Moto (detalle y alta) · Documentos · Mantenimiento (pantalla principal) · Mantenimiento (registrar) · Mantenimiento (recordatorio y detalle) · Perfil y cuenta. Los componentes reusables siguen arriba de todo.
>
> Se borraron 22 nodos descartados: las seis exploraciones de garaje A–E con sus tesis y marcadores, y las variantes S2 y S3 del selector de marca. Quedan **72 pantallas**.

> Trabajo de la noche del 2026-08-19, con las correcciones de la mañana del 2026-08-20. Todo vive en `rideglory.pen`; acá solo están los `nodeId` para que abra Pencil y vaya decidiendo.
>
> **Cómo revisar:** no busque la que más le guste. **Descarte.** Con eliminar dos de cada grupo, la decisión sale sola.
>
> Los frames marcados 🔖 están en revisión. Lo aprobado no lleva marca.

## Ya aprobado (no se toca)

| Pantalla | nodeId |
|---|---|
| Detalle de moto, con Documentos en fila ancha | `POD7C` |
| Garaje — galería de 2 columnas | `V02g9` |
| Garaje — sin foto y nombre largo (icono centrado 2026-08-20) | `ZSjcI` |
| Garaje — vacío | `rgLwm` |
| Garaje — carga | `pBdbp` |
| Garaje — sin conexión | `ZSUKH` |
| Garaje — 8 motos (icono centrado 2026-08-20) | `NQnlL` |

**16 componentes reusables** en la parte de arriba del canvas: tab bar, botones, **FAB** (`Q7Mkr`, nuevo el 2026-08-20), chips de estado, header, bloque de odómetro, celda de moto, fila de registro, campo de formulario, selector de moto, chip de sugerencia, switch, fila de ajuste y banner. Cambiar uno cambia todas las pantallas.

---

## Aplicado el 2026-08-20, ya no es decisión

- **Estados del garaje centrados.** `rgLwm` y `ZSUKH` centran el contenido en el cuerpo, y el icono perdió el recuadro de superficie que lo hacía leer como una celda más de la galería —la confusión con el card de agregar moto.
- **El botón amarillo de ancho completo sale de Mantenimiento.** Lo reemplaza un FAB (`Q7Mkr`, 64dp con contorno oscuro) en `uW3OI`, `n1AmaQ`, `KucgY` y `cZCI4`. Devuelve unos 80px de alto por pantalla. El contorno no es decorativo: el amarillo sobre fondo blanco queda en 1.4:1 y no alcanza el 3:1 que WCAG pide para el límite de un control.
- **F2 pasa de 4 pasos a 3**, y el tercero dejó de ser un paso más de preguntas: es la hoja de detalles opcionales al estilo de F3 (`FzCw2`).
- **El kilometraje menor al odómetro dejó de ser un error.** el estado *Kilometraje anterior al odómetro* (hoy `ljdLM`, reconstruido sobre F2 el 2026-08-20) y avisa en gris que es un registro anterior y que el odómetro no cambia. Guardar queda habilitado.
- **Documentos: elegida la opción (b).** Ver más abajo.

---

## Decisión 1 · Mantenimiento — RESUELTA el 2026-08-20

**Gana M5 — Agenda + Historial** (`V3B6C`). Arriba PRÓXIMOS con lo vencido, lo de este mes y lo de más adelante; abajo HISTORIAL por meses. Es el primer destino de la barra y lo primero que se ve al abrir.

M1 (Agenda), M2 (Historial), M3 (Por pieza) y M4 (Por moto) se borraron del canvas con sus estados vacíos, tesis y marcadores.

**El precio que quedó vivo:** al fusionar se perdieron los encabezados VENCIDO / ESTE MES, así que la urgencia vive **solo en el color de la cifra** —rojo, ámbar, neutro—. Hay que verificarlo bajo sol directo. Si no se lee, se devuelven los encabezados y la pantalla crece.

**Pendiente inmediato:** M5 no tiene estado vacío, ni de carga, ni sin conexión. Los cuatro que se borraron sí los tenían.

## Decisión 2 · Los intervalos por pieza — RESUELTA a medias el 2026-08-20

Las tres opciones originales eran: fijos por catálogo, editables, o inferidos del historial. La pregunta de Cami —«¿en qué punto de la app se crea el mantenimiento futuro?»— las reencuadra: **no son excluyentes, son la misma cosa en momentos distintos**, y lo que faltaba era el *dónde*.

**Respuesta: el intervalo se ofrece al guardar el mantenimiento, y viene apagado** (`u8CzY` apagado · `YwX8r` encendido). Al terminar de registrar, la pantalla confirma que quedó guardado y ofrece —sin obligar— avisar del próximo. El interruptor está **apagado por defecto**; al encenderlo aparecen los dos campos, prellenados con «cada 7.500 km **o** cada 12 meses, lo que se cumpla primero». La acción principal es **«Listo»**, no «Programar».

Una primera versión ponía los campos ya llenos y un botón amarillo «Programar el próximo», con la salida escondida en una X. Cami lo señaló: eso lo lee cualquiera como obligatorio. La jerarquía está invertida a propósito — terminar es el camino ancho; programar es un desvío que se toma quien quiera.

Por qué ahí y no en un menú de ajustes: es el único momento en que el dato ya está en la cabeza del usuario —acaba de cambiar el aceite y sabe cada cuánto lo cambia—. Una sección «Intervalos» en configuración es trabajo que nadie hace, y sin ella la agenda queda vacía o equivocada, que es exactamente por lo que M1 se descartó como pantalla de entrada.

Las tres opciones originales quedan así:

- **Inferido del historial** — es el *prellenado* de esa pregunta, no un modo aparte.
- **Catálogo** — es el respaldo para el **primer** registro de una pieza, cuando todavía no hay «la anterior duró».
- **Editable** — sigue siendo necesario, y es lo único que falta ubicar (ver abajo).

**El costo asumido:** apagado por defecto significa que mucha gente nunca lo activará y su agenda quedará vacía. Se acepta a cambio de no imponer. Si más adelante la agenda resulta estar siempre vacía, la palanca a mover es el texto de esa fila —o proponer el interruptor ya encendido a partir del segundo registro de la misma pieza, cuando la app ya sabe cuánto duró—, no volverlo obligatorio.

**El dato son dos dimensiones, no una:** kilómetros **y** tiempo, y se avisa con lo que llegue primero. Un aceite cada 7.500 km vence igual al año aunque la moto no se mueva. Cualquier modelo que guarde solo el kilometraje está mal desde la base.

### Dónde vive el interruptor — dos opciones sobre la mesa (2026-08-20)

| | Dónde | nodeId |
|---|---|---|
| **PROG-A** | Fila del paso 3 del formulario, bajo su encabezado RECORDATORIO. Se guarda todo de una | `g3rONd` |
| **PROG-B** | Pantalla aparte tras guardar, con la propuesta prellenada y **Omitir** al mismo peso que Programar | `FNk38` |

*(La tercera, ya construida: pantalla aparte con el interruptor apagado y «Listo» como acción principal — `u8CzY` apagado, `YwX8r` encendido.)*

**Recomendación: PROG-A.** El argumento que la decide no es de estilo: **en F2 no se puede guardar sin pasar por el paso 3**, porque ahí vive el botón Guardar. Eso le da a A exactamente la misma visibilidad que una pantalla aparte, sin cobrar la pantalla. B paga un peaje en cada registro para comprar algo que A ya tiene gratis.

Dos condiciones para que A funcione:

1. **El recordatorio no puede ser un campo más.** Los otros cuatro —fecha, taller, costo, nota— describen lo que ya pasó; este agenda lo que viene. Por eso va bajo su propio encabezado RECORDATORIO y separado, no en la fila siguiente a «Nota».
2. **A depende de que F2 haya ganado.** Si el formulario volviera a ser de una sola pantalla, el paso 3 desaparece y toca irse a B.

**Si prefiere B**, condiciónela: que la pantalla **solo aparezca cuando esa pieza todavía no tiene intervalo**. Sin eso se convierte en el peaje que usted mismo describió con las notificaciones — «unas cinco, ya se vuelve cansón» — y la gente aprende a darle Omitir sin leer, que es peor que no preguntar.

### Resuelto: el formulario no crece, y editar es la misma hoja (2026-08-20)

Dos objeciones de Cami sobre PROG-A: que activar el interruptor metiera dos campos más en un formulario ya largo, y que no estuviera claro cómo se edita el intervalo después. Las dos se resuelven con la misma pieza.

**El interruptor no despliega campos** (`B8OGu`). Al activarlo, la fila no crece: solo cambia su subtítulo de «Opcional. Está apagado» a «Cada 7.500 km o 12 meses · toca para cambiar». El formulario mide exactamente lo mismo encendido que apagado.

**Los números viven en una hoja aparte** (`Z6b3T`, **aprobada el 2026-08-20**): los dos campos y Guardar. Nada más.

**Ninguno de los dos es obligatorio: con uno basta.** Se puede programar solo por kilómetros, solo por fecha, o por ambos —y ahí sí avisa con el que se cumpla primero—. La nota de la hoja lo dice explícitamente. Para la implementación: los dos campos son opcionales por separado, pero **al menos uno** debe tener valor para que el recordatorio exista.

*Corregido el 2026-08-20:* la hoja tenía además «Quitar recordatorio» en rojo. Cami dijo que algo no le cuadraba y señaló ese botón. Tenía razón por dos motivos: una acción destructiva no puede compartir peso visual con la principal en una hoja de 330px, y sobre todo **era redundante** — el interruptor de la fila ya apaga el recordatorio. Eran dos formas de hacer lo mismo, que es justo lo que esta hoja existe para evitar. Apagar es del interruptor; la hoja solo pone los números.

**Y esa hoja es la misma para crear y para editar.** Es la respuesta a la pregunta de cómo se ve al editar: **igual que al crearlo**. Una sola pantalla que se abre desde el formulario al activar el interruptor, y desde la lista de recordatorios de la moto. No hay dos formas de tocar el mismo dato.

**El punto de entrada para editar es el detalle del mantenimiento** (`PF1QF`), no una lista de intervalos por pieza.

*Corregido el 2026-08-20.* Yo había hecho «Recordatorios · Yamaha MT-03»: una lista de piezas de la moto, cada una con su intervalo, como si el recordatorio fuera una regla global del tipo de mantenimiento. Cami lo rechazó con el argumento correcto: **el recordatorio va enlazado a un mantenimiento concreto**, no a «todos los mantenimientos de cierto tipo». El próximo cambio de aceite sale de *este* cambio de aceite —18.450 km + 7.500—, no de una configuración aparte.

Eso mata la lista y destapa un hueco que llevaba rato ahí: **no existía la pantalla de detalle de un mantenimiento registrado**. Las filas del historial tenían chevron y no llevaban a ninguna parte. Ahora `PF1QF` es esa pantalla: qué se hizo, en qué moto, cuándo y a cuántos km; taller, costo y nota; el bloque RECORDATORIO con su interruptor —que abre la hoja `Z6b3T`—; y eliminar el registro.

**Una consecuencia que hay que decidir en el modelo de datos:** si el recordatorio pertenece al registro, al registrar un nuevo cambio de aceite el recordatorio del anterior tiene que **reemplazarse**, no acumularse. De lo contrario aparecen dos «próximo cambio de aceite» compitiendo. Está escrito en la propia pantalla para que no se pierda.

## Decisión 2b · El chip de duración — RESUELTA el 2026-08-20

El chip «La anterior duró 9.800 km» es lo más valioso del historial y a la vez lo más fácil de volver mentira. Cami: *«¿qué pasa si en un mismo registro digo que cambié las 2 llantas? Muchas veces la delantera dura el doble que la trasera.»*

**Regla adoptada: un registro = una pieza, siempre.** Si cambió las dos llantas, quedan **dos registros**, cada uno con su kilometraje, su duración y su chip. Nunca hay un chip que promedie cosas que no se pueden promediar.

Se descartó la alternativa que había construido —registro con varias líneas de pieza, chip neutro cuando hay más de una— y con ella las pantallas `T2p7u` (detalle multi-pieza) y `x2mVfl` (paso 3 con dos piezas), ya borradas.

**Lo que esto obliga en el catálogo, y es la letra pequeña:** «Cambio de aceite **y filtro**» tiene que ser **un solo ítem del catálogo**, no dos. La regla no es «un registro = un objeto físico», es «un registro = un ítem del catálogo». El catálogo decide qué se cambia junto —aceite y filtro se cambian siempre juntos, luego son un ítem— y qué se cambia por separado —llanta delantera y llanta trasera son dos ítems, porque duran distinto—.

Ese es todo el trabajo de diseño que queda del asunto: **definir el catálogo de ítems**. Si un ítem agrupa cosas que duran distinto, el chip vuelve a mentir por otra vía.

**Ventaja secundaria:** el recordatorio queda trivial. Un registro genera como mucho un recordatorio, y la hoja `Z6b3T` —una pieza, dos campos— nunca necesita representar varios intervalos.

## Decisión 3 · Registrar mantenimiento — RESUELTA el 2026-08-20

**Gana F2 — Por pasos**, en tres pasos, con el recordatorio en el paso 3 y el bottom sheet para los números.

| Pantalla | nodeId |
|---|---|
| Paso 1 · qué se hizo | `Yhgp2` |
| Paso 2 · a cuántos km | `x74Sa` |
| Paso 3 · detalles + RECORDATORIO apagado | `g3rONd` |
| Paso 3 con el recordatorio activado (no crece) | `B8OGu` |
| Hoja de intervalo — crear y editar | `Z6b3T` |

F1 (formulario completo), F3 (mínimo primero) y F4 (desde plantilla) se borraron con sus tesis y marcadores. También PROG-B (pantalla aparte con Omitir) y las dos variantes de pantalla-aparte-con-interruptor: al vivir el interruptor dentro del paso 3, no hacen falta.

Estados aprobados el 2026-08-20, reconstruidos el mismo día sobre el layout real de F2 (ya no sobre F3, la variante descartada):

| Estado | Vive en | nodeId |
|---|---|---|
| Kilometraje anterior al odómetro | Paso 2 (`x74Sa`), donde está el campo | `ljdLM` |
| Guardando | Paso 3 (`g3rONd`), donde está el botón Guardar | `PPgFL` |
| Error al guardar | Paso 3 (`g3rONd`) | `mgxIO` |

**Corrección de fondo, no solo de envoltorio:** el kilometraje anterior no vivía en el paso 3 como se había construido primero — vive en el **paso 2**, porque ahí es donde se escribe el número. Guardando y error sí son del paso 3, porque ahí está el botón que dispara el guardado.

**El indicador de guardado se queda como está** (`e5fWGR`): botón «Guardando…» con barra de progreso interna. Se evaluaron el guardado optimista sin loader —cerrar y mostrar el registro ya en el historial, con encolado y reintento si falla—, una barra fina en el borde superior de la pantalla, y el botón mutando a un check. Decisión de Cami: dejarlo como está.

## Decisión 8 · Detalle del mantenimiento — RESUELTA el 2026-08-20

**Aprobada D3+ «Comprobante con historia»** (`b8WMj1`), fusión de D3 y D2. Se borraron D1 (ficha de datos), D2 (historia de la pieza) y D4 (la duración primero) con sus tesis.

Cómo quedó, de arriba abajo: encabezado con el nombre del ítem y los tres puntos · el kilometraje como cifra protagonista con moto y fecha · taller, costo y nota como líneas de recibo · «ANTES, EN ESTA MOTO» con los tres cambios anteriores del mismo ítem, su duración y «Ver 5 más» · el promedio · el recordatorio con su interruptor.

| Estado | nodeId |
|---|---|
| Detalle | `b8WMj1` |
| Lista de anteriores expandida | `O6Kp4` |
| Hoja de acciones (editar / eliminar) | `yZ3We` |

### La lista de anteriores

Muestra **tres** y «Ver 5 más» **expande en la misma pantalla** — no navega. Tres y no dos: con dos duraciones solo se ve una comparación y no se sabe cuál es la rara; con tres se lee un patrón. El promedio resume lo que no se muestra. El botón dice el número para no obligar a tocar solo para averiguar cuánto hay detrás. Cada fila anterior abre el detalle de ese mantenimiento.

**La altura de la pantalla no crece con el historial**, que era el requisito de Cami.

### Editar y eliminar: menú de tres puntos

Se quitó «Eliminar registro» del final del scroll. Tres razones: editar estaba en el encabezado y eliminar al final, dos acciones sobre el mismo objeto en extremos opuestos; el final de una pantalla no debe ser una acción destructiva, menos con una lista que se expande; y el lápiz suelto era ambiguo —¿editar qué?—.

Se paga un toque más para editar y que las acciones no estén a la vista. Aceptable: editar o borrar un registro pasado se **busca** cuando hace falta, y los tres puntos son donde se busca.

**Nota de implementación:** el icono es `ellipsis-vertical`; `more-vertical` no existe en esta librería y renderiza un glifo equivocado.

### La foto de la factura: fuera de la v2

Quitada de D3+. El motivo **no es el costo de almacenamiento**: una factura comprimida pesa ~250 KB y a seis servicios al año son ~1,5 MB por usuario por año — con cien usuarios, 150 MB anuales, que caben de sobra en el plan gratuito de Supabase Storage durante años.

Lo que la mata es lo que observó Cami: **en el formulario no se pide en ningún lado**. Si el único punto de captura es entrar al detalle y tocar «agregar», casi nadie lo hará — es lo que ya pasó con el contacto de emergencia, que solo se podía fijar al inscribirse a una rodada y quedó vacío para todos.

Y arrastra costos que no son de disco: la factura lleva datos del taller y a veces la placa, o sea tratamiento de datos de terceros bajo Ley 1581; obliga a borrado real en Storage al eliminar el registro o la cuenta; y suma permisos de cámara y galería, compresión y manejo de fallos de subida.

**Si algún día entra, el lugar es el paso 3 del formulario**, al lado de Costo — no una acción suelta en el detalle.

### Pendientes de esta pantalla

- **Confirmación de borrado** (bloqueante B3 del reviewer), que debe advertir que se va el recordatorio asociado.
- **Caso sin anteriores**: con un solo registro del ítem, la sección «ANTES, EN ESTA MOTO» queda vacía.
- Carga y error accionable.

## Decisión 4 · Agregar moto — RESUELTA el 2026-08-26

**Gana A2 — Empieza por la placa.** Un ancla concreta antes del formulario: primero la placa (`KIdCH`), validada contra el formato real; luego el resto de los datos (`e0fmR`). Descartadas A1 (todo en una pantalla) y A3 (catálogo de marcas como paso 1) — ambas marcadas ❌.

**El giro respecto a la recomendación original:** yo había recomendado A3 porque protegía el dato de marca a futuro. Cami la revirtió: **A2 se queda, pero su campo de marca deja de ser texto libre y usa el selector S1 ya aprobado** (`LHKHl`). Así A2 gana en lo que importaba de A3 —la marca entra normalizada— sin heredar su arquitectura completa. El campo `Marca` en `e0fmR` ahora lleva chevron y abre `LHKHl` al tocarlo.

**La línea (MT-03, GN 125) sigue siendo texto libre.** Es la advertencia que ya estaba en la Decisión 4b: es la mitad peor del problema de normalización, y no se resuelve con este cambio.

### El selector de marca, mejorado (2026-08-26)

Cami pidió mejorar la lista (`o6ds2` → ahora `DJNkr`). Cambios:

- **Avatar circular con la inicial de la marca**, en vez de texto plano. No es un logo —esos siguen pendientes como asset— pero da un ancla visual sin comprometerse a una identidad de marca que la app no tiene autorización de usar.
- **Chevron en cada fila**, no solo en la seleccionada. Antes ninguna fila insinuaba que era tocable salvo por estar en una lista; ahora la afordancia es explícita.
- **La fila seleccionada tiene fondo propio** (`$c-accent-soft`, esquinas redondeadas), no solo negrita y un check. Se distingue de un vistazo, no leyendo.

Se ajustó la altura de la hoja (`nh848`) porque las filas más altas (60px, antes 56px) se salían del cálculo original por 31px.

*Ajustado el 2026-08-26:* se quitaron los divisores entre filas. Con el avatar y el padding nuevo, cada fila ya se distingue sola; el divisor sobraba.

**A1 y A3 se borraron del canvas** —pantallas, tesis y marcadores— y la fila de Moto se reordenó sin huecos.

### Estados de Agregar moto — HECHOS el 2026-08-26

`IPfLr` («Agregar moto — Guardando») resultó estar construido sobre el layout viejo de A1, la variante ya descartada: secciones IDENTIDAD/FICHA TÉCNICA en una sola pantalla, en vez del flujo de dos pasos de A2. Se reemplazó.

| Estado | nodeId |
|---|---|
| Guardando (sobre el layout real de A2, paso 2) | `M2i66X` |
| Error al guardar — nuevo, no existía | `sH7QQ` |

De paso, **«Editar moto» (`tbZKM`) tenía el mismo problema**: campo Marca en texto libre, sin el selector S1. Se le agregó el chevron para que abra `LHKHl`, igual que en `e0fmR`.

Fila de Moto reordenada sin huecos: `POD7C` → `KIdCH` → `ruRle` → `e0fmR` → `LHKHl` → `tbZKM` → `M2i66X` → `sH7QQ`.

## Decisión 5 · Perfil

| | nodeId |
|---|---|
| **P1 — Lista de ajustes** | `BS3wJ` |
| **P2 — Ficha del rider** | `iFssW` |

Contacto de emergencia: `FNOK0`.

**RESUELTA el 2026-08-26: gana P2.** El descubrimiento encontró que el contacto de emergencia hoy solo se puede fijar inscribiéndose a una rodada, y que la pantalla de perfil estaba rota. En una lista de ajustes queda condenado a no llenarse nunca; P2 lo destaca con un banner de advertencia hasta que exista, conectando directo con la regla de seguridad del rider: el SOS necesita ese contacto cacheado antes de la rodada, no leído en la emergencia.

### Estados de P2 — HECHOS el 2026-08-26

Skeleton agrupado por sección (`ZhLW3`): identidad, banner de emergencia, motos y ajustes, cada bloque en el lugar donde después aparece su contenido real — mismo criterio que se corrigió en el skeleton de M5. Error (`iWE6o`) y sin conexión (`HGJYs`) con el patrón centrado ya estándar en la app.

**Feature Perfil completa: decisión + estados.** Falta la limpieza de `BS3wJ` (P1, descartada) del canvas.

### Revisor sobre todo lo de hoy — HECHO el 2026-08-26, veredicto `blocked` → corregido

Auditó Mantenimiento, Agregar/Editar moto y Perfil completos, más el componente `Jiqal`. Dos bloqueantes, los dos corregidos:

1. **Botón "Sí, eliminar" con contraste real de 2.8:1** (`eRpHn`/`PQXRU`): texto blanco hardcodeado sobre `$c-error-text`, que en tema oscuro es un rojo *claro* (#F87171) — pensado para texto sobre fondo oscuro, no para ser fondo de un botón. **El mismo defecto ya existía en dos pantallas aprobadas antes de hoy**: «Sí, borrar mi cuenta» (`H69H3`/`LQl0E`) y «Continuar con el borrado» (`MCSBy`/`JygI0`). Fix sistémico: nuevo token **`$c-error-solid`** (`#B91C1C` fijo en ambos temas, no cambia como `$c-error-text`) para fondo, y texto con `$c-plate-text` (`#FAFAFA` fijo) — contraste real ≈8.2:1. Aplicado a los tres botones.
2. **`stroke:"$c-border"` en 4 instancias del bloque "Placa confirmada"** (`e0fmR`, `LHKHl`, `M2i66X`, `sH7QQ`) — se escapó de la Fase 0 porque el bloque no es un componente reusable, es un frame copiado y pegado cuatro veces. Corregido a `$c-border-strong` en las cuatro. **Pendiente real:** convertir "Placa confirmada" en componente para que esto no vuelva a pasar.

Hallazgos menores sin corregir todavía: reutilizar el componente `HYvT4` en los botones de `c3w4HW`/`j45TOh`/`P222KC`/`iWE6o`/`HGJYs` en vez de reconstruirlos a mano; el selector `LHKHl` sin divisores tiene la fila seleccionada con padding distinto al resto (desalinea el avatar) y sin separador visual entre marcas consecutivas; los 4 scrims de hoja (`yZ3We`, `eRpHn`, `Z6b3T`, `LHKHl`) usan `#0A0A0AB3` hardcodeado — vale la pena un `$c-scrim` si el patrón se sigue repitiendo.

### Componente nuevo: Botón guardando (2026-08-26)

`Jiqal`, con ícono (apagado por defecto) y barra de progreso (encendida por defecto) toggleables por separado. Reemplaza dos implementaciones sueltas e idénticas que existían en Mantenimiento (`PPgFL`) y Agregar moto (`M2i66X`) — la deriva que las reglas de componentes de la app buscan evitar.

Tres variantes en comparación (`xI4Cz` V1-barra, `U0xKCf` V2-ícono, `Rcdob` V3-ambos), sin decidir. Recomendación: **V1**. El ícono `loader-circle` está pensado para animarse; congelado en un mockup se lee como un glifo roto, no como carga. Conecta con la regla de «nunca spinner» que ya rige los estados de página completa.

## Decisión 6 · Autenticación

| | nodeId |
|---|---|
| **L1 — Social primero** | `olYdj` |
| **L2 — Bienvenida con propósito** | `tp9oS` |

Correo `ROAHx` · error `xTYYm` · recuperar contraseña `CBfOH`.

**Recomendación: L2**, con una condición: sus tres promesas tienen que ser verdad en la v1.

## Decisión 7 · Documentos (menor)

`POD7C` ya está aprobada. Falta autorizar borrar las descartadas: `zRvqo` y `tl1jJ`.

**Decidido el 2026-08-20: la opción (b).** Subir un documento arranca preguntando el origen —foto, galería o PDF— en vez de abrir la cámara de una.

Ojo con una lectura fácil: elegir (b) **no descarta** la pantalla de cámara. Pasa a ser el paso 2, el destino de «Tomar foto». El flujo quedó marcado así en el canvas:

1. `R9ZYe` — elegir origen
2. `rbRuw` — cámara con el marco guía
3. `MG790` — confirmar y guardar

Sin variantes: visor `tu2U6` · visor sin conexión `P5GIm` · sin subir `dB4Au`.

---

## Decisiones de producto, no de diseño

**Eventos.** No se diseñó nada, a propósito. Sigue sin respuesta la pregunta del backlog: *¿qué hace un evento en Rideglory que no haga un mensaje de WhatsApp con hora, punto y link?* Diseñar un CRUD de eventos antes de responderla es trabajo botado.

**La app como red social.** Planteada el 2026-08-19 y pospuesta. Cambia el alcance entero. Lo que la destrabaría está en [`../product/validacion.md`](../product/validacion.md): una conversación con un organizador de rodadas de marca.

**"Tecno"** como abreviatura de tecnomecánica: ¿es la palabra que usa la gente, o una invención nuestra?

**Marca.** `Rideglory` está escrito en tipografía, no hay logo. Y los botones de Google y Apple llevan un relleno gris de andamiaje: faltan los assets oficiales, que tienen reglas propias de uso.

---

## Pendientes de diseño ya identificados

- **Tema oscuro de todo.** Lo construido desde la dirección C está solo en claro. Hay un problema conocido: `c-block` `#1A1A1A` casi se funde con el fondo `#0C0C0C`.
- **Identidad visual sin cerrar formalmente.** Los 6 frames de dirección (A, B, C claro y oscuro) siguen en el canvas. Todo lo demás ya asume C en dosis baja.
- **Carga y sin conexión** de la pantalla de mantenimiento que gane.
- **Documento vencido** en el visor: hoy solo hay vigente y por vencer.
- Qué pasa al tocar el chip de pendiente en la galería, y el orden de la cuadrícula.

## Dos defectos que se corrigieron de paso

Valen para quien implemente: un `descendants` **anidado** dentro de otro no se aplica en Pencil — la ruta correcta es `"Switch/Knob"`. Y el switch apagado usaba `c-border` como pista, lo que dejaba un knob blanco a **1.1:1**, invisible; ahora la pista apagada es `c-text-secondary`, a 4.9:1.
