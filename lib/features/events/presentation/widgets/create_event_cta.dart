import 'package:flutter/widgets.dart';

import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/components/saving_button.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/create_event_cubit.dart';
import '../cubit/create_event_state.dart';
import '../../../../core/domain/result_state.dart';

/// CTA inferior del asistente de creación: cambia de "Siguiente" a
/// "Publicar rodada" / "Publicando…" / "Reintentar" según el paso y el
/// estado del envío.
class CreateEventCta extends StatelessWidget {
  const CreateEventCta({
    required this.state,
    required this.cubit,
    required this.isSaving,
    super.key,
  });

  final CreateEventState state;
  final CreateEventCubit cubit;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    if (isSaving) {
      return SavingButton(label: context.l10n.events_create_saving);
    }
    if (state.step == 0) {
      return AppPrimaryButton(
        label: context.l10n.events_create_next_cta,
        onPressed: state.canContinueStep1 ? cubit.nextStep : null,
      );
    }
    if (state.step == 1) {
      return AppPrimaryButton(
        label: context.l10n.events_create_next_cta,
        onPressed: state.canContinueStep2 ? cubit.nextStep : null,
      );
    }
    final hasError = state.submission.maybeWhen(
      error: (_) => true,
      orElse: () => false,
    );
    return AppPrimaryButton(
      label: hasError
          ? context.l10n.common_retry
          : context.l10n.events_create_publish_cta,
      onPressed: state.canSubmit ? cubit.submit : null,
    );
  }
}
