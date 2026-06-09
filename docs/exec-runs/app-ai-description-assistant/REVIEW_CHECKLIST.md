# REVIEW CHECKLIST — app-ai-description-assistant
**Fecha:** 2026-06-08T23:54:12Z

Pasos manuales antes de commitear:

## Calidad
- [ ] `dart analyze lib/` → "No issues found!" (confirmado en QA handoff)
- [ ] `flutter test` → todos los tests pasan (874/874 confirmado en QA handoff)

## Flujo happy path
- [X] Abrir formulario de evento → tocar botón "IA" en el editor de descripción
- [X] Escribir un prompt en el chat → la respuesta AI aparece como burbuja
- [X] El indicador de cuota decrece tras cada generación
- [X] Tocar "Insertar en descripción" con el editor vacío → contenido se aplica directamente sin ConfirmationDialog
- [X] El QuillEditor muestra el contenido formateado (bold, headings, bullet lists)

## Confirmación de reemplazo
- [X] Con descripción ya existente → tocar "Insertar" → aparece ConfirmationDialog "Reemplazar descripción"
- [X] Cancelar → descripción no cambia
- [X] Confirmar → descripción se reemplaza

## Errores y cuota
- [X] Cortar red → tocar "IA" → sheet muestra banner `ai_errorNetwork` con botón "Reintentar" → app no crashea
- [X] "Reintentar" funciona cuando la red vuelve
- [X] Con cuota agotada (simular `ai_description_daily_limit = 0` en Remote Config) → campo de texto deshabilitado, sin botón "Reintentar"

## Guardrail — otros formularios
- [X] Abrir formulario de mantenimiento o SOAT (cualquier AppRichTextEditor sin onAiSuggest) → no aparece sheet de IA, UX sin regresión

## Edición de evento existente
- [X] Abrir formulario de edición de evento con descripción preexistente → descripción se carga correctamente en el QuillEditor
- [X] El botón IA funciona normalmente en modo edición

## Corrección pendiente (watchlist)
- [ ] Considerar corregir `turn.role.name == 'user'` → `turn.role == AiChatRole.user` en `ai_description_chat_sheet.dart:219` (no es blocker, pero mejora robustez)
