import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/delete/cubit/vehicle_delete_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/list/cubit/vehicle_list_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/vehicle_card.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/app_app_bar.dart';
import 'package:rideglory/shared/widgets/app_drawer.dart';
import 'package:rideglory/shared/widgets/empty_state_widget.dart';
import 'package:rideglory/shared/widgets/form/app_search_bar.dart';
import 'package:rideglory/shared/widgets/modals/app_dialog.dart';
import 'package:rideglory/shared/widgets/modals/confirmation_dialog.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_strings.dart';
import 'package:rideglory/shared/widgets/modals/dialog_type.dart';
import 'package:rideglory/shared/widgets/no_search_results_empty_widget.dart';

class VehicleListPage extends StatelessWidget {
  const VehicleListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<VehicleDeleteCubit>(),
      child: const _VehicleListView(),
    );
  }
}

class _VehicleListView extends StatefulWidget {
  const _VehicleListView();

  @override
  State<_VehicleListView> createState() => _VehicleListViewState();
}

class _VehicleListViewState extends State<_VehicleListView> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleListCubit>().loadVehicles();
    });

    super.initState();
  }

  Future<void> _goToEditVehicle(
    BuildContext context,
    VehicleModel vehicle,
  ) async {
    final result = await context.pushNamed<VehicleModel?>(
      AppRoutes.editVehicle,
      extra: vehicle,
    );
    if (result != null && context.mounted) {
      context.read<VehicleListCubit>().updateVehicleLocally(result);
    }
  }

  Future<void> _loadVechicles(BuildContext context) =>
      context.read<VehicleListCubit>().loadVehicles();

  Future<void> _goToCreateVehicle(BuildContext context) async {
    final result = await context.pushNamed<VehicleModel?>(
      AppRoutes.createVehicle,
    );
    if (result != null && context.mounted) {
      context.read<VehicleListCubit>().addVehicleLocally(result);
    }
  }

  Future<void> _goToCreateMaintenance(
    BuildContext context,
    VehicleModel vehicle,
  ) async {
    await context.pushNamed(AppRoutes.createMaintenance, extra: vehicle);
  }

  void _showDeleteDialog(BuildContext context, VehicleModel vehicle) async {
    ConfirmationDialog.show(
      context: context,
      title: VehicleStrings.deleteVehicle,
      content:
          '${VehicleStrings.deleteVehicleMessage} "${vehicle.name}"? ${VehicleStrings.deleteVehicleWarning}',
      cancelLabel: AppStrings.cancel,
      confirmLabel: AppStrings.delete,
      confirmType: DialogActionType.danger,
      dialogType: DialogType.warning,
      onConfirm: () {
        if (vehicle.id != null) {
          final vehicleListState = context.read<VehicleListCubit>().state;
          final availableVehicles = vehicleListState is Data<List<VehicleModel>>
              ? vehicleListState.data
              : <VehicleModel>[];
          context.read<VehicleDeleteCubit>().deleteVehicle(
            vehicle.id!,
            availableVehicles: availableVehicles,
          );
        }
      },
    );
  }

  void _deleteVehicleListener(BuildContext context, VehicleDeleteState state) {
    state.whenOrNull(
      success: (deletedId) {
        context.read<VehicleListCubit>().removeVehicleFromList(deletedId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(VehicleStrings.vehicleDeleted),
            backgroundColor: Colors.green,
          ),
        );
      },
      error: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.errorMessage(message)),
            backgroundColor: Colors.red,
          ),
        );
      },
      errorLastVehicle: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final showingArchived = context
        .watch<VehicleListCubit>()
        .showArchivedVehicles;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppAppBar(
        title: showingArchived
            ? VehicleStrings.archivedVehicle
            : VehicleStrings.myVehicles,
        actions: [
          IconButton(
            icon: Icon(
              showingArchived ? Icons.inventory_2 : Icons.inventory_2_outlined,
            ),
            onPressed: () {
              context.read<VehicleListCubit>().toggleShowArchived();
            },
            tooltip: showingArchived
                ? VehicleStrings.showActiveVehicles
                : VehicleStrings.viewArchived,
          ),
          if (!showingArchived) ...[
            IconButton(
              icon: const Icon(Icons.build_circle_outlined),
              onPressed: () {
                context.pushNamed(AppRoutes.maintenances);
              },
              tooltip: VehicleStrings.maintenancesTooltip,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                await _goToCreateVehicle(context);
              },
              tooltip: VehicleStrings.addVehicleTooltip,
            ),
          ],
        ],
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.vehicles),
      body: MultiBlocListener(
        listeners: [
          BlocListener<VehicleDeleteCubit, VehicleDeleteState>(
            listener: _deleteVehicleListener,
          ),
        ],
        child: BlocBuilder<VehicleListCubit, ResultState<List<VehicleModel>>>(
          builder: (context, state) {
            return state.maybeWhen(
              orElse: () => const Center(child: CircularProgressIndicator()),
              error: (error) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppStrings.errorMessage(error.message)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _loadVechicles(context);
                      },
                      child: Text(AppStrings.retry),
                    ),
                  ],
                ),
              ),
              empty: () {
                return EmptyStateWidget(
                  icon: showingArchived
                      ? Icons.inventory_2_outlined
                      : Icons.directions_car_outlined,
                  title: showingArchived
                      ? VehicleStrings.noArchivedVehicles
                      : VehicleStrings.noVehicles,
                  description: showingArchived
                      ? VehicleStrings.archiveVehiclesDescription
                      : VehicleStrings.addFirstVehicle,
                  actionButtonText: showingArchived
                      ? null
                      : VehicleStrings.addVehicle,
                  onActionPressed: showingArchived
                      ? null
                      : () {
                          _goToCreateVehicle(context);
                        },
                );
              },
              data: (vehicles) {
                final currentVehicleId = context
                    .watch<VehicleCubit>()
                    .currentVehicle
                    ?.id;

                return RefreshIndicator(
                  onRefresh: () async {
                    await _loadVechicles(context);
                  },
                  // TODO Move to another widget
                  child: Column(
                    children: [
                      // Search bar
                      if (!showingArchived)
                        AppSearchBar(
                          hintText: VehicleStrings.searchVehicles,
                          onSearchChanged: (value) {
                            context.read<VehicleListCubit>().updateSearchQuery(
                              value,
                            );
                          },
                        ),
                      // Vehicle list or empty filtered state
                      Expanded(
                        child: vehicles.isEmpty
                            ? NoSearchResultsEmptyWidget()
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: vehicles.length,
                                itemBuilder: (context, index) {
                                  final vehicle = vehicles[index];
                                  final isCurrent =
                                      vehicle.id == currentVehicleId;

                                  return BlocBuilder<
                                    VehicleDeleteCubit,
                                    VehicleDeleteState
                                  >(
                                    builder: (context, state) {
                                      return VehicleCard(
                                        vehicle: vehicle,
                                        isCurrent: isCurrent,
                                        onTap: state.maybeWhen(
                                          orElse: () {
                                            return () => _goToEditVehicle(
                                              context,
                                              vehicle,
                                            );
                                          },
                                          success: (deletedId) {
                                            if (deletedId == vehicle.id) {
                                              return null;
                                            }

                                            return () => _goToEditVehicle(
                                              context,
                                              vehicle,
                                            );
                                          },
                                          loading: () {
                                            return null;
                                          },
                                        ),
                                        onSetAsCurrent: !vehicle.isArchived
                                            ? () {
                                                context
                                                    .read<VehicleCubit>()
                                                    .setMainVehicle(
                                                      vehicle.id!,
                                                    );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      '${vehicle.name} ${VehicleStrings.vehicleSetAsMain}',
                                                    ),
                                                    backgroundColor:
                                                        const Color(0xFF10B981),
                                                  ),
                                                );
                                              }
                                            : null,
                                        onAddMaintenance: !vehicle.isArchived
                                            ? () => _goToCreateMaintenance(
                                                context,
                                                vehicle,
                                              )
                                            : null,
                                        onArchive: !vehicle.isArchived
                                            ? () {
                                                context
                                                    .read<VehicleListCubit>()
                                                    .archiveVehicle(vehicle);
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      '${vehicle.name} ${VehicleStrings.vehicleArchived}',
                                                    ),
                                                    backgroundColor:
                                                        const Color(0xFF6366F1),
                                                  ),
                                                );
                                              }
                                            : null,
                                        onUnarchive: vehicle.isArchived
                                            ? () {
                                                context
                                                    .read<VehicleListCubit>()
                                                    .unarchiveVehicle(vehicle);
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      '${vehicle.name} ${VehicleStrings.vehicleUnarchived}',
                                                    ),
                                                    backgroundColor:
                                                        const Color(0xFF10B981),
                                                  ),
                                                );
                                              }
                                            : null,
                                        onDelete: () {
                                          _showDeleteDialog(context, vehicle);
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
