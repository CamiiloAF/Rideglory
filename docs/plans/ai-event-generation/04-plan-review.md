# 04 — Plan Review

**Slug:** ai-event-generation
**Fecha:** 2026-06-05T21:23:01Z
**Reviewer:** Plan Reviewer (UX móvil + Clean Architecture)
**Veredicto:** ok_con_ajustes

---

## UX por fase

### Fase 1 — Backend: Base de texto IA
No hay superficie Flutter. Sin observaciones de UX.

### Fase 2 — Backend: Portada IA con Storage
No hay superficie Flutter. Observación de calidad: verificar permisos del bucket antes de escribir lógica de generación (supuesto 4 del PO); si falla silencia el error. Gate explícito en el PR: una prueba de integración con el bucket real o instrucción de verificación manual en el README de Fase 2.

### Fase 3 — Backend: Sistema de cuotas
No hay superficie Flutter. Observación de diseño de DTO: tanto `AiDescriptionResponseDto` como `AiCoverResponseDto` **deben incluir el campo `remainingGenerations: int`** en la respuesta. Flutter no puede calcular el restante localmente (límites pueden cambiar en Remote Config sin aviso); el backend es la fuente de verdad del conteo. Si este campo no está en los DTOs de Fases 1-2 habrá que parchear retroactivamente.

### Fase 4 — App: Asistente de descripción

#### Flujo pantalla completa (375 px)

El punto de entrada es el botón "IA" en la toolbar de `AppRichTextEditor`. Ese botón dispara `onAiSuggest`. La UI de chat vive en un `DraggableScrollableSheet` (bottom sheet arrastrable):

- `initialChildSize: 0.65`, `minChildSize: 0.45`, `maxChildSize: 0.95`
- El padre no debe tener `resizeToAvoidBottomInset: true`; el sheet gestiona el inset del teclado con `MediaQuery.of(context).viewInsets.bottom` + padding interno
- La lista de burbujas es `ListView` invertida (`reverse: true`) para que el mensaje más reciente quede visible sin scroll
- Touch targets: campo de entrada ≥ 48 dp de alto; botón enviar (ícono) en área ≥ 48×48 dp; botón "Insertar en descripción" ancho completo (`AppButton` tipo primary, 48 dp alto)

#### Estados obligatorios por widget

| Estado | Widget esperado |
|--------|----------------|
| idle / sin historial | Mensaje de bienvenida centrado ("¿De qué trata tu rodada?") + campo de entrada habilitado |
| loading (turno en vuelo) | Burbuja de loading (tres puntos animados) en el lado IA; campo de entrada bloqueado |
| data | Burbuja de texto con Markdown renderizado (solo h2, párrafos, bold, italic, listas simples) |
| error tipado | Banner inline dentro del sheet con mensaje en español + botón "Reintentar"; campo habilitado de nuevo |
| quota = 0 | Campo de entrada deshabilitado, placeholder "Has alcanzado el límite diario de generaciones"; botón "Insertar" sigue activo si hay contenido previo |

#### Confirmación antes de pisar contenido existente

Si `AppRichTextEditor` tiene contenido no vacío y el usuario toca "Insertar en descripción", mostrar `ConfirmationDialog` (del shared) antes de reemplazar. Si el editor está vacío, insertar directo sin confirmación.

#### Markdown → Quill Delta

La conversión vive en el cubit (capa presentation), no en domain. El repositorio devuelve `String markdown`; el cubit llama a `MarkdownToDeltaConverter` (clase utilitaria en `lib/features/events/presentation/utils/`). Si la conversión falla (edge case), el cubit expone el Markdown plano como fallback en un estado `ResultState.error` con mensaje "No se pudo aplicar el formato; texto copiado sin formato". Nunca silenciar el error.

#### Cuota visible

Texto pequeño debajo del campo de entrada: "X generaciones restantes hoy". Leer de `remainingGenerations` del último response DTO. Antes del primer turno leer de Remote Config (límite configurado) para mostrar el tope inicial.

### Fase 5 — App: Asistente de portada

#### Flujo pantalla completa (375 px)

Bottom sheet igual que Fase 4 (DraggableScrollable). Las burbujas de imagen tienen relación de aspecto 16:9 fija; ancho máximo = ancho del sheet − 32 dp (padding). En 375 px eso da ~211 × 119 px por burbuja.

| Estado | Widget esperado |
|--------|----------------|
| idle / sin historial | Placeholder 16:9 con ícono de cámara + campo de prompt habilitado |
| loading imagen | Shimmer animado 16:9 (no spinner genérico); latencia esperada ~10-15 s; mostrar indicador de progreso indeterminado bajo el shimmer |
| data | Imagen cargada con `CachedNetworkImage`; botón "Usar esta imagen" (secondary) en la burbuja; botón "Ver en pantalla completa" (ícono expand) en la esquina superior derecha de la burbuja |
| error tipado | Banner inline igual que Fase 4 |
| quota = 0 | Campo deshabilitado; botones "Usar esta imagen" en burbujas anteriores siguen activos |

#### Visor full-screen

Pantalla separada (`AiCoverFullScreenPage`) o `showDialog` con imagen a pantalla completa. CTA principal: `AppButton` "Usar esta portada" (botón primary, ancho completo, zona segura inferior). Botón de cierre (ícono X) en top-right, dentro de SafeArea. La confirmación de imagen en full-screen y en la burbuja deben ambas funcionar — no solo una.

#### Comunicación cubit → EventFormCubit

Cuando el usuario confirma una imagen, el cubit local llama `Navigator.of(context).pop(selectedImageUrl)`. El `EventFormCubit` recibe la URL vía el callback del caller (no se comparte estado global entre cubits). Este contrato debe quedar documentado en los comentarios del cubit, no asumirse.

#### Flujo manual de carga (fallback)

El botón "Subir imagen" de `CoverPreviewWidget` **no desaparece** con este refactor. El selector de flujo queda: [Generar con IA] | [Subir imagen]. El PO no lo menciona explícitamente; agregar como criterio de aceptación de Fase 5.

---

## Gates de calidad

### Clean Architecture (bloqueante en toda fase Flutter)

| Gate | Fase | Descripción |
|------|------|-------------|
| `ChatTurn` en domain | 4 | `ChatTurn` (role: `user \| assistant`, content: `String`, timestamp: `DateTime`) es un modelo puro Dart en `lib/features/events/domain/model/chat_turn.dart`. Ningún import de Flutter. |
| `AiDescriptionRepository` interfaz en domain | 4 | El contrato se define en domain; `AiDescriptionRepositoryImpl` en data; nunca inversión. |
| `AiCoverRepository` interfaz en domain | 5 | Igual que arriba para portada. |
| Markdown→Delta en presentation layer | 4 | `MarkdownToDeltaConverter` vive en `lib/features/events/presentation/utils/`. No en domain ni data (Delta es tipo de flutter_quill, no permitido en domain/data). |
| No exposición de DTO en presentation | 4-5 | Los cubits exponen modelos domain (`ChatTurn`, `String imageUrl`), no `AiDescriptionResponseDto`. |
| Cubits `@injectable` (no `@singleton`) | 4-5 | `AiDescriptionChatCubit` y `AiCoverChatCubit` son `@injectable`; su `BlocProvider` vive en el bottom sheet, no en `main.dart`. `AuthCubit` es la única excepción global permitida. |
| `remainingGenerations` en DTO de Fases 1-2 | 1-3 | Campo `remainingGenerations: int` presente en `AiDescriptionResponseDto` y `AiCoverResponseDto` desde Fase 1/2 para no parchear en Fase 3. |

### rideglory-coding-standards (bloqueante)

| Gate | Fases |
|------|-------|
| Un widget por archivo | 4-5 |
| No métodos `Widget _buildXxx()` en ningún widget nuevo | 4-5 |
| Todos los botones vía `AppButton` / `AppTextButton` | 4-5 |
| Todos los dialogs vía `AppDialog` / `ConfirmationDialog` | 4-5 |
| Estado async vía `ResultState<T>` (sin `bool isLoading`) | 4-5 |
| Texto oscuro sobre color primario naranja (`AppColors.darkBgPrimary`) | 4-5 |
| Todos los strings de usuario en `app_es.arb` / `context.l10n` | 4-6 |
| `dart analyze` limpio antes de cada PR de fase Flutter | 4-5-6 |

### Analytics (bloqueante Fase 6)

Los 5 eventos `ai_*` se disparan desde métodos de cubit, nunca desde `build()` ni callbacks de widget. Gate: revisión de diff en Fase 6 confirma que no hay llamadas analytics en la capa presentation widget.

---

## Riesgos de scope

### R1 — Fase 4 subdimensionada

La Fase 4 cubre en un solo entregable: modelo domain (`ChatTurn`), repositorio e interfaz, use case, DTO + Retrofit service, cubit con estado `@freezed` complejo, bottom sheet con burbujas, Markdown→Delta converter, confirmación de reemplazo, y display de cuota. Es el equivalente a 2 features medianas. Si la estimación de tiempo es ajustada, considerar dividir: **4a** (domain + data + cubit sin UI) y **4b** (UI completa + integración). El plan actual no prohíbe esto; la PO puede ajustar antes de ejecución.

### R2 — Markdown→Delta sin paquete maduro

El scan lo identifica. Si en el sprint de Fase 4 no se encuentra paquete compatible con `flutter_quill ^11.0.0`, la implementación manual tarda más de 1 día. Mitigación ya documentada en la propuesta PO es correcta (limitar a los elementos que Gemini produce). Agregar un criterio de aceptación explícito: "La conversión soporta párrafo, h2, bold, italic y lista sin ordenar; cualquier otro elemento se inserta como texto plano".

### R3 — Latencia de imagen en UX

Con Gemini imagen (~10-15 s), el loading state en Fase 5 es crítico. Sin shimmer adecuado, el usuario asume que la app se colgó. El PO no especifica el widget de loading. Lo especifico aquí (ver sección UX Fase 5); el implementador debe seguirlo.

### R4 — Retiro del endpoint legacy (/events/generate-cover)

El retiro backend ocurre en Fase 3; el retiro Flutter en Fase 5. Hay una ventana de 2 fases (Fases 3-4) en que el endpoint puede estar inactivo en backend pero el cliente Flutter todavía lo referencia. En el contexto actual (sin usuarios reales en producción) esto no rompe a nadie, pero si se hacen pruebas de QA con dispositivo físico durante Fase 3-4, `CoverPreviewWidget` fallará en el botón "Generar con IA" del flujo anterior. Documentar en el handoff de Fase 3: "El botón 'Generar con IA' en el flujo actual de portada quedará inoperativo para testers desde este momento hasta Fase 5".

### R5 — Pattern B en DTOs de IA

Los DTOs de IA son response-only (no tienen modelo domain 1:1 en el sentido tradicional, ya que el "turno" es `ChatTurn` y la respuesta tiene campos adicionales como `remainingGenerations`). Confirmar la excepción en el DTO con comentario inline: `// Excepción Pattern B: DTO compuesto con campos de control (remainingGenerations) que no pertenecen al modelo domain ChatTurn`. Sin esta documentación el Tech Lead la marcará como violación en revisión.

---

## Ajustes

Los siguientes ajustes son **requeridos** antes de que el Architect cierre el plan:

### A1 — `remainingGenerations` en DTOs desde Fase 1

Agregar campo `remainingGenerations: int` a `AiDescriptionResponseDto` (Fase 1) y `AiCoverResponseDto` (Fase 2). Sin esto, Fase 4 y 5 tienen que parchear los contratos retroactivamente.

### A2 — Criterio de aceptación explícito: "Subir imagen" sobrevive Fase 5

En Fase 5, agregar como criterio de aceptación: "El botón 'Subir imagen' permanece disponible como alternativa al flujo IA. El selector de flujo ofrece [Generar con IA] y [Subir imagen] en paralelo".

### A3 — ChatTurn en domain especificado en Fase 4

El plan de Fase 4 debe listar explícitamente: "Crear `ChatTurn` en `lib/features/events/domain/model/chat_turn.dart` como clase pura Dart (sin imports Flutter)". Actualmente el PO describe el state como `List<ChatTurn>` sin indicar en qué capa vive el modelo.

### A4 — Markdown→Delta como criterio de aceptación acotado

Fase 4, criterio de aceptación: "La conversión Markdown→Delta soporta: párrafos, h2 (→ header level 2 en Delta), bold, italic, y listas sin ordenar. Cualquier otro elemento se inserta como texto plano sin error visible." Evita scope creep y testeo de edge cases poco probables.

### A5 — Comunicación AiCoverChatCubit → EventFormCubit documentada

Fase 5 debe especificar el mecanismo: `Navigator.of(context).pop(selectedImageUrl)` como `String?`; el caller recibe la URL y llama `eventFormCubit.setCoverUrl(url)`. Sin esto el implementador puede optar por estado global, violando la regla de cubits locales.

### A6 — "Usar esta imagen" presente tanto en burbuja como en full-screen

Fase 5, criterio de aceptación: "El botón 'Usar esta imagen' está disponible en la burbuja del chat (acción secundaria) Y como CTA primario en el visor full-screen".

### A7 — Gate de analytics en Fase 6

Fase 6 debe incluir como criterio de aceptación: "Revisión de diff confirma que todos los `logEvent('ai_*')` se invocan desde métodos de cubit, sin ninguna llamada en `build()` o callbacks de widget".

### A8 — Excepción Pattern B documentada en DTOs de IA

En las descripciones de Fases 1-2, agregar nota: "Los DTOs de IA (`AiDescriptionResponseDto`, `AiCoverResponseDto`) son DTOs compuestos con campos de control (`remainingGenerations`); no extienden un modelo domain. Documentar con comentario inline la excepción Pattern B".
