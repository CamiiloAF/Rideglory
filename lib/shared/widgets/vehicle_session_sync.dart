import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';

/// Mantiene [VehicleCubit] sincronizado con el ciclo de vida de la sesión.
///
/// [VehicleCubit] y [AuthCubit] son instancias únicas provistas en la raíz
/// (`main.dart`), vivas durante todo el proceso. Sin este listener, cerrar
/// sesión y entrar con otra cuenta (o registrar una nueva) sin reiniciar la
/// app deja el estado de vehículos del usuario anterior en el cubit: el
/// guard `if (state is Initial)` de `MainShell` nunca vuelve a disparar el
/// fetch, y Home no refleja la realidad de la nueva sesión hasta visitar el
/// tab de Garaje (que sí refetchea sin guard).
class VehicleSessionSync extends StatelessWidget {
  const VehicleSessionSync({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          current.isAuthenticated || current.isUnauthenticated,
      listener: (context, state) {
        final vehicleCubit = context.read<VehicleCubit>();
        if (state.isAuthenticated) {
          vehicleCubit.fetchMyVehicles();
        } else if (state.isUnauthenticated) {
          vehicleCubit.clearVehicles();
        }
      },
      child: child,
    );
  }
}
