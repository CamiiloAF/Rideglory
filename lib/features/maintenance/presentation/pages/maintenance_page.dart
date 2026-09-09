import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../cubit/maintenance_cubit.dart';
import 'maintenance_view.dart';

/// Pestaña de entrada de la app (D4): agenda e historial de mantenimiento.
class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MaintenanceCubit>()..load(),
      child: const MaintenanceView(),
    );
  }
}
