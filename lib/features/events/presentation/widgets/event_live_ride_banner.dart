import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../design_system/components/app_banner.dart';
import '../../../../design_system/components/app_secondary_button.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../live_ride/presentation/cubit/sos_cubit.dart';
import '../../../live_ride/presentation/cubit/sos_state.dart';
import '../../../live_ride/presentation/cubit/sos_send_state.dart';
import '../../../live_ride/presentation/live_ride_route_args.dart';
import '../../domain/event.dart';

/// EV2: cuando la rodada está `started` y quien mira es organizador o
/// inscrito aprobado, CTA principal a LV1. Si ya tiene un SOS propio
/// pendiente o confirmado (D19: solo lo cierra él o el organizador), un
/// banner encima lleva directo a la pantalla de SOS en vez de perderlo en
/// el mapa.
class EventLiveRideBanner extends StatefulWidget {
  const EventLiveRideBanner({required this.event, super.key});

  final Event event;

  @override
  State<EventLiveRideBanner> createState() => _EventLiveRideBannerState();
}

class _EventLiveRideBannerState extends State<EventLiveRideBanner> {
  LiveRideRouteArgs get _routeArgs => LiveRideRouteArgs(
    eventName: widget.event.name,
    isOwner: widget.event.isOwnedByMe,
    ownerId: widget.event.ownerId,
  );

  @override
  void initState() {
    super.initState();
    context.read<SosCubit>().load(widget.event.id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SosCubit, SosState>(
      builder: (context, state) {
        final hasOwnSos =
            state.mine is SosSendPending || state.mine is SosSendConfirmed;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasOwnSos) ...[
                GestureDetector(
                  onTap: () => context.pushNamed(
                    AppRoutes.eventLiveSos,
                    pathParameters: {'id': widget.event.id},
                    extra: _routeArgs,
                  ),
                  child: AppBanner(
                    icon: LucideIcons.siren,
                    title: context.l10n.live_ride_own_sos_banner,
                    body: '',
                  ),
                ),
                const SizedBox(height: 10),
              ],
              AppSecondaryButton(
                label: context.l10n.live_ride_view_live_cta,
                icon: LucideIcons.radio,
                onPressed: () => context.pushNamed(
                  AppRoutes.eventLive,
                  pathParameters: {'id': widget.event.id},
                  extra: _routeArgs,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
