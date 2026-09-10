import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../design_system/components/app_fab.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../../shared/cubits/connectivity/connectivity_cubit.dart';
import '../../../../shared/cubits/connectivity/connectivity_state.dart';
import '../../../../shared/widgets/states/empty_state_view.dart';
import '../../../../shared/widgets/states/error_state_view.dart';
import '../../../../shared/widgets/states/offline_state_view.dart';
import '../../../../shared/widgets/states/skeleton_list.dart';
import '../../domain/maintenance.dart';
import '../cubit/maintenance_cubit.dart';
import '../cubit/maintenance_state.dart';
import '../maintenance_routes.dart';
import '../widgets/maintenance_header.dart';
import '../widgets/maintenance_status_filter_sheet.dart';
import 'maintenance_content.dart';

/// Cuerpo de la pantalla principal: resuelve entre los estados
/// obligatorios (carga, vacío, error, sin conexión) y el contenido.
class MaintenanceView extends StatelessWidget {
  const MaintenanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MaintenanceCubit>();
    final isOffline =
        context.watch<ConnectivityCubit>().state is ConnectivityOffline;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            MaintenanceHeader(
              onFilterTap: () => _openStatusFilter(context, cubit),
            ),
            Expanded(
              child: BlocBuilder<MaintenanceCubit, MaintenanceState>(
                builder: (context, state) {
                  if (isOffline && (state.isLoading || state.hasError)) {
                    return OfflineStateView(
                      title: context.l10n.common_offline_title,
                      message: context.l10n.maintenance_offline_body,
                      onRetry: cubit.load,
                    );
                  }
                  if (state.isLoading) {
                    return const SkeletonList();
                  }
                  if (state.hasError) {
                    return ErrorStateView(
                      title: context.l10n.maintenance_error_title,
                      onRetry: cubit.load,
                    );
                  }
                  if (state.hasNoVehicles) {
                    return EmptyStateView(
                      icon: Icons.two_wheeler_outlined,
                      title: context.l10n.maintenance_no_vehicles_title,
                      body: context.l10n.maintenance_no_vehicles_body,
                      actionLabel: context.l10n.maintenance_no_vehicles_action,
                      onAction: () => context.pushNamed(AppRoutes.vehicleAdd),
                    );
                  }
                  if (state.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.build_outlined,
                      title: context.l10n.maintenance_empty_title,
                      body: context.l10n.maintenance_empty_body,
                      actionLabel: context.l10n.maintenance_empty_action,
                      onAction: () => _openRegister(context, state),
                    );
                  }
                  return MaintenanceContent(
                    state: state,
                    onVehicleSelected: cubit.selectVehicle,
                    onAgendaItemTap: (id) =>
                        _openDetailById(context, state, id),
                    onHistoryEntryTap: (maintenance) =>
                        _openDetail(context, maintenance),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: BlocBuilder<MaintenanceCubit, MaintenanceState>(
        buildWhen: (previous, current) =>
            previous.vehicleList != current.vehicleList,
        builder: (context, state) {
          if (state.vehicleList.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 76),
            child: Semantics(
              button: true,
              label: context.l10n.maintenance_fab_label,
              child: AppFab(onPressed: () => _openRegister(context, state)),
            ),
          );
        },
      ),
    );
  }

  void _openStatusFilter(BuildContext context, MaintenanceCubit cubit) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) =>
          BlocBuilder<MaintenanceCubit, MaintenanceState>(
            bloc: cubit,
            builder: (context, state) => MaintenanceStatusFilterSheet(
              selected: state.statusFilter,
              onSelected: (status) {
                cubit.filterByStatus(status);
                Navigator.of(sheetContext).pop();
              },
            ),
          ),
    );
  }

  Future<void> _openRegister(
    BuildContext context,
    MaintenanceState state,
  ) async {
    final selected = state.vehicleList
        .where((option) => option.id == state.selectedVehicleId)
        .toList();
    final main = state.vehicleList.where((option) => option.isMain).toList();
    final vehicle = selected.isNotEmpty
        ? selected.first
        : main.isNotEmpty
        ? main.first
        : (state.vehicleList.isNotEmpty ? state.vehicleList.first : null);
    if (vehicle == null) return;
    final cubit = context.read<MaintenanceCubit>();
    final saved = await context.pushNamed<bool>(
      MaintenanceRoutes.register,
      extra: RegisterMaintenanceArgs(vehicle: vehicle),
    );
    if (saved == true) cubit.load();
  }

  void _openDetailById(
    BuildContext context,
    MaintenanceState state,
    String id,
  ) {
    final matches = state.maintenanceList
        .where((item) => item.id == id)
        .toList();
    if (matches.isEmpty) return;
    _openDetail(context, matches.first);
  }

  Future<void> _openDetail(
    BuildContext context,
    Maintenance maintenance,
  ) async {
    final cubit = context.read<MaintenanceCubit>();
    final changed = await context.pushNamed<bool>(
      MaintenanceRoutes.detail,
      extra: maintenance,
    );
    if (changed == true) cubit.load();
  }
}
