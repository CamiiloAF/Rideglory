import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import 'cubit/sos_cubit.dart';
import 'live_ride_route_args.dart';
import 'widgets/sos_confirm_sheet.dart';

/// LV3 → LV4: abre la hoja de confirmar SOS y, si se completa el pulsado
/// de 1,5 s, dispara `SosCubit.raise()` (D16: encolado local antes de la
/// red) y navega a la pantalla de SOS activo, sin esperar la confirmación
/// del servidor — LV4a/LV4b ya distinguen pendiente de confirmado.
Future<void> triggerLiveRideSosFlow(
  BuildContext context, {
  required String eventId,
  required LiveRideRouteArgs args,
}) async {
  final sosCubit = context.read<SosCubit>();
  await SosConfirmSheet.show(
    context,
    onConfirmed: () {
      unawaited(sosCubit.raise());
    },
  );
  if (!context.mounted) return;
  await context.pushNamed(
    AppRoutes.eventLiveSos,
    pathParameters: {'id': eventId},
    extra: args,
  );
}
