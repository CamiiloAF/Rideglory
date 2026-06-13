import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';

/// Bottom bar for the edit mode — "Actualizar evento" save button.
class EditingBottomBar extends StatelessWidget {
  const EditingBottomBar({
    super.key,
    required this.isLoading,
    required this.cubit,
  });

  final bool isLoading;
  final EventFormCubit cubit;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safePadding = bottomPadding < 16 ? 16.0 : bottomPadding;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkBgPrimary,
        border: Border(top: BorderSide(color: AppColors.darkBorderPrimary)),
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, safePadding),
      child: AppButton(
        label: context.l10n.event_updateEvent,
        isLoading: isLoading,
        onPressed: isLoading ? null : () => _onSave(context),
        icon: Icons.save_outlined,
      ),
    );
  }

  Future<void> _onSave(BuildContext context) async {
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
