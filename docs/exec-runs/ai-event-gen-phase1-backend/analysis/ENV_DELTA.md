# ENV Delta — ai-event-gen-phase1-backend

**Generado:** 2026-06-05T22:41:18Z

## Variables nuevas

| Variable | Servicio | Requerida | Default | Descripción |
|----------|----------|-----------|---------|-------------|
| `GEMINI_API_KEY` | api-gateway | Sí (runtime) | — | API key de Gemini Developer API (Google AI Studio) |
| `GEMINI_TEXT_MODEL` | api-gateway | No | `gemini-2.5-flash` | Modelo de texto Gemini usado para generación de descripciones |

## Acción requerida

- Agregar ambas variables en `api-gateway/.env.example` con comentarios descriptivos.
- El desarrollador debe configurar `GEMINI_API_KEY` en su `.env` local para pruebas manuales.
- EC2/staging: fuera del alcance de esta fase — documentado pero no desplegado.

## Variables NO modificadas

Ninguna variable existente se modifica o elimina.
