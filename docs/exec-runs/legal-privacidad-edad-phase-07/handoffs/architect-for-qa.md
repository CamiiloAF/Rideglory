> Slim handoff — read this before handoffs/architect.md

# Architect → QA

Esta corrida es **retroactiva**: gran parte del alcance ya está en el árbol de
trabajo. Tu trabajo es verificación + cerrar el único gap real + generar el
Patrol organizador ausente.

## Trazabilidad de criterios de aceptación (12 del PRD)

| AC | Estado por lectura de código | Qué correr |
|----|-------------------------------|------------|
| 1-4 (isOrganizerView en los 3 nav points + vista piloto no afectada) | Ya implementado, código verificado | `flutter test test/features/event_registration/` |
| 5-6 (botones de contacto visibles/ocultos) | Ya implementado, tests existen | `registration_detail_bottom_bar_test.dart`, `registration_contact_actions_test.dart` |
| 7-8 (tap Llamar/WhatsApp → UrlLauncherHelper) | Ya implementado | mismo archivo de test de contact_actions |
| 9 (datos ofuscados `"••••"` se muestran literal) | Ya implementado (campos string simples, sin transformar) | revisar `registration_detail_page_test.dart` |
| **10 (bloodType nullable fallback)** | **NO cumplido hoy** — falta `bloodTypeRaw`; Frontend lo agrega en esta corrida | Confirmar que el nuevo fallback (`bloodType?.label ?? bloodTypeRaw ?? notAvailable`) está y que ningún caso muestra `"null"` ni crashea |
| 11 (l10n sin hardcodeo) | Ya cumplido (`registration_callButton`/`whatsappButton` existen) | grep manual |
| 12 (dart analyze limpio) | Pendiente de correr tras el fix de AC10 | `dart analyze` |

## Gap a verificar específicamente

Antes del fix de Frontend: `registration_detail_page.dart` muestra `"••••"`
SIEMPRE que `bloodType == null`, sin distinguir la razón. Después del fix debe
distinguir: valor crudo del backend si existe, si no `"N/A"`.

## Patrol e2e organizador — no existe, generarlo

`integration_test/registration_patrol_test.dart` (176 líneas, existente) cubre
solo el flujo del piloto. No hay cobertura Patrol del flujo organizador. Casos
mínimos a generar en `integration_test/registration_organizer_patrol_test.dart`:

1. Abrir detalle desde `AttendeesList` (rama pending) → título "Detalles de solicitud".
2. Abrir detalle desde `AttendeesList` (rama processed) → misma vista organizador.
3. Inscripción `approved` + `allowOrganizerContact=true` → fila de 2 botones Llamar/WhatsApp visible.
4. Inscripción con `allowOrganizerContact=false` y sin acciones pendientes → bottom bar es `SizedBox.shrink()`.
5. Vista piloto (`MyRegistrations`) sigue mostrando "Mi inscripción" — regresión negativa, confirma que NO aparecen botones de contacto ahí aunque `allowOrganizerContact=true`.

## Comandos

```bash
flutter test test/features/event_registration/
flutter test test/features/events/
dart analyze
# tras generar el Patrol nuevo:
patrol test -t integration_test/registration_organizer_patrol_test.dart
```

> Full detail: handoffs/architect.md
