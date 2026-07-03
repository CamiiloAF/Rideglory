import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_model.dart';
import 'package:rideglory/features/vehicle_documents/presentation/cubit/vehicle_document_cubit.dart';
import 'package:rideglory/features/vehicle_documents/presentation/widgets/status_view_error_body.dart';

/// Generic scaffold that renders the [ResultState] of a [VehicleDocumentCubit].
///
/// Consumers provide the loading, empty, data, and error child widgets.
/// The scaffold itself handles the [AppBar] with optional [actions] for the
/// data state.
class DocumentStatusView<
  C extends VehicleDocumentCubit<T>,
  T extends VehicleDocumentModel
>
    extends StatelessWidget {
  const DocumentStatusView({
    super.key,
    required this.title,
    required this.vehicle,
    required this.buildEmpty,
    required this.buildData,
    this.buildDataActions,
    required this.onRetry,
  });

  final String title;
  final dynamic vehicle;
  final Widget Function(BuildContext context) buildEmpty;
  final Widget Function(BuildContext context, T data) buildData;
  final List<Widget> Function(BuildContext context, T data)? buildDataActions;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppBar(
        title: Text(
          title,
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
        leading: const BackButton(
          color: AppColors.textOnDarkPrimary,
          style: ButtonStyle(iconSize: WidgetStatePropertyAll(20)),
        ),
        actions: buildDataActions != null
            ? [
                BlocBuilder<C, ResultState<T>>(
                  builder: (context, state) {
                    if (state is! Data<T>) return const SizedBox.shrink();
                    return Row(
                      children: buildDataActions!(context, state.data),
                    );
                  },
                ),
              ]
            : null,
      ),
      body: BlocBuilder<C, ResultState<T>>(
        builder: (context, state) {
          if (state is Initial || state is Loading) {
            return const AppLoadingIndicator(
              variant: AppLoadingIndicatorVariant.page,
            );
          }
          if (state is Empty) {
            return buildEmpty(context);
          }
          if (state is Data<T>) {
            return buildData(context, state.data);
          }
          if (state is Error<T>) {
            return StatusViewErrorBody(
              message: state.error.message,
              onRetry: onRetry,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
