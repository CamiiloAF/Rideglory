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
import '../widgets/vehicle_edit_body.dart';

/// Ficha completa de una moto: foto, ficha técnica, principal, documentos
/// y eliminar.
///
/// Pencil: tbZKM (no incluye la fila de documentos ni archivar/restaurar en
/// el frame aprobado — ver informe de cierre para el detalle de la
/// desviación).
class VehicleEditPage extends StatelessWidget {
  const VehicleEditPage({required this.vehicle, super.key});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<VehicleFormCubit>()..startEditing(vehicle),
      child: BlocListener<VehicleFormCubit, VehicleFormState>(
        listenWhen: (previous, current) =>
            previous.submission != current.submission,
        listener: (context, state) {
          if (state.submission is Data<Vehicle>) context.pop(true);
        },
        child: Scaffold(
          appBar: AppPageHeader(title: context.l10n.garage_edit_vehicle_title),
          body: SafeArea(child: VehicleEditBody(vehicle: vehicle)),
        ),
      ),
    );
  }
}
