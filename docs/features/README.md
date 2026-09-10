# Documentación por Feature — Rideglory

> Índice de la documentación detallada de cada feature de la app.

Cada archivo describe **cómo está construido** un feature en profundidad: modelo de dominio, capas (domain/data/presentation), cubits y estados, flujos, rutas, endpoints API, conexiones con otros features, y patrones/trampas conocidas.

El objetivo es servir como **contexto base** para cualquier desarrollador (o agente) que vaya a trabajar en el feature: leer la doc primero para no inventar comportamientos que no existen, ni omitir matices.

> Regla de mantenimiento: **al modificar código de un feature, actualizar la sección relevante de su doc**. Ver `feedback_update_feature_docs` en el sistema de memorias.

> **v2 (`refactor/v2`):** estos documentos describen el comportamiento real de `lib/` reconstruido en los Bloques 0-2 de `docs/product/ALCANCE-V2.md`. El Bloque 3 (mapa en vivo, tracking, SOS) no existe todavía — sigue bloqueado por el experimento 1. Ver `docs/dev-runs/refactor-v2.md` para el cierre de la corrida que los produjo.

## Features

| Feature | Documento | Resumen corto |
|---|---|---|
| **Auth** | [auth.md](./auth.md) | Bienvenida L2, Supabase Auth (Google/Apple/correo), AuthCubit observa la sesión |
| **Profile** | [profile.md](./profile.md) | Ficha del rider, contacto de emergencia, consentimientos, borrado de cuenta in-app |
| **Garage** | [garage.md](./garage.md) | Galería de motos, alta por placa, moto principal, archivar, alerta de documentos |
| **Documents** | [documents.md](./documents.md) | SOAT y RTM como un solo modelo, OCR on-device, caché offline, recordatorios locales |
| **Maintenance** | [maintenance.md](./maintenance.md) | Agenda derivada + historial, registro en 3 pasos, odómetro derivado (D5) |
| **Events** | [events.md](./events.md) | Rodadas sin mapa: crear/publicar, inscripción con capa legal, aviso de inicio, inscritos del organizador |

## Documentos transversales

Documentación que no describe un feature de negocio, sino una convención/infraestructura que cruza varios features:

| Documento | Resumen corto |
|---|---|
| [analytics.md](./analytics.md) | Reglas de un único punto de importación por SDK Firebase (Analytics/Crashlytics→Sentry), contrato de `CrashReporter` |

## Cómo usar esta documentación

### Como desarrollador (humano)
- Antes de implementar una feature nueva: lee la doc del feature relacionado para entender la arquitectura existente.
- Si vas a modificar un flujo: busca la sección de "Patrones y trampas conocidas".
- Para encontrar un archivo específico: usa la tabla "Archivos clave de referencia rápida" al final de cada doc.

### Como contexto para Claude / agentes
- Estas docs sirven como verdad sobre la implementación actual.
- Si el código diverge de la doc, **actualiza la doc** (no solo el código).
- Las trampas documentadas (sentinel patterns, optimistic updates sin rollback, throttling, etc.) son críticas para mantener consistencia al hacer cambios.

## Convenciones

- Lenguaje: **Español (es-CO)**.
- Profundidad: estructura, modelo de dominio, capas, cubits, flujos, rutas, endpoints, conexiones cross-feature, patrones inusuales.
- Cada feature tiene su sección "Archivos clave de referencia rápida" para navegación.
- Endpoints y nombres de archivo se citan con path completo desde `lib/`.

## Mantenimiento

- **Al cambiar comportamiento de un feature**: actualizar la sección correspondiente. Mínimo: la fecha "Última actualización" al inicio.
- **Al agregar un feature nuevo**: crear `<feature>.md` siguiendo el formato de los existentes y agregar entrada a este índice.
- **Al deprecar/eliminar**: actualizar la doc explicando reemplazo, o eliminarla si el feature ya no existe.
