# 02 — PO Proposal

**Slug:** ai-event-generation
**Fecha:** 2026-06-05T21:20:34Z

---

## Fases propuestas

| # | Título | Objetivo de valor (1 frase) |
|---|--------|-----------------------------|
| 1 | Backend — Base de texto IA | El backend puede generar descripciones de eventos con Gemini; la app existente no se interrumpe. |
| 2 | Backend — Portada IA con Storage | El backend puede generar imágenes 16:9 con Gemini y almacenarlas en Firebase Storage; ambos endpoints IA quedan listos para consumo Flutter. |
| 3 | Backend — Sistema de cuotas | El backend controla cuántas generaciones puede hacer cada usuario por día y devuelve errores tipados claros cuando se agota el límite. |
| 4 | App — Asistente de descripción | Un organizador puede conversar con un asistente IA para generar y refinar la descripción de su evento, e inyectarla en el editor con un solo toque. |
| 5 | App — Asistente de portada | Un organizador puede generar imágenes de portada IA, previsualizar en pantalla completa y confirmar la que le guste; el flujo antiguo (Unsplash) queda retirado. |
| 6 | QA, analytics y cierre | El feature es apto para producción: observabilidad completa, strings localizadas, suite de tests verde y backend desplegado. |

---

### Fase 1 — Backend: Base de texto IA

**Objetivo:** El backend expone `POST /events/ai/description` (Gemini texto); el endpoint legacy `/events/generate-cover` permanece activo para no romper la app.

**Resumen:** Instalar `@google/genai` en api-gateway. Crear `AiModule` + `GeminiService.generateDescription()` con prompts de contexto rider colombiano. Publicar `POST /events/ai/description` que recibe `eventContext` + `history[]` y devuelve Markdown. Agregar `AiDescriptionRequestDto` / `AiDescriptionResponseDto` en `rideglory-contracts`. **No** eliminar `ClaudeService` ni `UnsplashService` todavía; la app sigue funcionando.

---

### Fase 2 — Backend: Portada IA con Storage

**Objetivo:** El backend puede producir una imagen 16:9 via Gemini, subirla a Firebase Storage en `pending/{userId}/{draftId}.jpg` y devolver la URL; incluye cron de barrido de huérfanos.

**Resumen:** Agregar `GeminiService.generateCover()` (lógica nueva-vs-edición por keywords es-CO). Crear `POST /events/ai/cover` → imagen → Storage → URL pública. Implementar `StorageCleanupService` con `@Cron` semanal que borra archivos `pending/` con más de 7 días. Publicar DTOs `AiCoverRequestDto` / `AiCoverResponseDto` en `rideglory-contracts`. El endpoint legacy `/events/generate-cover` sigue vivo.

---

### Fase 3 — Backend: Sistema de cuotas

**Objetivo:** Cada usuario tiene un límite diario de generaciones (texto e imagen) configurable desde Firebase Remote Config; superarlo devuelve errores tipados manejables por la app.

**Resumen:** Migración Prisma en `events-ms` para tabla `ai_usage_quota` (userId, date, descriptionCount, coverCount). Crear handlers TCP/microservicio `checkAiQuota` / `incrementAiQuota` en events-ms. En api-gateway, `AiModule` llama estos handlers antes de cada generación. Leer límites `ai_description_daily_limit` / `ai_cover_daily_limit` desde Firebase Remote Config Admin SDK. Implementar los 4 errores tipados: `quota_exceeded_user`, `quota_exceeded_project`, `safety_blocked`, `network_error`. Eliminar `ClaudeService`, `UnsplashService` y el secret `UNSPLASH_ACCESS_KEY` — el legacy endpoint `/events/generate-cover` puede retirarse aquí o en Fase 5 según coordinación con Flutter.

---

### Fase 4 — App: Asistente de descripción

**Objetivo:** Un organizador puede abrir un chat con un asistente IA desde el formulario de evento, iterar sobre la descripción en lenguaje natural y aplicarla al editor de texto enriquecido con un toque.

**Resumen:** Agregar `AiDescriptionRequestDto` / `AiDescriptionResponseDto` (Pattern B) y `GenerateEventDescriptionUseCase`. Crear `AiDescriptionChatCubit` con estado `@freezed` (history, `ResultState<String>`, remainingQuota). UI de chat como bottom sheet con burbujas (pregunta / respuesta), campo de entrada y botón "Insertar en descripción". Conversión Markdown→Quill Delta en cliente (evaluar `markdown_quill` o implementación manual). Confirmación antes de pisar texto existente. Conectar `AppRichTextEditor.onAiSuggest` callback. Mostrar cuota restante (Remote Config).

---

### Fase 5 — App: Asistente de portada

**Objetivo:** Un organizador puede generar portadas IA en un chat visual, ver cada imagen en pantalla completa y confirmar la que le guste; el flujo de Unsplash desaparece de la app.

**Resumen:** Agregar `AiCoverRequestDto` / `AiCoverResponseDto` y `GenerateEventCoverUseCase`. Crear `AiCoverChatCubit` con estado `@freezed` (history, `ResultState<String>` para URL, remainingQuota). UI de chat con burbujas de imagen; visor full-screen al tocar; botón "Usar esta imagen" pasa la URL al `EventFormCubit`. Manejo de los 4 errores tipados con mensaje en español. Deshabilitar envío cuando cuota = 0. Eliminar `GetGenerateCoverUseCase`, `EventCoverService` (endpoint legacy) y `CoverGenerationDto` del cliente Flutter. Refactorizar `CoverPreviewWidget` / `CoverPlaceholderView` para el nuevo flujo.

---

### Fase 6 — QA, analytics y cierre

**Objetivo:** El feature está listo para producción con observabilidad, cobertura de tests, strings completas y backend desplegado en EC2.

**Resumen:** Implementar los 5 eventos de telemetría (`ai_description_generated`, `ai_image_generated`, `ai_quota_exceeded`, `ai_generation_failed`, `ai_cover_used`). Agregar todas las strings al `app_es.arb`. Escribir tests backend (spec) para los dos endpoints IA. Alcanzar `flutter test` al 100% en las clases nuevas; `dart analyze` limpio. Actualizar `docs/features/events.md`. Deploy backend en EC2 (siguiendo workflow de migraciones local-first).

---

## Supuestos

1. **Disponibilidad Gemini free tier:** Gemini 2.5 Flash (texto e imagen nativa) está disponible en free tier en el momento de implementar la Fase 1; si cambia la API antes de Fase 2 habrá que ajustar el modelo.
2. **Endpoint legacy protegido:** `/events/generate-cover` permanece operativo hasta que Fase 5 complete su retiro en Flutter; no se rompe la app durante las fases intermedias.
3. **Quota vía microservicio TCP:** api-gateway no accede directamente a la DB de events-ms; la cuota se expone como handlers TCP (`checkAiQuota` / `incrementAiQuota`) en events-ms, siguiendo el patrón existente del monorepo.
4. **Firebase Storage accesible desde backend:** Las credenciales de `firebase-admin` ya configuradas en api-gateway tienen permisos de escritura al bucket de Storage; no se requiere configuración adicional de IAM.
5. **rideglory-contracts operativo:** El paquete `file:../rideglory-contracts` ya puede recibir DTOs nuevos sin setup adicional de build o publish.
6. **Historial recortado en cliente:** El cliente envía como máximo los últimos 10 turnos en el array `history[]` para no exceder la ventana de contexto de Gemini ni aumentar el payload innecesariamente.
7. **Sin usuarios reales en producción:** No hay usuarios activos que dependan del flujo Unsplash/Claude; refactors agresivos son seguros.
8. **Conversión Markdown→Delta viable:** Existe un paquete compatible con `flutter_quill ^11.0.0` o la conversión puede implementarse manualmente con esfuerzo razonable (< 1 día de trabajo).

---

## Riesgos

1. **API de imagen Gemini inestable (Fase 2):** El modelo de generación de imagen nativa en Gemini 2.5 Flash está en preview; su disponibilidad o nombre puede cambiar. Mitigación: validar el endpoint exacto antes de arrancar Fase 2; tener un fallback de imagen placeholder.
2. **Latencia de cuota via TCP (Fase 3):** Cada generación agrega un round-trip api-gateway → events-ms para check + increment de cuota. Si events-ms está bajo carga, la latencia sube. Mitigación: cachear el check en memoria por ventana de 1 min en api-gateway.
3. **Markdown→Delta sin paquete maduro (Fase 4):** No hay paquete probado para flutter_quill 11.x. Una implementación manual puede introducir bugs en edge cases (listas anidadas, negrita+cursiva). Mitigación: limitar la conversión a los elementos Markdown que Gemini usa realmente (h2, párrafos, listas simples, bold/italic).
4. **Firebase Storage desde backend — permisos (Fase 2):** Si el bucket tiene reglas de solo-cliente, las subidas desde `firebase-admin` fallan. Mitigación: verificar permisos en el sprint de Fase 2 antes de escribir lógica de generación.
5. **Propagación de Remote Config (Fases 3-5):** Los límites de cuota se leen de Remote Config con fetch+activate; hay un delay de hasta 12 horas en cliente si no se fuerza el fetch. Mitigación: forzar `fetchAndActivate()` al abrir el asistente IA.
6. **Coordinación de retiro del endpoint legacy:** Si Fase 3 elimina `/events/generate-cover` antes de que Fase 5 retire el cliente Flutter, la app en testers puede romper el flujo de portada. Mitigación: coordinar explícitamente; el endpoint legacy solo se elimina cuando Fase 5 esté en producción.

---

## Criterios de éxito globales

- Un organizador puede generar una descripción IA completa y aplicarla al editor en ≤ 3 turnos de chat.
- Un organizador puede generar una portada IA, previsualizarla en pantalla completa y confirmarla sin salir del formulario de evento.
- La cuota diaria se respeta y el usuario ve cuántas generaciones le quedan antes de intentar generar.
- Cuando la cuota se agota, el usuario recibe un mensaje claro en español y no queda con la app bloqueada.
- `dart analyze` sin errores; `flutter test` al 100% en código nuevo; spec backend verde.
- El endpoint `/events/generate-cover` (Unsplash/Claude) está eliminado del backend y del cliente al finalizar Fase 5.
- `docs/features/events.md` refleja el nuevo flujo de asistentes IA.
