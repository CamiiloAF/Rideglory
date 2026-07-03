# Review Checklist — legal-privacidad-edad-fase7-organizador

Pasos manuales para el humano antes de commitear (el árbol queda sucio a propósito).

## 1. Revisar el diff

```
git status --porcelain
git diff -- lib/features/event_registration/
git diff -- test/features/event_registration/ test/features/events/
```

Confirmar que solo estos 6 archivos modificados + 2 archivos nuevos aparecen
(fuera de `docs/exec-runs/`):

- [ ] `lib/features/event_registration/data/dto/event_registration_dto.dart`
- [ ] `lib/features/event_registration/domain/model/event_registration_model.dart`
- [ ] `lib/features/event_registration/presentation/registration_detail_page.dart`
- [ ] `test/features/event_registration/data/dto/event_registration_dto_test.dart`
- [ ] `test/features/event_registration/presentation/registration_detail_page_test.dart`
- [ ] `test/features/events/presentation/attendees/widgets/attendees_list_navigation_test.dart`
- [ ] `integration_test/registration_organizer_patrol_test.dart` (nuevo)
- [ ] `test/features/events/presentation/detail/widgets/event_detail_participants_section_test.dart` (nuevo)

## 2. Regenerar codigo si aun no se hizo en tu maquina

```
dart run build_runner build --delete-conflicting-outputs
```

Confirmar que `event_registration_dto.g.dart` no incluye una clave literal
`bloodTypeRaw` en `fromJson`/`toJson` generados (esta gitignored, no aparece
en el diff, pero debe existir localmente tras el build).

## 3. Analisis estatico

```
dart analyze lib/features/event_registration/
dart analyze
```

Esperado: 0 issues en los archivos tocados por esta fase (puede haber infos
preexistentes en otros archivos, no relacionados).

## 4. Tests

```
flutter test test/features/event_registration/ --concurrency=1
flutter test test/features/events/presentation/detail/widgets/event_detail_participants_section_test.dart test/features/events/presentation/attendees/widgets/attendees_list_navigation_test.dart
flutter test
```

Esperado: todos en verde (101/101, 7/7, y la suite completa sin regresiones).

## 5. Patrol e2e (opcional, requiere emulador)

Para ejercitar tambien la rama de botones de contacto (Llamar/WhatsApp), sembrar
primero una inscripcion de `qa1@gmail.com` con `allowOrganizerContact=true` en
"Mi Evento", luego:

```
patrol test -t integration_test/registration_organizer_patrol_test.dart \
  --flavor dev --dart-define-from-file=config/dev.json \
  --dart-define=TEST_EMAIL=qa2@gmail.com --dart-define=TEST_PASSWORD=Test123.
```

Nota: usar `-d/--device` (no `--device-id`, desactualizado en un handoff previo).

## 6. Verificacion funcional manual (recomendada, no bloqueante)

- [ ] Abrir el detalle de una inscripcion sin `bloodType` compartido (backend
      retorna sentinel no mapeable) desde la vista organizador: debe mostrar
      el string crudo (p. ej. `"••••"`), nunca crash ni `"null"`.
- [ ] Abrir una inscripcion con `bloodType=null` y sin ningun sentinel: debe
      mostrar `"N/A"`.
- [ ] Tap real en "Llamar"/"WhatsApp" en un dispositivo con esas apps
      instaladas: confirmar que abren el marcador/WhatsApp correctamente.

## 7. Decision sobre deuda menor (opcional)

- [ ] Decidir si eliminar la clave ARB `registration_maskedValue` (queda sin
      call-sites tras el fix de AC10) — cambio de 1 linea en `app_es.arb` +
      `flutter gen-l10n`, no bloqueante para esta fase.

## 8. Commit

Una vez verificado lo anterior, commitear con el mensaje sugerido en
`SUMMARY.md` (el humano ejecuta el commit; ningun agente de esta corrida
ejecuta `git add`/`commit`/`push`).
