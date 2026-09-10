import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/sos_cubit.dart';
import '../cubit/sos_state.dart';
import '../cubit/sos_send_state.dart';
import '../live_ride_route_args.dart';
import '../widgets/sos_active_content.dart';
import '../widgets/sos_active_header.dart';
import '../widgets/sos_close_confirm_dialog.dart';
import '../widgets/sos_closed_view.dart';

/// LV4a/LV4b: SOS propio pendiente o confirmado. **Nunca dice "enviado"
/// hasta que el servidor confirma** — `pending` muestra explícitamente
/// que no salió y que se reintentará (regla de seguridad del rider).
///
/// Pencil: bAklu (pendiente) / KVhKk (confirmado)
class SosActiveView extends StatelessWidget {
  const SosActiveView({required this.eventId, required this.args, super.key});

  final String eventId;
  final LiveRideRouteArgs args;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      appBar: SosActiveHeader(onBack: () => _backToLiveRide(context)),
      body: SafeArea(
        top: false,
        child: BlocBuilder<SosCubit, SosState>(
          builder: (context, sosState) {
            final mine = sosState.mine;
            if (mine is SosSendConfirmed || mine is SosSendClosing) {
              final alert = mine is SosSendConfirmed
                  ? mine.alert
                  : (mine as SosSendClosing).alert;
              return SosActiveContent(
                isConfirmed: true,
                lat: alert.lat,
                lng: alert.lng,
                accuracyM: alert.accuracyM,
                isBusy: mine is SosSendClosing,
                onClose: () => _closeSos(context),
              );
            }
            if (mine is SosSendPending) {
              final position = mine.item.position;
              return SosActiveContent(
                isConfirmed: false,
                lat: position.lat,
                lng: position.lng,
                accuracyM: position.accuracyM,
                isBusy: false,
                onClose: () => _closeSos(context),
              );
            }
            if (mine is SosSendClosed) {
              return const SosClosedView();
            }
            return Center(
              child: Text(
                context.l10n.sos_sending_title,
                style: TextStyle(color: colors.textSecondary),
              ),
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

  void _backToLiveRide(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.pushReplacementNamed(
        AppRoutes.eventLive,
        pathParameters: {'id': eventId},
        extra: args,
      );
    }
  }
}
