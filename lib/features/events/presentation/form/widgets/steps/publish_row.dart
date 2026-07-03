import 'package:flutter/material.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/event_organizer_responsibility_sheet.dart';

/// Fila de acciones del step 4.
///
/// - Modo creación: "Publicar evento" (guarda y cierra).
/// - Modo edición: "Cerrar" (los cambios ya se guardaron por sección).
class PublishRow extends StatelessWidget {
  const PublishRow({super.key, required this.isSaving, required this.cubit});

  final bool isSaving;
  final EventFormCubit cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit.isEditing) {
      return AppButton(
        label: context.l10n.event_step_close,
        onPressed: () {
          final savedEvent = cubit.state.saveResult.whenOrNull(
            data: (event) => event,
          );
          Navigator.of(context).pop(savedEvent);
        },
        variant: AppButtonVariant.ghost,
        shape: AppButtonShape.pill,
        height: 52,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          label: context.l10n.event_step_review_publishButton,
          isLoading: isSaving,
          onPressed: isSaving ? null : () => _onPublish(context),
          icon: Icons.send_rounded,
          shape: AppButtonShape.pill,
          height: 52,
        ),
      ],
    );
  }

  Future<void> _onPublish(BuildContext context) async {
    final event = await cubit.buildEventToSave();
    if (!context.mounted) return;
    if (event == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.event_formIncompleteMessage)),
      );
      return;
    }

    // Modo creación: la responsabilidad legal del organizador se declara en un
    // bottom sheet, reusando las mismas instancias de cubit para que el cierre
    // del wizard (listener de EventFormView) siga funcionando tras publicar.
    final saved = await showEventOrganizerResponsibilitySheet(
      context: context,
      eventToSave: event,
    );
    // Cierra la página de creación devolviendo el evento guardado para que la
    // lista lo agregue (pop-result). Si el organizador tocó "Revisar evento"
    // (saved == null), se queda en el formulario.
    if (saved != null && context.mounted) {
      Navigator.of(context).pop(saved);
    }
  }
}
