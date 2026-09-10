import 'package:flutter/widgets.dart';

import '../../domain/event_registrant.dart';
import 'event_registrant_tile.dart';

class EventRegistrantsList extends StatelessWidget {
  const EventRegistrantsList({required this.registrants, super.key});

  final List<EventRegistrant> registrants;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: registrants.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          EventRegistrantTile(registrant: registrants[index]),
    );
  }
}
