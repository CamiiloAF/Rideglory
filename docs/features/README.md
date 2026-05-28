# Documentación por Feature — Rideglory

> Índice de la documentación detallada de cada feature de la app.

Cada archivo describe **cómo está construido** un feature en profundidad: modelo de dominio, capas (domain/data/presentation), cubits y estados, flujos, rutas, endpoints API, conexiones con otros features, y patrones/trampas conocidas.

El objetivo es servir como **contexto base** para cualquier desarrollador (o agente) que vaya a trabajar en el feature: leer la doc primero para no inventar comportamientos que no existen, ni omitir matices.

> Regla de mantenimiento: **al modificar código de un feature, actualizar la sección relevante de su doc**. Ver `feedback_update_feature_docs` en el sistema de memorias.

## Features

| Feature | Documento | Resumen corto |
|---|---|---|
| **Splash** | [splash.md](./splash.md) | Pantalla inicial, permisos de ubicación, decisión login vs home |
| **Authentication** | [authentication.md](./authentication.md) | Login/Signup email + Google (+ Apple stub), forgot password, AuthCubit singleton |
| **Profile** | [profile.md](./profile.md) | Perfil propio (lectura + atajos). Edición no persiste todavía |
| **Users** | [users.md](./users.md) | UserModel + UserRepository, RiderProfilePage (perfil de otro rider), storage local |
| **Home** | [home.md](./home.md) | Dashboard: vehículo principal + próximos eventos + campana de notif |
| **Vehicles** | [vehicles.md](./vehicles.md) | Garage, CRUD vehículos, vehículo principal, archivar, integración SOAT |
| **Maintenance** | [maintenance.md](./maintenance.md) | Mantenimientos completed/scheduled, status dinámico, auto-creación post-completed |
| **SOAT** | [soat.md](./soat.md) | Captura del SOAT (foto/PDF o manual), cálculo de vigencia, status |
| **Events** | [events.md](./events.md) | CRUD eventos, ciclo de vida (draft→scheduled→inProgress→finished), tracking en vivo, asistentes |
| **Event Registration** | [event_registration.md](./event_registration.md) | Inscripciones, pre-llenado en cascada, saveToProfile, mis inscripciones |
| **Notifications** | [notifications.md](./notifications.md) | Centro de notif, FCM, deep linking, badge de no-leídas |

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
