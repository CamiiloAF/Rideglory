# Frontend Handoff — app-ai-description-assistant

Estado final: COMPLETO. `dart analyze lib/` → 0 issues. `flutter test` (20 tests) → 20/20 pass.

---

## Cambios aplicados

### 1. `lib/features/events/data/repository/ai_description_repository_impl.dart`
Todas las instancias de `Left(XException(...))` convertidas a `const Left(XException(...))` para satisfacer `prefer_const_constructors`. Afectó 4 constructores: `AiQuotaExceededUserException`, `AiQuotaExceededProjectException`, `AiSafetyBlockedException`, `AiNetworkErrorException`.

### 2. `lib/features/events/presentation/form/widgets/ai_chat/ai_insert_button.dart`
Eliminado el import directo de `confirmation_dialog.dart`. `ConfirmationDialog` ya está re-exportado por `design_system.dart` → `molecules.dart`.

### 3. `lib/features/events/presentation/form/widgets/sections/event_form_basic_info_section.dart`
**Bug de producción corregido**: `_buildEventContext()` usaba `FormBuilder.of(context)?.value` (que devuelve `_savedValue`, solo poblado tras `save()`) en lugar de `FormBuilder.of(context)?.instantValue` (que devuelve el estado actual de los campos). Con `value`, los campos siempre llegaban vacíos al sheet de IA aunque el usuario hubiera escrito en el formulario. Corregido a `instantValue`.

### 4. Tests nuevos creados

| Archivo | ACs cubiertos | Tests |
|---|---|---|
| `test/shared/widgets/form/app_rich_text_editor_external_controller_test.dart` | AC3, AC4, AC5, AC6, AC7, AC8 | 6 |
| `test/features/events/presentation/form/cubit/ai_description_chat_cubit_test.dart` | AC15, AC16 | 5 |
| `test/features/events/presentation/form/widgets/ai_chat/ai_description_chat_sheet_test.dart` | AC13, AC14 | 5 |
| `test/features/events/presentation/form/widgets/sections/event_form_basic_info_section_test.dart` | AC17, AC18 | 4 |

**Total: 20 tests, 20/20 pass.**

---

## Patrones técnicos relevantes

- `FormBuilderState.instantValue` (no `.value`) es el getter correcto para leer campos en tiempo real sin haber llamado `save()`.
- Tests de widgets con `QuillEditor` requieren `FlutterQuillLocalizations.delegate` en `localizationsDelegates`.
- `MockCubit<AiDescriptionChatState> implements AiDescriptionChatCubit` + `whenListen(...)` es el patrón correcto para inyectar cubits en tests de widgets vía GetIt.
- Para verificar que un controller externo NO es dispuesto: usar un spy `class _Spy extends QuillController` con contador `disposeCallCount`.
- `FormBuilder.of(context)?.instantValue` desde el contexto del State es equivalente a `formKey.currentState!.instantValue` — ambos apuntan al mismo `FormBuilderState`.
