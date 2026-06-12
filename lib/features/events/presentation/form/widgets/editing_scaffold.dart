import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/editing_bottom_bar.dart';
import 'package:rideglory/features/events/presentation/form/widgets/editing_form_body.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';

/// Scaffold for editing mode: original flat scroll layout preserved.
class EditingScaffold extends StatelessWidget {
  const EditingScaffold({super.key, required this.isSaving});

  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EventFormCubit>();

    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppFormNavHeader(
        title: context.l10n.event_editEvent,
        leading: AppFormNavAction.text(
          label: context.l10n.cancel,
          onTap: () => context.pop(),
        ),
        trailing: AppFormNavAction.text(
          label: context.l10n.event_form_publish_action,
          onTap: () => _onPublish(context),
          emphasized: true,
          isLoading: isSaving,
        ),
      ),
      body: const EditingFormBody(),
      bottomNavigationBar: EditingBottomBar(
        isLoading: isSaving,
        cubit: cubit,
      ),
    );
  }

  Future<void> _onPublish(BuildContext context) async {
    final cubit = context.read<EventFormCubit>();
    final imageCubit = context.read<FormImageCubit>();
    final event = await cubit.buildEventToSave();
    if (!context.mounted) return;
    if (event != null) {
      final imageState = imageCubit.state;
      final imageData = imageState.whenOrNull(data: (data) => data);
      await cubit.saveEvent(
        event,
        localCoverImagePath:
            imageData?.hasLocalImage == true ? imageData?.localImagePath : null,
        remoteCoverImageUrl: imageData?.hasLocalImage != true
            ? imageData?.remoteImageUrl
            : null,
      );
    }
  }
}
