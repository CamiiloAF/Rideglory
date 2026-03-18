import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/tracking/constants/map_strings.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

class ParticipantsPlaceholderPage extends StatelessWidget {
  const ParticipantsPlaceholderPage({
    super.key,
    required this.event,
  });

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: context.colorScheme.surface,
        foregroundColor: context.colorScheme.onSurface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: const Text(MapStrings.participantsList),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            MapStrings.participantsPlaceholder,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

