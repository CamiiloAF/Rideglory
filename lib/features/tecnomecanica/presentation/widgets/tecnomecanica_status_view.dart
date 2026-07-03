import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';
import 'package:rideglory/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit.dart';
import 'package:rideglory/features/tecnomecanica/presentation/pages/tecnomecanica_manual_capture_params.dart';
import 'package:rideglory/features/tecnomecanica/presentation/widgets/tecnomecanica_data_view.dart';
import 'package:rideglory/features/tecnomecanica/presentation/widgets/tecnomecanica_empty_state.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class TecnomecanicaStatusView extends StatelessWidget {
  const TecnomecanicaStatusView({
    super.key,
    required this.vehicle,
    this.isArchived = false,
  });

  final VehicleModel vehicle;
  final bool isArchived;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppBar(
        title: Text(
          context.l10n.tecnomecanica_page_status_title,
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
          if (!isArchived)
            BlocBuilder<TecnomecanicaCubit, ResultState<TecnomecanicaModel>>(
              builder: (context, state) {
                if (state is! Data<TecnomecanicaModel>) {
                  return const SizedBox.shrink();
                }
                return AppTextButton(
                  label: context.l10n.tecnomecanica_edit_btn,
                  onPressed: () => context
                      .push<bool>(
                        AppRoutes.tecnomecanicaManualCapture,
                        extra: TecnomecanicaManualCaptureParams(
                          cubit: context.read<TecnomecanicaCubit>(),
                          vehicle: vehicle,
                          existingRtm: state.data,
                        ),
                      )
                      .then((_) {
                        if (context.mounted) {
                          context.read<TecnomecanicaCubit>().load(
                            vehicle.id ?? '',
                          );
                        }
                      }),
                );
              },
            ),
        ],
      ),
      body: BlocBuilder<TecnomecanicaCubit, ResultState<TecnomecanicaModel>>(
        builder: (context, state) {
          if (state is Initial || state is Loading) {
            return const AppLoadingIndicator(
              variant: AppLoadingIndicatorVariant.page,
            );
          } else if (state is Empty) {
            return TecnomecanicaEmptyState(vehicle: vehicle);
          } else if (state is Data) {
            return TecnomecanicaDataView(
              vehicle: vehicle,
              rtm: (state as Data<TecnomecanicaModel>).data,
              isArchived: isArchived,
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
                      (state as Error<TecnomecanicaModel>).error.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textOnDarkSecondary,
                        fontSize: 14,
                      ),
                    ),
                    AppSpacing.gapLg,
                    AppButton(
                      label: context.l10n.retry,
                      onPressed: () => context.read<TecnomecanicaCubit>().load(
                        vehicle.id ?? '',
                      ),
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
