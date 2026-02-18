import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/maintenance/presentation/form/cubit/maintenance_form_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/maintenance_form_content.dart';
import 'package:rideglory/shared/widgets/app_app_bar.dart';

class MaintenanceFormView extends StatefulWidget {
  const MaintenanceFormView({super.key});

  @override
  State<MaintenanceFormView> createState() => _MaintenanceFormViewState();
}

class _MaintenanceFormViewState extends State<MaintenanceFormView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: 'Mantenimiento'),
      body: BlocListener<MaintenanceFormCubit, MaintenanceFormState>(
        listener: (context, state) {
          state.whenOrNull(
            success: (maintenance) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mantenimiento guardado exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop(true);
            },
            error: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: \$message'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          );
        },
        child: const MaintenanceFormContent(),
      ),
    );
  }
}
