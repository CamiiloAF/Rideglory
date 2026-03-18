import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
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
          padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            context.l10n.home_upcomingRides,
            style: TextStyle(
              color: context.colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        events.isEmpty
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: HomeEmptyEventsCard(),
              )
            : SizedBox(
                height: 260,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: events.length,
                  separatorBuilder: (_, _) => AppSpacing.hGapMd,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return HomeEventCard(
                      event: event,
                      onTap: () => context.pushNamed(
                        AppRoutes.eventDetail,
                        extra: event,
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }
}
