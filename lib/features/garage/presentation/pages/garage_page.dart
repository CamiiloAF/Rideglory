import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../shared/cubits/connectivity/connectivity_cubit.dart';
import '../../../../shared/cubits/connectivity/connectivity_state.dart';
import '../../../../shared/widgets/states/offline_state_view.dart';
import '../cubit/garage_gallery_cubit.dart';
import '../widgets/garage_gallery_view.dart';

/// Punto de entrada de la pestaña Garaje (D4: Mantenimiento es la de
/// entrada; esta es la tercera del Pill Tab Bar).
///
/// Pencil: V02g9 (galería), rgLwm (vacío), pBdbp (carga), ZSUKH (sin
/// conexión).
class GaragePage extends StatelessWidget {
  const GaragePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isOffline =
        context.watch<ConnectivityCubit>().state is ConnectivityOffline;
    return BlocProvider(
      create: (_) => getIt<GarageGalleryCubit>()..load(),
      child: Scaffold(
        body: SafeArea(
          child: isOffline
              ? OfflineStateView(
                  onRetry: () => context.read<GarageGalleryCubit>().load(),
                )
              : const GarageGalleryView(),
        ),
      ),
    );
  }
}
