import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_card.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/states/page_error_state_widget.dart';
import 'package:rideglory/shared/widgets/states/page_loading_state_widget.dart';

class MyDraftsView extends StatelessWidget {
  const MyDraftsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppAppBar(title: context.l10n.draft_myDraftsTitle),
      body: BlocBuilder<EventsCubit, ResultState<List<EventModel>>>(
        builder: (context, state) {
          return state.when(
            initial: () => const PageLoadingStateWidget(),
            loading: () => const PageLoadingStateWidget(),
            empty: () => EmptyStateWidget(
              icon: Icons.edit_note_rounded,
              title: context.l10n.draft_noDrafts,
              description: context.l10n.draft_noDraftsHint,
            ),
            data: (events) {
              final drafts = events
                  .where((event) => event.state == EventState.draft)
                  .toList();

              if (drafts.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.edit_note_rounded,
                  title: context.l10n.draft_noDrafts,
                  description: context.l10n.draft_noDraftsHint,
                );
              }

              final currentUserId = context
                  .watch<AuthCubit>()
                  .state
                  .currentUser
                  ?.id;

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: drafts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (_, i) {
                  final event = drafts[i];
                  final isOwner = event.ownerId == currentUserId;
                  return EventCard(
                    key: event.id != null
                        ? ValueKey(event.id)
                        : ObjectKey(event),
                    event: event,
                    isOwner: isOwner,
                    onTap: () => _navigateToDetail(context, event),
                  );
                },
              );
            },
            error: (error) => PageErrorStateWidget(
              title: context.l10n.event_errorLoadingEvents,
              message: error.message,
              onRetry: () => context.read<EventsCubit>().fetchEvents(),
            ),
          );
        },
      ),
    );
  }

  Future<void> _navigateToDetail(BuildContext context, EventModel event) async {
    final result = await context.pushNamed<dynamic>(
      AppRoutes.eventDetail,
      extra: event,
    );
    if (context.mounted) {
      if (result is EventModel) {
        context.read<EventsCubit>().updateEvent(result);
      } else if (result == true && event.id != null) {
        context.read<EventsCubit>().removeEvent(event.id!);
      }
    }
  }
}
