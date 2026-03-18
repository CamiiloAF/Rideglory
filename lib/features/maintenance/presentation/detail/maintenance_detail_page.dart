import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/delete/cubit/maintenance_delete_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/detail/widgets/maintenance_options_bottom_sheet.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/features/maintenance/presentation/detail/widgets/maintenance_info_tile.dart';
import 'package:rideglory/features/maintenance/presentation/detail/widgets/maintenance_section_header.dart';
import 'package:rideglory/features/maintenance/presentation/detail/widgets/maintenance_alert_card.dart';
import 'package:rideglory/features/maintenance/presentation/detail/widgets/maintenance_detail_header.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

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
        title: context.l10n.maintenance_deleteMaintenance,
        content: context.l10n.maintenance_deleteMaintenanceMessage,
        confirmLabel: context.l10n.delete,
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
              SnackBar(
                content: Text(
                  context.l10n.maintenance_maintenanceDeletedSuccessfully,
                ),
                backgroundColor: Colors.green,
              ),
            );
            context.pop({'action': 'deleted', 'deletedId': deletedId});
          },
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.errorMessage(message)),
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
            title: context.l10n.maintenance_maintenanceDetail,
            leading: BackButton(onPressed: _popWithResult),
            actions: [
              IconButton(
                icon: Icon(Icons.share_outlined),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.more_vert),
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
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: MaintenanceInfoTile(
                        label: context.l10n.maintenance_mileage,
                        value:
                            '${numberFormat.format(_maintenance.maintanceMileage)} km',
                        icon: Icons.speed,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: MaintenanceInfoTile(
                        label: context.l10n.maintenance_totalCost,
                        value: _maintenance.cost != null
                            ? currencyFormat.format(_maintenance.cost)
                            : context.l10n.notAvailable,
                        icon: Icons.attach_money,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                if (_maintenance.notes != null &&
                    _maintenance.notes!.isNotEmpty) ...[
                  MaintenanceSectionHeader(
                    title: context.l10n.maintenance_serviceNotes,
                    icon: Icons.description_outlined,
                  ),
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.colorScheme.outlineVariant),
                    ),
                    child: Text(
                      _maintenance.notes!,
                      style: context.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                ],
                if (_maintenance.nextMaintenanceDate != null ||
                    _maintenance.nextMaintenanceMileage != null) ...[
                  Row(
                    children: [
                      MaintenanceSectionHeader(
                        title: context.l10n.maintenance_nextMaintenance,
                        icon: Icons.event_repeat_outlined,
                      ),
                      SizedBox(width: 8),
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
                          context.l10n.maintenance_suggested.toUpperCase(),
                          style: context.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        if (_maintenance.nextMaintenanceDate != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.maintenance_estimatedDate.toUpperCase(),
                                  style: context.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                SizedBox(height: 8),
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
                            color: context.colorScheme.outlineVariant,
                          ),
                        if (_maintenance.nextMaintenanceMileage != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.maintenance_mileage.toUpperCase(),
                                  style: context.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                SizedBox(height: 8),
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
                  SizedBox(height: 24),
                ],
                if (_maintenance.receiveAlert) ...[
                  MaintenanceSectionHeader(
                    title: context.l10n.maintenance_alertsConfiguration,
                    icon: Icons.notifications_active_outlined,
                  ),
                  SizedBox(height: 12),
                  if (!_maintenance.receiveMileageAlert &&
                      !_maintenance.receiveDateAlert)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_active,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              context.l10n.maintenance_alertsActivatedDesc,
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
                              label: context.l10n.maintenance_alertByMileage.toUpperCase(),
                              value: _maintenance.nextMaintenanceMileage != null
                                  ? '${numberFormat.format(_maintenance.nextMaintenanceMileage)} km'
                                  : '-',
                              subtitle: context.l10n.maintenance_mileageAlertBefore,
                              isOn: _maintenance.receiveMileageAlert,
                            ),
                          ),
                        if (_maintenance.receiveMileageAlert &&
                            _maintenance.receiveDateAlert)
                          SizedBox(width: 12),
                        if (_maintenance.receiveDateAlert ||
                            _maintenance.nextMaintenanceDate != null)
                          Expanded(
                            child: MaintenanceAlertCard(
                              icon: Icons.calendar_month_outlined,
                              label: context.l10n.maintenance_alertByDate.toUpperCase(),
                              value: _maintenance.nextMaintenanceDate != null
                                  ? DateFormat('dd MMM, yyyy')
                                      .format(_maintenance.nextMaintenanceDate!)
                                  : '-',
                              subtitle: context.l10n.maintenance_dateAlertBefore,
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
