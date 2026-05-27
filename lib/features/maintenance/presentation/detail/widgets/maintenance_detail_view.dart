import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/delete/cubit/maintenance_delete_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/detail/widgets/maintenance_cta_bar.dart';
import 'package:rideglory/features/maintenance/presentation/detail/widgets/maintenance_detail_icon_button.dart';
import 'package:rideglory/features/maintenance/presentation/detail/widgets/maintenance_info_card.dart';
import 'package:rideglory/features/maintenance/presentation/detail/widgets/maintenance_next_service_card.dart';
import 'package:rideglory/features/maintenance/presentation/detail/widgets/maintenance_notes_card.dart';
import 'package:rideglory/features/maintenance/presentation/detail/widgets/maintenance_options_bottom_sheet.dart';
import 'package:rideglory/features/maintenance/presentation/detail/widgets/maintenance_type_card.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class MaintenanceDetailView extends StatefulWidget {
  const MaintenanceDetailView({super.key, required this.maintenance});

  final MaintenanceModel maintenance;

  @override
  State<MaintenanceDetailView> createState() => _MaintenanceDetailViewState();
}

class _MaintenanceDetailViewState extends State<MaintenanceDetailView> {
  late MaintenanceModel _maintenance;
  bool _wasUpdated = false;

  @override
  void initState() {
    super.initState();
    _maintenance = widget.maintenance;
  }

  void _popWithResult() {
    context.pop(_wasUpdated ? _maintenance : null);
  }

  Future<void> _showOptions() async {
    final action = await MaintenanceOptionsBottomSheet.show(context);

    if (action == MaintenanceAction.edit && mounted) {
      final raw = await context.pushNamed<dynamic>(
        AppRoutes.editMaintenance,
        extra: _maintenance,
      );
      final result = raw is List<MaintenanceModel> ? raw.first : raw as MaintenanceModel?;
      if (result != null && mounted) {
        setState(() {
          _maintenance = result;
          _wasUpdated = true;
        });
      }
    } else if (action == MaintenanceAction.delete && mounted) {
      _confirmDelete();
    }
  }

  Future<void> _onEdit() async {
    final raw = await context.pushNamed<dynamic>(
      AppRoutes.editMaintenance,
      extra: _maintenance,
    );
    final result = raw is List<MaintenanceModel> ? raw.first : raw as MaintenanceModel?;
    if (result != null && mounted) {
      setState(() {
        _maintenance = result;
        _wasUpdated = true;
      });
    }
  }

  void _onDelete() => _confirmDelete();

  Future<void> _confirmDelete() async {
    final confirm = await ConfirmationDialog.show(
      context: context,
      title: context.l10n.maintenance_deleteMaintenance,
      content: context.l10n.maintenance_deleteMaintenanceMessage,
      confirmLabel: context.l10n.delete,
      confirmType: DialogActionType.danger,
    );
    if (confirm == true && mounted) {
      context.read<MaintenanceDeleteCubit>().deleteMaintenance(_maintenance);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MaintenanceDeleteCubit, MaintenanceDeleteState>(
      listener: (context, state) {
        state.whenOrNull(
          success: (deletedId) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.l10n.maintenance_maintenanceDeletedSuccessfully,
                ),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop({'action': 'deleted', 'deletedId': deletedId});
          },
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.errorMessage(message)),
                backgroundColor: AppColors.error,
              ),
            );
          },
        );
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _popWithResult();
        },
        child: Scaffold(
          backgroundColor: AppColors.darkBgPrimary,
          appBar: AppBar(
            backgroundColor: AppColors.darkBgPrimary,
            elevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  MaintenanceDetailIconButton(
                    icon: Icons.arrow_back,
                    onTap: _popWithResult,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.maintenance_maintenanceDetail,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textOnDarkPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  MaintenanceDetailIconButton(
                    icon: Icons.more_vert,
                    onTap: _showOptions,
                  ),
                ],
              ),
            ),
          ),
          body: BlocBuilder<VehicleCubit, ResultState<List<VehicleModel>>>(
            builder: (context, vehicleState) {
              VehicleModel? vehicle;
              if (_maintenance.vehicleId != null) {
                try {
                  vehicle = context.read<VehicleCubit>().availableVehicles
                      .firstWhere((v) => v.id == _maintenance.vehicleId);
                } catch (_) {}
              }

              final hasNotes =
                  _maintenance.notes != null && _maintenance.notes!.isNotEmpty;
              final hasNextService = _maintenance.nextDate != null ||
                  _maintenance.nextOdometer != null;

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MaintenanceTypeCard(
                            maintenance: _maintenance,
                            vehicle: vehicle,
                          ),
                          if (_maintenance.mode == MaintenanceMode.completed) ...[
                            const SizedBox(height: 16),
                            MaintenanceInfoCard(maintenance: _maintenance),
                          ],
                          if (hasNotes) ...[
                            const SizedBox(height: 16),
                            MaintenanceNotesCard(notes: _maintenance.notes!),
                          ],
                          if (hasNextService) ...[
                            const SizedBox(height: 16),
                            MaintenanceNextServiceCard(
                              maintenance: _maintenance,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  MaintenanceCtaBar(onEdit: _onEdit, onDelete: _onDelete),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
