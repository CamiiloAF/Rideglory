# Review Checklist — app-ai-cover-assistant
_Generated: 2026-06-09T03:52:23Z_

Completa estos pasos antes de commitear.

---

## Pre-commit

- [ ] `dart analyze lib` — 0 issues (ya pasa, verificar tras cualquier edición manual)
- [ ] `flutter test test/features/events/domain/use_cases/get_generate_cover_use_case_test.dart` — 5/5 pass
- [ ] `flutter test test/features/events/presentation/form/cubit/event_form_cubit_analytics_test.dart` — 9/9 pass
- [ ] Verificar que NO quedan referencias a `GetGenerateCoverUseCase`, `EventCoverRepository`, `generateEventCover` en `lib/`: `grep -r "GetGenerateCoverUseCase\|EventCoverRepository\|generateEventCover" lib/`

---

## Pruebas funcionales en dispositivo/emulador (dev flavor)

### Happy path
- [ ] Abrir formulario de creación de evento
- [ ] Tocar "Generar con IA" → se abre `AiCoverChatSheet` (bottom sheet, drag handle visible)
- [ ] Escribir un prompt (ej. "Rodada por el eje cafetero al amanecer") y tocar "Generar con IA"
- [ ] Verificar: shimmer 16:9 aparece mientras carga; LinearProgressIndicator indeterminado debajo
- [ ] Al llegar la imagen: shimmer desaparece, imagen 16:9 se muestra con botón "Usar esta imagen"
- [ ] Tocar imagen → abre `AiCoverFullScreenPage` (pantalla completa, InteractiveViewer funcional)
- [ ] Tocar "Usar esta portada" → vuelve al sheet → sheet se cierra → imagen queda en el form
- [ ] Generar otra imagen desde el sheet → indicador de cuota se actualiza
- [ ] Tocar "Usar esta imagen" directo (sin full screen) → sheet cierra, imagen en form

### Error — safety_blocked (422)
- [ ] Escribir prompt con contenido cuestionable → banner rojo con mensaje "El contenido fue bloqueado. Modifica la descripción" + botón "Reintentar" → input se rehabilita

### Error — quota_exceeded_user (429 + error=quota_exceeded_user)
- [ ] Al agotar cuota diaria → banner rojo "Alcanzaste tu límite de generaciones por hoy"; **input permanece deshabilitado**; no hay botón "Reintentar"

### Error — quota_exceeded_project (429 + error=quota_exceeded_project)
- [ ] Banner rojo "Servicio temporalmente no disponible. Intenta más tarde" + "Reintentar" visible; input se rehabilita

### Fallback — subir imagen manual
- [ ] En el form, tocar "Subir imagen" → gallery picker abre correctamente (path legacy sin cambios)

### Regresión
- [ ] Flujo completo de creación de evento (sin portada AI) sigue funcionando
- [ ] Edición de evento existente no muestra errores relacionados con cover legacy

---

## Watchlist (no bloquea, revisar en próxima iteración)

- `AiCoverError.unknown` muestra mensaje de red — considerar un string genérico dedicado
- `AiCoverResult` sin `==` semántico — agregar `@equatable` o `==` override para robustez de tests futuros
