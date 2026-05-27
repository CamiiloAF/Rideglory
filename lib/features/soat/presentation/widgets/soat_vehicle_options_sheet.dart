import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/soat/presentation/cubit/soat_upload_cubit.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_manual_option_card.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_upload_option_card.dart';

sealed class SoatOptionsResult {}

final class SoatOptionsUpload extends SoatOptionsResult {
  SoatOptionsUpload(this.image);
  final XFile image;
}

final class SoatOptionsManual extends SoatOptionsResult {}

class SoatVehicleOptionsSheet extends StatelessWidget {
  const SoatVehicleOptionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SoatUploadCubit>(),
      child: const _SheetContent(),
    );
  }
}

class _SheetContent extends StatelessWidget {
  const _SheetContent();

  @override
  Widget build(BuildContext context) {
    return BlocListener<SoatUploadCubit, SoatUploadState>(
      listener: (context, state) {
        if (state is SoatUploadImagePicked) {
          // Custom: Navigator.pop preserved — closes showModalBottomSheet route with typed result.
          Navigator.of(context).pop(SoatOptionsUpload(state.image));
        } else if (state is SoatUploadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: BlocBuilder<SoatUploadCubit, SoatUploadState>(
        builder: (context, state) {
          final isLoading = state is SoatUploadPicking;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.darkBorderPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SoatUploadOptionCard(
                    isLoading: isLoading,
                    onCameraTap: () =>
                        context.read<SoatUploadCubit>().pickFromCamera(),
                    onGalleryTap: () =>
                        context.read<SoatUploadCubit>().pickFromGallery(),
                    onFileTap: () =>
                        context.read<SoatUploadCubit>().pickFromFile(),
                  ),
                  const SizedBox(height: 16),
                  SoatManualOptionCard(
                    // Custom: Navigator.pop preserved — closes showModalBottomSheet route with typed result.
                    onTap: () =>
                        Navigator.of(context).pop(SoatOptionsManual()),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
