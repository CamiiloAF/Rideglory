import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/soat/presentation/cubit/soat_cubit.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_data_view.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_empty_state.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/soat/presentation/pages/soat_manual_capture_params.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class SoatStatusView extends StatelessWidget {
  const SoatStatusView({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppBar(
        title: Text(
          context.l10n.soat_page_status_title,
          style: const TextStyle(
            color: AppColors.textOnDarkPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.darkBgPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textOnDarkPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          BlocBuilder<SoatCubit, ResultState<SoatModel>>(
            builder: (context, state) {
              if (state is! Data<SoatModel>) return const SizedBox.shrink();
              return AppTextButton(
                label: context.l10n.soat_edit_btn,
                onPressed: () => context
                    .push<bool>(
                      AppRoutes.soatManualCapture,
                      extra: SoatManualCaptureParams(vehicle: vehicle),
                    )
                    .then((_) {
                  if (context.mounted) {
                    context.read<SoatCubit>().load(vehicle.id ?? '');
                  }
                }),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<SoatCubit, ResultState<SoatModel>>(
        builder: (context, state) {
          if (state is Initial || state is Loading) {
            return const AppLoadingIndicator(
              variant: AppLoadingIndicatorVariant.page,
            );
          } else if (state is Empty) {
            return SoatEmptyState(vehicle: vehicle);
          } else if (state is Data) {
            return SoatDataView(
              vehicle: vehicle,
              soat: (state as Data<SoatModel>).data,
            );
          } else if (state is Error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 48,
                    ),
                    AppSpacing.gapLg,
                    Text(
                      (state as Error<SoatModel>).error.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textOnDarkSecondary,
                        fontSize: 14,
                      ),
                    ),
                    AppSpacing.gapLg,
                    AppButton(
                      label: context.l10n.retry,
                      onPressed: () =>
                          context.read<SoatCubit>().load(vehicle.id ?? ''),
                      isFullWidth: false,
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
