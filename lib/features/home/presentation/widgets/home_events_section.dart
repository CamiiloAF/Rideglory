import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/home/presentation/cubit/home_cubit.dart';
import 'package:rideglory/features/home/presentation/widgets/home_empty_events_card.dart';
import 'package:rideglory/features/home/presentation/widgets/home_event_card.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class HomeEventsSection extends StatelessWidget {
  const HomeEventsSection({super.key, required this.events});

  final List<EventModel> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.home_sectionEvents.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textOnDarkSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const Icon(
                Icons.tune,
                color: AppColors.textOnDarkSecondary,
                size: 20,
              ),
            ],
          ),
        ),
        events.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: HomeEmptyEventsCard(),
              )
            : SizedBox(
                height: 340,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: events.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return HomeEventCard(
                      event: event,
                      onTap: () async {
                        final result = await context.pushNamed<dynamic>(
                          AppRoutes.eventDetail,
                          extra: event,
                        );
                        if (!context.mounted) return;
                        if (result is EventModel) {
                          context.read<HomeCubit>().updateEvent(result);
                        } else if (result == true && event.id != null) {
                          context.read<HomeCubit>().removeEvent(event.id!);
                        }
                      },
                    );
                  },
                ),
              ),
      ],
    );
  }
}
