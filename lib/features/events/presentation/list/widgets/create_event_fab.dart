import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class CreateEventFab extends StatelessWidget {
  const CreateEventFab({super.key, required this.showMyEvents});

  final bool showMyEvents;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await context.pushNamed<EventModel?>(
          AppRoutes.createEvent,
        );
        if (result != null && context.mounted) {
          context.read<EventsCubit>().addEvent(result);
        }
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.add, color: AppColors.darkBgPrimary, size: 18)],
        ),
      ),
    );
  }
}
