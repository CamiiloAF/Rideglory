import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../domain/maintenance.dart';
import '../cubit/maintenance_detail_cubit.dart';
import 'maintenance_detail_view.dart';

/// Detalle de un mantenimiento (Pencil `b8WMj1`). Recibe el registro por
/// `extra` de `go_router`: la pantalla principal ya lo tiene cargado, no
/// hace falta una segunda consulta para mostrarlo.
class MaintenanceDetailPage extends StatelessWidget {
  const MaintenanceDetailPage({required this.maintenance, super.key});

  final Maintenance maintenance;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MaintenanceDetailCubit>()..start(maintenance),
      child: const MaintenanceDetailView(),
    );
  }
}
