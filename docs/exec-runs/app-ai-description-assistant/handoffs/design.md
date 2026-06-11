# Design handoff — app-ai-description-assistant

**Date:** 2026-06-08T19:19:12Z
**Status:** done
**Slug:** app-ai-description-assistant

---

## Pantallas

| Pantalla / estado | Tipo | Archivo mockup | Descripción |
|-------------------|------|----------------|-------------|
| AI Chat Sheet — Idle | EXTEND | `ai-chat-sheet.html` (estado 1) | Sheet vacío, empty state con ícono ✦ y hint de uso |
| AI Chat Sheet — Loading | EXTEND | `ai-chat-sheet.html` (estado 2) | Turno de usuario enviado; indicador de 3 puntos animados en posición del modelo; input deshabilitado |
| AI Chat Sheet — Data | EXTEND | `ai-chat-sheet.html` (estado 3) | Burbujas de chat (historial visible); botón "Insertar en descripción" anclado sobre el input row |
| AI Chat Sheet — Error cuota usuario | EXTEND | `ai-chat-sheet.html` (estado 4) | Banner gris neutro (no rojo) — la cuota no es error del usuario; campo de texto y botón Enviar deshabilitados; SIN botón Reintentar; botón Insertar sigue disponible si hay respuesta previa |
| AI Chat Sheet — Error recuperable | EXTEND | `ai-chat-sheet.html` (estado 5) | Banner rojo; botón "Reintentar" presente; input habilitado (mensaje persistido); aplica a quota_exceeded_project, safety_blocked, network_error |
| Dialog — Confirmar reemplazo | EXTEND | `ai-insert-confirm-dialog.html` | ConfirmationDialog estándar con ícono ✦ (naranja); dos acciones: "Reemplazar" (primary) y "Cancelar" (secondary); aparece SOLO si editor tiene contenido (doc.length > 1) |
| Estado post-inserción exitosa | EXTEND | `ai-insert-confirm-dialog.html` | Sheet muestra estado de confirmación visual (✓ verde + texto) antes de cerrarse; el input sigue disponible para iteraciones adicionales |

**Clasificación:** todo es EXTEND — el único punto de entrada (botón IA en AppRichTextEditor) ya existe; esta fase lo conecta con el sheet funcional.

---

## Flujos UX

### Flujo principal — primera vez
```
FormBuilder (EventFormBasicInfoSection)
  └─ Toca botón [✦ IA] en AppRichTextEditor
       └─ DraggableScrollableSheet se abre desde abajo (initSize=0.7, maxSize=0.92)
            └─ Estado: Idle — EmptyStateWidget con hint
                 └─ Usuario escribe mensaje → toca Enviar [➤]
                      ├─ Estado: Loading (input deshabilitado, dots animados)
                      └─ [200 OK] → Estado: Data
                           ├─ Burbujas de chat visibles (ListView invertida, newest at bottom)
                           ├─ Botón [⬇ Insertar en descripción] visible
                           └─ Usuario toca Insertar
                                ├─ Si editor vacío (length ≤ 1) → inserción directa → estado post-inserción
                                └─ Si editor tiene contenido → ConfirmationDialog
                                     ├─ Confirma → inserción + estado post-inserción
                                     └─ Cancela → vuelve al chat (sin cambios)
```

### Flujo de error — cuota usuario (terminal)
```
Enviar → [429 quota_exceeded_user]
  └─ Banner neutro: "Alcanzaste el límite diario de generaciones. Intenta mañana."
       ├─ Input deshabilitado (opacidad 0.4)
       ├─ Botón Enviar deshabilitado
       ├─ SIN botón Reintentar
       └─ Si había respuesta previa: botón Insertar sigue habilitado
```

### Flujo de error — recuperable (quota_exceeded_project / safety_blocked / network_error)
```
Enviar → [429/422/503 error recuperable]
  └─ Banner rojo con mensaje específico + botón [↺ Reintentar]
       ├─ Input HABILITADO (mensaje del usuario persistido en campo)
       └─ Reintentar → re-envía mismo mensaje → vuelve a Loading
```

### Cancelar o cerrar el sheet
```
Toca [✕] o arrastra sheet hacia abajo
  └─ Sheet se cierra; QuillController externo NO se dispone (ownership en EventFormBasicInfoSection.State)
       └─ El contenido del editor permanece intacto
```

---

## Componentes

### Reutilizados (no crear)
| Componente existente | Dónde se usa |
|----------------------|--------------|
| `ConfirmationDialog` (`lib/shared/widgets/modals/confirmation_dialog.dart`) | Confirmar reemplazo de contenido del editor |
| `AppRichTextEditor` | Widget existente, se modifica solo para agregar `externalController` |
| `AppTextField` | Existente en EventFormBasicInfoSection |
| `AppCityAutocomplete` | Existente en EventFormBasicInfoSection |

### Nuevos (crear — 1 widget por archivo)
| Widget | Archivo | Descripción |
|--------|---------|-------------|
| `AiDescriptionChatSheet` | `ai_description_chat_sheet.dart` | `DraggableScrollableSheet` entry point; `BlocProvider<AiDescriptionChatCubit>`; gestiona el scaffold del sheet |
| `AiChatBubble` | `ai_chat_bubble.dart` | Burbuja de chat; prop `role: AiChatRole`; user = right-aligned, bg naranja oscuro; model = left-aligned con avatar ✦, bg surface-2 |
| `AiChatInputRow` | `ai_chat_input_row.dart` | Campo de texto multilinea + botón Enviar naranja; se deshabilita (`enabled: false`) cuando el estado es `quota_exceeded_user` |
| `AiChatLoadingIndicator` | `ai_chat_loading_indicator.dart` | Tres puntos animados dentro de una burbuja modelo; aparece como último ítem de la lista durante Loading |
| `AiChatErrorBanner` | `ai_chat_error_banner.dart` | Banner con ícono + mensaje l10n; prop `isRecoverable: bool` controla si muestra botón Reintentar y el color del banner; cuota usuario → neutro; recuperable → rojo |
| `AiQuotaIndicator` | `ai_quota_indicator.dart` | Pill pequeño en el header del sheet; `count >= 5` → verde; `count 1-4` → naranja; `count == 0` → rojo + texto "Cuota agotada" |
| `AiInsertButton` | `ai_insert_button.dart` | Botón naranja full-width "Insertar en descripción"; visible solo cuando el cubit tiene respuesta del modelo; dispara lógica de confirmación |
| `AiChatEmptyState` | `ai_chat_empty_state.dart` | Estado idle: ícono ✦ en círculo naranja-dim, título, párrafo de hint con ejemplo en cursiva naranja |

### Jerarquía del sheet
```
DraggableScrollableSheet
└── Column
    ├── SheetHandle (handle bar)
    ├── AiSheetHeader (title + AiQuotaIndicator + botón cerrar)
    ├── Expanded
    │   └── ListView (reverse: true)  ← newest at bottom
    │       ├── AiChatEmptyState  (si no hay mensajes)
    │       ├── AiChatBubble × N  (historial)
    │       ├── AiChatLoadingIndicator  (si loading)
    │       └── AiChatErrorBanner  (si error)
    ├── AiInsertButton  (solo si hay respuesta modelo)
    └── AiChatInputRow
```

---

## Copy (español)

| Clave ARB | Texto | Contexto |
|-----------|-------|---------|
| `ai_chatTitle` | `Asistente IA` | Título del header del sheet |
| `ai_chatHint` | `Escribe tu mensaje aquí...` | Placeholder del campo de texto |
| `ai_sendButton` | `Enviar` | Tooltip / semanticLabel del botón Enviar |
| `ai_insertButton` | `Insertar en descripción` | Texto del botón de inserción |
| `ai_quotaRemaining` | `{count} generaciones restantes` | Pill de cuota (≥ 1); param `{count}` |
| `ai_quotaExhausted` | `Cuota agotada` | Pill de cuota cuando `count == 0` |
| `ai_errorQuotaUser` | `Alcanzaste el límite diario de generaciones. Intenta mañana.` | Banner cuota usuario (no recuperable) |
| `ai_errorQuotaProject` | `El servicio está temporalmente saturado. Intenta en unos minutos.` | Banner cuota proyecto (recuperable) |
| `ai_errorSafetyBlocked` | `Tu mensaje fue bloqueado por las políticas de seguridad. Reformúlalo e intenta de nuevo.` | Banner safety blocked (recuperable) |
| `ai_errorNetwork` | `Error de conexión. Verifica tu internet e intenta de nuevo.` | Banner error de red (recuperable) |
| `ai_retryButton` | `Reintentar` | Botón dentro del banner recuperable |
| `ai_confirmReplaceTitle` | `¿Reemplazar descripción?` | Título del ConfirmationDialog |
| `ai_confirmReplaceMessage` | `Ya tienes contenido en la descripción. ¿Deseas reemplazarlo con la sugerencia de la IA?` | Cuerpo del ConfirmationDialog |
| `ai_emptyStateTitle` | `Crea la descripción de tu evento` | Título del empty state |
| `ai_emptyStateHint` | `Cuéntame sobre tu evento y te ayudo a redactar una descripción atractiva.` | Subtítulo del empty state |
| `ai_insertedSuccessTitle` | `Descripción insertada` | Estado post-inserción exitosa |
| `ai_insertedSuccessBody` | `El contenido fue aplicado al editor. Puedes cerrar el asistente o seguir iterando.` | Subtítulo post-inserción |

**Notas de copy:**
- El error `quota_exceeded_user` NO usa color rojo ni ícono de alerta — es una limitación esperada, no un fallo del sistema. Banner neutro (`color: text-secondary`) para evitar ansiedad.
- Los errores recuperables SÍ usan rojo para indicar que la acción puede reintentarse.
- El hint del empty state incluye un ejemplo en cursiva naranja para bajar la barrera de entrada.

---

## Accesibilidad

| Elemento | Requisito |
|----------|-----------|
| Botón [➤ Enviar] | `semanticLabel: context.l10n.ai_sendButton`; mínimo 44×44px |
| Botón [⬇ Insertar en descripción] | `semanticLabel` explícito; mínimo 48px de altura |
| Burbujas de chat | Cada `AiChatBubble` envuelve su contenido en `Semantics(label: 'Asistente IA: {contenido}')` o `'Tú: {contenido}'` según rol |
| AiChatErrorBanner | `role: Semantics(liveRegion: true)` — lector de pantalla anuncia el error automáticamente |
| AiQuotaIndicator | `Semantics(label: '{count} generaciones restantes de IA')` |
| ConfirmationDialog | Mantenido por `ConfirmationDialog` existente — ya cumple accesibilidad |
| Campo de texto input | `TextInputAction.send`; `keyboardType: TextInputType.multiline`; `maxLines: 4` |
| Touch targets | Todo elemento interactivo ≥ 44×44px (incluye el avatar-placeholder ✦ si es tappable) |
| Contraste | Burbujas modelo: `#F4F4F5` sobre `#1F1F1F` → ratio > 7:1 ✓ | Burbujas usuario: `#F4F4F5` sobre `#3D2A0A` → ratio ~5:1 ✓ |
| Animación loading dots | Respetar `MediaQuery.disableAnimations` — mostrar dots estáticos si está activo |

---

## Notas para Frontend

### DraggableScrollableSheet
- `initialChildSize: 0.70`, `minChildSize: 0.40`, `maxChildSize: 0.92`
- `expand: false` — no ocupa toda la pantalla por defecto
- El sheet se abre con `showModalBottomSheet` (no Navigator.push) para mantener el contexto del form activo debajo

### ListView invertida (chat)
- `reverse: true` en el `ListView` interno
- Los ítems se agregan al inicio de la lista (newest at bottom visually)
- El scroll automático no es necesario — `reverse: true` ya mantiene el último mensaje visible

### QuillController externo (ADR-A5)
- `EventFormBasicInfoSection.State` crea el controller en `initState()` y lo dispone en `dispose()`
- El mismo controller se pasa a `AppRichTextEditor(externalController: _controller)` y al sheet via el cubit o un callback
- Inserción: `_controller.document = Document.fromDelta(convertedDelta)` + `_controller.updateSelection(TextSelection.collapsed(offset: 0), ChangeSource.local)` — necesario para disparar `onChanged`
- Ver ADR-R9 (flutter_quill 11.x): si `fromDelta()` es inestable, usar `Document.fromJson(jsonDecode(jsonEncode(delta.toJson())))` como fallback

### AiInsertButton — visibilidad
- Solo se muestra cuando `state.messages.any((m) => m.role == AiChatRole.model)` — es decir, cuando hay al menos una respuesta del modelo
- En estado `quota_exceeded_user` sigue visible si ya hay respuesta previa (el usuario puede insertar aunque no pueda generar más)

### AiChatErrorBanner — distinción visual
- `quota_exceeded_user` → `Container` con fondo `surface-2`, borde `border`, texto `text-secondary` (neutro)
- Recuperables → fondo `error-dim`, borde rojo, texto `error` (rojo)
- El botón Reintentar NO aparece en `quota_exceeded_user`; en los otros 3 tipos SÍ

### AiDescriptionChatCubit — lifecycle
- `@injectable` factory (transient) — se instancia en `BlocProvider` dentro del sheet, se destruye al cerrar
- `initQuota()` se llama en el constructor / `initState` del sheet; no en `build`
- El historial se mantiene en el estado del cubit (`List<AiChatTurn> messages`); el use case lo recorta a 10 turnos antes de enviar al backend

### Feedback visual post-inserción
- Tras insertar exitosamente, el sheet puede mostrar un breve estado de confirmación (ícono ✓ verde + texto) antes de permitir más iteraciones
- El sheet NO se cierra automáticamente — el usuario puede seguir iterando

### Botón IA en AppRichTextEditor
- El botón [✦ IA] existente ya tiene el diseño correcto (border naranja, ícono `Icons.auto_awesome`, texto "IA")
- Solo cambia el `onTap`: en lugar de `InfoDialog` → llama el callback que `EventFormBasicInfoSection.State` provee para abrir el sheet
- El parámetro `onAiSuggest` del editor se convierte en la señal de que el botón debe mostrarse (no cambia su lógica)

---

## Change log
- 2026-06-08T19:19:12Z: Design handoff creado. 5 estados del AI chat sheet diseñados. 2 mockups HTML producidos. 8 widgets atómicos especificados. Copy completo (17 claves ARB). Accesibilidad y notas de implementación documentadas.
