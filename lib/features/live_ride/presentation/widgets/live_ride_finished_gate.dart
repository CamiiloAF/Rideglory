import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../cubit/sos_cubit.dart';
import '../cubit/sos_state.dart';
import '../cubit/sos_send_state.dart';
import 'live_ride_finished_view.dart';
import 'live_ride_finished_with_sos_view.dart';
import 'sos_close_confirm_dialog.dart';

/// LV7: decide entre la vista simple y la vista con SOS abierto según
/// `SosCubit.state.mine` — un SOS propio pendiente o confirmado sigue
/// visible aunque la rodada haya terminado (D19).
class LiveRideFinishedGate extends StatelessWidget {
  const LiveRideFinishedGate({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<SosCubit, SosState>(
          builder: (context, sosState) {
            final mine = sosState.mine;
            if (mine is SosSendPending || mine is SosSendConfirmed) {
              final lat = mine is SosSendConfirmed
                  ? mine.alert.lat
                  : (mine as SosSendPending).item.position.lat;
              final lng = mine is SosSendConfirmed
                  ? mine.alert.lng
                  : (mine as SosSendPending).item.position.lng;
              final accuracy = mine is SosSendConfirmed
                  ? mine.alert.accuracyM
                  : (mine as SosSendPending).item.position.accuracyM;
              return LiveRideFinishedWithSosView(
                lat: lat,
                lng: lng,
                accuracyM: accuracy,
                onCloseSos: () => _closeSos(context),
                onBackToEvent: () => _backToEvent(context),
              );
            }
            return LiveRideFinishedView(
              onBackToEvent: () => _backToEvent(context),
            );
          },
        ),
      ),
    );
  }

  Future<void> _closeSos(BuildContext context) async {
    final confirmed = await SosCloseConfirmDialog.show(context);
    if (!confirmed || !context.mounted) return;
    await context.read<SosCubit>().closeMine();
  }

  void _backToEvent(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.pushReplacementNamed(
        AppRoutes.eventDetail,
        pathParameters: {'id': eventId},
      );
    }
  }
}
