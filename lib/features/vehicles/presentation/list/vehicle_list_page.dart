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
import 'package:rideglory/shared/widgets/modals/app_dialog.dart';
import 'package:rideglory/shared/widgets/modals/confirmation_dialog.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_strings.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/shared/widgets/modals/dialog_type.dart';

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
    final result = await context.pushNamed(
      AppRoutes.editVehicle,
      extra: vehicle,
    );
    if (result == true && context.mounted) {
      _loadVechicles(context);
    }
  }

  Future<void> _loadVechicles(BuildContext context) =>
      context.read<VehicleListCubit>().loadVehicles();

  Future<void> _goToCreateVehicle(BuildContext context) async {
    final result = await context.pushNamed(AppRoutes.createVehicle);
    if (result == true && context.mounted) {
      _loadVechicles(context);
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppAppBar(
        title: context.watch<VehicleListCubit>().showArchivedVehicles
            ? VehicleStrings.archivedVehicle
            : VehicleStrings.myVehicles,
        actions: [
          IconButton(
            icon: Icon(
              context.watch<VehicleListCubit>().showArchivedVehicles
                  ? Icons.inventory_2
                  : Icons.inventory_2_outlined,
            ),
            onPressed: () {
              context.read<VehicleListCubit>().toggleShowArchived();
            },
            tooltip: context.watch<VehicleListCubit>().showArchivedVehicles
                ? VehicleStrings.showActiveVehicles
                : VehicleStrings.viewArchived,
          ),
          if (!context.watch<VehicleListCubit>().showArchivedVehicles) ...[
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
                final showingArchived = context
                    .watch<VehicleListCubit>()
                    .showArchivedVehicles;
                return EmptyStateWidget(
                  icon: showingArchived
                      ? Icons.inventory_2_outlined
                      : Icons.directions_car_outlined,
                  title: showingArchived
                      ? VehicleStrings.archivedVehicleMessage
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
                  iconColor: const Color(0xFF6366F1),
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
                  child: Column(
                    children: [
                      // Search bar
                      if (!context
                          .watch<VehicleListCubit>()
                          .showArchivedVehicles)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: VehicleStrings.searchVehicles,
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            onChanged: (value) {
                              context
                                  .read<VehicleListCubit>()
                                  .updateSearchQuery(value);
                            },
                          ),
                        ),
                      // Vehicle list or empty filtered state
                      Expanded(
                        child: vehicles.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off_rounded,
                                        size: 80,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        AppStrings.noResults,
                                        style: context.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        context
                                                .watch<VehicleListCubit>()
                                                .showArchivedVehicles
                                            ? VehicleStrings
                                                  .archivedVehicleMessage
                                            : VehicleStrings.adjustSearch,
                                        style: context.bodyMedium,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: vehicles.length,
                                itemBuilder: (context, index) {
                                  final vehicle = vehicles[index];
                                  final isCurrent =
                                      vehicle.id == currentVehicleId;

                                  return VehicleCard(
                                    vehicle: vehicle,
                                    isCurrent: isCurrent,
                                    onTap: () async {
                                      // Navigate to edit vehicle
                                      if (vehicle.id != null) {
                                        await _goToEditVehicle(
                                          context,
                                          vehicle,
                                        );
                                      }
                                    },
                                    onSetAsCurrent: !vehicle.isArchived
                                        ? () {
                                            context
                                                .read<VehicleCubit>()
                                                .setMainVehicle(vehicle.id!);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '${vehicle.name} ${VehicleStrings.vehicleSetAsMain}',
                                                ),
                                                backgroundColor: const Color(
                                                  0xFF10B981,
                                                ),
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
                                                backgroundColor: const Color(
                                                  0xFF6366F1,
                                                ),
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
                                                backgroundColor: const Color(
                                                  0xFF10B981,
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                    onDelete: () {
                                      _showDeleteDialog(context, vehicle);
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
