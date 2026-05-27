import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/delete/cubit/maintenance_delete_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/detail/widgets/maintenance_detail_view.dart';

class MaintenanceDetailPage extends StatelessWidget {
  const MaintenanceDetailPage({super.key, required this.maintenance});

  final MaintenanceModel maintenance;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<MaintenanceDeleteCubit>(),
      child: MaintenanceDetailView(maintenance: maintenance),
    );
  }
}
