import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/domain/result_state.dart';
import '../../../../design_system/components/app_page_header.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/models/vehicle.dart';
import '../cubit/vehicle_form_cubit.dart';
import '../cubit/vehicle_form_state.dart';
import '../widgets/vehicle_form_details_step.dart';
import '../widgets/vehicle_form_plate_step.dart';

/// Alta y edición de una moto en dos pasos: primero la placa (A2), luego
/// la ficha completa.
///
/// Pencil: KIdCH, ruRle, e0fmR, M2i66X, sH7QQ (alta) · tbZKM (edición)
class VehicleFormPage extends StatelessWidget {
  const VehicleFormPage({this.editingVehicle, super.key});

  final Vehicle? editingVehicle;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<VehicleFormCubit>();
        final vehicle = editingVehicle;
        if (vehicle != null) cubit.startEditing(vehicle);
        return cubit;
      },
      child: BlocListener<VehicleFormCubit, VehicleFormState>(
        listenWhen: (previous, current) => previous.submission != current.submission,
        listener: (context, state) {
          if (state.submission is Data<Vehicle>) {
            context.pop(true);
          }
        },
        child: Scaffold(
          appBar: AppPageHeader(
            title: editingVehicle == null
                ? context.l10n.garage_add_vehicle_title
                : context.l10n.garage_edit_vehicle_title,
          ),
          body: SafeArea(
            child: BlocBuilder<VehicleFormCubit, VehicleFormState>(
              buildWhen: (previous, current) => previous.step != current.step,
              builder: (context, state) {
                return state.step == VehicleFormStep.plate
                    ? const VehicleFormPlateStep()
                    : const VehicleFormDetailsStep();
              },
            ),
          ),
        ),
      ),
    );
  }
}
