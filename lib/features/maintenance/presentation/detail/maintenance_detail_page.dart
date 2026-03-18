import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/delete/cubit/maintenance_delete_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/detail/widgets/maintenance_options_bottom_sheet.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/app_app_bar.dart';
import 'package:rideglory/shared/widgets/modals/confirmation_dialog.dart';
import 'package:rideglory/shared/widgets/modals/app_dialog.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_strings.dart';
import 'package:rideglory/features/maintenance/presentation/detail/widgets/maintenance_info_tile.dart';
import 'package:rideglory/features/maintenance/presentation/detail/widgets/maintenance_section_header.dart';
import 'package:rideglory/features/maintenance/presentation/detail/widgets/maintenance_alert_card.dart';
import 'package:rideglory/features/maintenance/presentation/detail/widgets/maintenance_detail_header.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';

class MaintenanceDetailPage extends StatelessWidget {
  const MaintenanceDetailPage({super.key, required this.maintenance});

  final MaintenanceModel maintenance;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<MaintenanceDeleteCubit>(),
      child: _MaintenanceDetailView(maintenance: maintenance),
    );
  }
}

class _MaintenanceDetailView extends StatefulWidget {
  const _MaintenanceDetailView({required this.maintenance});

  final MaintenanceModel maintenance;

  @override
  State<_MaintenanceDetailView> createState() => _MaintenanceDetailViewState();
}

class _MaintenanceDetailViewState extends State<_MaintenanceDetailView> {
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
      final result = await context.pushNamed<MaintenanceModel?>(
        AppRoutes.editMaintenance,
        extra: _maintenance,
      );
      if (result != null && mounted) {
        setState(() {
          _maintenance = result;
          _wasUpdated = true;
        });
      }
    } else if (action == MaintenanceAction.delete && mounted) {
      final confirm = await ConfirmationDialog.show(
        context: context,
        title: MaintenanceStrings.deleteMaintenance,
        content: MaintenanceStrings.deleteMaintenanceMessage,
        confirmLabel: AppStrings.delete,
        confirmType: DialogActionType.danger,
      );
      if (confirm == true && mounted) {
        context.read<MaintenanceDeleteCubit>().deleteMaintenance(
          _maintenance.id!,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    final numberFormat = NumberFormat('#,###');

    return BlocListener<MaintenanceDeleteCubit, MaintenanceDeleteState>(
      listener: (context, state) {
        state.whenOrNull(
          success: (deletedId) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  MaintenanceStrings.maintenanceDeletedSuccessfully,
                ),
                backgroundColor: Colors.green,
              ),
            );
            context.pop({'action': 'deleted', 'deletedId': deletedId});
          },
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppStrings.errorMessage(message)),
                backgroundColor: Colors.red,
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
          backgroundColor: AppColors.darkBackground,
          appBar: AppAppBar(
            title: MaintenanceStrings.maintenanceDetail,
            leading: BackButton(onPressed: _popWithResult),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: _showOptions,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: BlocBuilder<VehicleCubit, VehicleState>(
              builder: (context, vehicleState) {
                VehicleModel? vehicle;
                if (_maintenance.vehicleId != null) {
                  try {
                    vehicle = context.read<VehicleCubit>().availableVehicles
                        .firstWhere(
                          (v) => v.id == _maintenance.vehicleId,
                        );
                  } catch (_) {}
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MaintenanceDetailHeader(
                      maintenance: _maintenance,
                      vehicle: vehicle,
                    ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: MaintenanceInfoTile(
                        label: MaintenanceStrings.mileage,
                        value:
                            '${numberFormat.format(_maintenance.maintanceMileage)} km',
                        icon: Icons.speed,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: MaintenanceInfoTile(
                        label: MaintenanceStrings.totalCost,
                        value: _maintenance.cost != null
                            ? currencyFormat.format(_maintenance.cost)
                            : AppStrings.notAvailable,
                        icon: Icons.attach_money,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_maintenance.notes != null &&
                    _maintenance.notes!.isNotEmpty) ...[
                  const MaintenanceSectionHeader(
                    title: MaintenanceStrings.serviceNotes,
                    icon: Icons.description_outlined,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Text(
                      _maintenance.notes!,
                      style: context.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (_maintenance.nextMaintenanceDate != null ||
                    _maintenance.nextMaintenanceMileage != null) ...[
                  Row(
                    children: [
                      const MaintenanceSectionHeader(
                        title: MaintenanceStrings.nextMaintenance,
                        icon: Icons.event_repeat_outlined,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme.primary
                              .withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          MaintenanceStrings.suggested.toUpperCase(),
                          style: context.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Row(
                      children: [
                        if (_maintenance.nextMaintenanceDate != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  MaintenanceStrings.estimatedDate.toUpperCase(),
                                  style: context.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  DateFormat('dd MMM, yyyy')
                                      .format(_maintenance.nextMaintenanceDate!),
                                  style: context.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_maintenance.nextMaintenanceDate != null &&
                            _maintenance.nextMaintenanceMileage != null)
                          Container(
                            width: 1,
                            height: 48,
                            color: AppColors.darkBorder,
                          ),
                        if (_maintenance.nextMaintenanceMileage != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  MaintenanceStrings.mileage.toUpperCase(),
                                  style: context.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${numberFormat.format(_maintenance.nextMaintenanceMileage)} km',
                                  style: context.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (_maintenance.receiveAlert) ...[
                  const MaintenanceSectionHeader(
                    title: MaintenanceStrings.alertsConfiguration,
                    icon: Icons.notifications_active_outlined,
                  ),
                  const SizedBox(height: 12),
                  if (!_maintenance.receiveMileageAlert &&
                      !_maintenance.receiveDateAlert)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_active,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              MaintenanceStrings.alertsActivatedDesc,
                              style: context.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        if (_maintenance.receiveMileageAlert ||
                            _maintenance.nextMaintenanceMileage != null)
                          Expanded(
                            child: MaintenanceAlertCard(
                              icon: Icons.speed,
                              label: MaintenanceStrings.alertByMileage.toUpperCase(),
                              value: _maintenance.nextMaintenanceMileage != null
                                  ? '${numberFormat.format(_maintenance.nextMaintenanceMileage)} km'
                                  : '-',
                              subtitle: MaintenanceStrings.mileageAlertBefore,
                              isOn: _maintenance.receiveMileageAlert,
                            ),
                          ),
                        if (_maintenance.receiveMileageAlert &&
                            _maintenance.receiveDateAlert)
                          const SizedBox(width: 12),
                        if (_maintenance.receiveDateAlert ||
                            _maintenance.nextMaintenanceDate != null)
                          Expanded(
                            child: MaintenanceAlertCard(
                              icon: Icons.calendar_month_outlined,
                              label: MaintenanceStrings.alertByDate.toUpperCase(),
                              value: _maintenance.nextMaintenanceDate != null
                                  ? DateFormat('dd MMM, yyyy')
                                      .format(_maintenance.nextMaintenanceDate!)
                                  : '-',
                              subtitle: MaintenanceStrings.dateAlertBefore,
                              isOn: _maintenance.receiveDateAlert,
                            ),
                          ),
                      ],
                    ),
                ],
              ],
            );
              },
            ),
          ),
        ),
      ),
    );
  }
}
