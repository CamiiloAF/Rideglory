import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/screens/event_route_config_screen.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/locations/custom_route_summary_card.dart';

class CustomRouteSection extends StatelessWidget {
  const CustomRouteSection({super.key, required this.state});

  final EventFormState state;

  @override
  Widget build(BuildContext context) {
    final hasWaypoints = state.waypoints.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppButton(
          label: context.l10n.route_builder_title,
          style: AppButtonStyle.outlined,
          icon: Icons.route_outlined,
          onPressed: () => _openRouteConfig(context),
        ),
        if (hasWaypoints) ...[
          const SizedBox(height: 16),
          CustomRouteSummaryCard(state: state),
        ],
      ],
    );
  }

  void _openRouteConfig(BuildContext context) {
    final cubit = context.read<EventFormCubit>();
    Navigator.of(context).push(
      // Custom: EventRouteConfigScreen has no go_router named route — anonymous push preserved. Reason: ephemeral sub-screen, no deep-link requirement.
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const EventRouteConfigScreen(),
        ),
      ),
    );
  }
}
