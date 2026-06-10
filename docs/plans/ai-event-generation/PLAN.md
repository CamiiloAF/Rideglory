# Plan: ai-event-generation
> Estado: BORRADOR — revision humana pendiente. Generado: 2026-06-05T22:07:51Z

## Overview

Feature de generación IA para eventos de Rideglory: un organizador puede conversar con un asistente IA para generar y refinar la descripción de su evento e inyectarla al editor de texto enriquecido con un toque, y generar portadas 16:9 en un chat visual con previsualización full-screen. El feature usa Gemini Developer API (free tier), almacena imágenes temporales en Firebase Storage, controla cuotas diarias en Firestore, y retira completamente el flujo legacy Unsplash/Claude al finalizar la Fase 5 (código backend, cliente Flutter y variables de entorno, en un único deploy coordinado). El plan se divide en 6 fases ordenadas por dependencia: 3 de backend (1→2→3) seguidas de 2 de Flutter (4→5) y un cierre transversal (6). Las Fases 4 y 5 requieren que las Fases 1-3 estén desplegadas.

## Fases

- Fase 1 [NORMAL]: [Fase 1 — Backend — Base de texto IA](phases/phase-01-backend-base-de-texto-ia.md)
- Fase 2 [FULL]: [Fase 2 — Backend — Portada IA con Storage](phases/phase-02-backend-portada-ia-con-storage.md)
- Fase 3 [NORMAL]: [Fase 3 — Backend — Sistema de cuotas](phases/phase-03-backend-sistema-de-cuotas.md)
- Fase 4 [FULL]: [Fase 4 — App — Asistente de descripción](phases/phase-04-app-asistente-de-descripcion.md)
- Fase 5 [FULL]: [Fase 5 — App — Asistente de portada + retiro completo del flujo legacy](phases/phase-05-app-asistente-de-portada-retiro-completo-del-flu.md) [CERRADA — portada IA eliminada; retiro legacy completo]
- Fase 6 [NORMAL]: [Fase 6 — QA, analytics y cierre](phases/phase-06-qa-analytics-y-cierre.md)

## Supuestos

1. **Gemini free tier operativo:** Gemini texto y el modelo de imagen (`GEMINI_IMAGE_MODEL`) están disponibles en free tier; si el modelo de imagen cambia de nombre antes de Fase 2, actualizar la env var es suficiente.
2. **firebase-admin acepta `storageBucket`:** La instancia singleton se reinicializa en cada deploy; agregar el parámetro es suficiente sin cambios de IAM adicionales.
3. **Permisos de escritura al bucket:** Las credenciales firebase-admin ya configuradas tienen permisos de escritura; se verifican en día 1 de Fase 2.
4. **rideglory-contracts operativo:** El paquete `file:../rideglory-contracts` acepta DTOs nuevos bajo `src/ai/` sin setup adicional.
5. **Historial recortado en cliente:** El cliente envía máximo 10 turnos en `history[]` para no exceder la ventana de contexto.
6. **Sin usuarios reales en producción:** No hay usuarios activos que dependan del flujo Unsplash/Claude; el retiro es seguro.
7. **flutter_quill ^11.0.0:** No existe paquete maduro para Markdown→Delta; la implementación manual es viable con el subconjunto acotado (párrafo, h2, bold, italic, lista).
8. **`axios` en api-gateway:** El implementador de Fase 5 debe verificar si `axios` está en uso en otros módulos antes de eliminar la dependencia.
9. **`uuid` package:** Puede estar ya presente en `pubspec.yaml`; si no, agregarlo es el único cambio de dependencia Flutter de Fase 5.
10. **`AppRichTextEditor` retrocompatible:** El param `externalController` es nullable; todos los call sites existentes siguen funcionando sin cambios.

## Riesgos

| ID | Riesgo | Prob | Impacto | Fase | Mitigación |
|----|--------|------|---------|------|-----------|
| R1 | Modelo Gemini imagen inestable (preview; puede cambiar nombre) | Alta | Alto | 2 | `GEMINI_IMAGE_MODEL` como env var; validar en día 1 de Fase 2 |
| R2 | `storageBucket` no configurado en firebase-admin → falla silenciosa | Media | Alto | 2 | Gate explícito en Fase 2: verificar escritura a Storage antes de implementar lógica de generación |
| R3 | `MarkdownToDeltaConverter` — edge cases no cubiertos | Media | Medio | 4 | Subconjunto acotado (A4); fallback texto plano sin error; tests unitarios obligatorios |
| R4 | Latencia imagen Gemini (~10-15 s) → UX percibida de app colgada | Alta | Medio | 5 | Shimmer 16:9 + indicador de progreso indeterminado obligatorio (especificado en UX) |
| R5 | Ventana inoperativa de portada para testers (Fases 3-4) | Media | Bajo | 3-4 | Nota en handoff de Fase 3; sin usuarios reales; solo afecta QA interno |
| R6 | Propagación Remote Config (delay hasta 12h) | Baja | Bajo | 3-5 | `fetchAndActivate()` al montar cada chat cubit |
| R7 | Fase 4 subdimensionada (equivale a 2 features medianas) | Media | Medio | 4 | Si el sprint es ajustado: dividir en 4a (domain+data+cubit+AppRichTextEditor mod) y 4b (UI+integración); el plan lo permite |
| R8 | `generate-cover.spec.ts` huérfano falla en CI si no se suprime | Media | Bajo | 5 | El implementador debe suprimir o refactorizar el spec al retirar el handler |
| R9 | `Document.fromDelta()` inestable en flutter_quill 11.x | Baja | Medio | 4 | Probar en día 1 de Fase 4; alternativa: `QuillController.fromDocument(Document.fromJson(deltaJson))` |

## Como ejecutar una fase

> Cada fase se implementa con rg-exec en el NIVEL recomendado (ver el [LITE/NORMAL/FULL] del titulo y la seccion "Ejecucion recomendada" de cada fase):

```
Workflow({ name: 'rg-exec', args: { source: 'docs/plans/ai-event-generation/phases/phase-01-backend-base-de-texto-ia.md', mode: '<lite|normal|full>' } })
```

> lite = mecanico/bajo riesgo; normal = feature acotada; full = complejo/riesgoso (contratos, migraciones, seguridad).
