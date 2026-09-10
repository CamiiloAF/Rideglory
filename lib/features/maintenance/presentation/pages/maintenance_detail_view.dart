import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/domain/result_state.dart';
import '../../../../core/utils/spanish_date_format.dart';
import '../../../../design_system/components/app_banner.dart';
import '../../../../design_system/components/app_page_header.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../../shared/widgets/states/error_state_view.dart';
import '../../../../shared/widgets/states/skeleton_list.dart';
import '../../domain/maintenance_reminder.dart';
import '../cubit/maintenance_detail_cubit.dart';
import '../cubit/maintenance_detail_state.dart';
import '../maintenance_routes.dart';
import '../widgets/maintenance_actions_sheet.dart';
import '../widgets/maintenance_delete_confirm_sheet.dart';
import '../widgets/maintenance_interval_sheet.dart';
import 'maintenance_detail_content.dart';

/// Cuerpo del detalle: encabezado con acciones y el contenido según el
/// estado del historial completo (para derivar "anteriores").
class MaintenanceDetailView extends StatelessWidget {
  const MaintenanceDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MaintenanceDetailCubit>();

    return BlocListener<MaintenanceDetailCubit, MaintenanceDetailState>(
      listenWhen: (previous, current) => previous.deletion != current.deletion,
      listener: (context, state) {
        final deleted = state.deletion.maybeWhen(
          data: (_) => true,
          orElse: () => false,
        );
        if (deleted) Navigator.of(context).pop(true);
      },
      child: BlocBuilder<MaintenanceDetailCubit, MaintenanceDetailState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppPageHeader(
              title: state.maintenance.type,
              actionIcon: LucideIcons.moreVertical,
              onAction: () => _openActions(context, cubit),
            ),
            body: Column(
              children: [
                if (state.deletion is Error<Unit>)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: AppBanner(
                      title: context.l10n.maintenance_delete_error_title,
                      body: context.l10n.maintenance_delete_error_body,
                    ),
                  ),
                Expanded(
                  child: state.allMaintenances.when(
                    initial: () => const SkeletonList(),
                    loading: () => const SkeletonList(),
                    error: (error) => ErrorStateView(
                      onRetry: () => cubit.start(state.maintenance),
                    ),
                    empty: () => MaintenanceDetailContent(
                      state: state,
                      onTogglePrevious: cubit.toggleShowAllPrevious,
                      onEditReminder: () =>
                          _openIntervalSheet(context, cubit, state),
                    ),
                    data: (_) => MaintenanceDetailContent(
                      state: state,
                      onTogglePrevious: cubit.toggleShowAllPrevious,
                      onEditReminder: () =>
                          _openIntervalSheet(context, cubit, state),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openActions(BuildContext context, MaintenanceDetailCubit cubit) {
    final maintenance = cubit.state.maintenance;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => MaintenanceActionsSheet(
        maintenance: maintenance,
        onEdit: () async {
          Navigator.of(sheetContext).pop();
          final vehicle = cubit.state.vehicle;
          if (vehicle == null) return;
          final saved = await context.pushNamed<bool>(
            MaintenanceRoutes.register,
            extra: RegisterMaintenanceArgs(
              vehicle: vehicle,
              existing: maintenance,
            ),
          );
          if (saved == true && context.mounted) Navigator.of(context).pop(true);
        },
        onDelete: () {
          Navigator.of(sheetContext).pop();
          _openDeleteConfirm(context, cubit);
        },
      ),
    );
  }

  void _openDeleteConfirm(BuildContext context, MaintenanceDetailCubit cubit) {
    final l10n = context.l10n;
    final maintenance = cubit.state.maintenance;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => MaintenanceDeleteConfirmSheet(
        body: l10n.maintenance_delete_confirm_body(
          maintenance.type,
          SpanishDateFormat.short(maintenance.serviceDate),
        ),
        onConfirm: () {
          Navigator.of(sheetContext).pop();
          cubit.delete();
        },
      ),
    );
  }

  void _openIntervalSheet(
    BuildContext context,
    MaintenanceDetailCubit cubit,
    MaintenanceDetailState state,
  ) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => MaintenanceIntervalSheet(
        subtitle: l10n.maintenance_interval_sheet_subtitle(
          state.maintenance.type,
          state.maintenance.vehicleDisplayName,
        ),
        initial: MaintenanceReminder(
          everyKm: state.maintenance.nextOdometer == null
              ? null
              : state.maintenance.nextOdometer! - state.maintenance.odometer,
          everyMonths: null,
        ),
        onSave: cubit.updateReminder,
      ),
    );
  }
}
