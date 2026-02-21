import 'package:flutter/material.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:url_launcher/url_launcher.dart';

class EventMapsButton extends StatelessWidget {
  final String url;

  const EventMapsButton({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.map_outlined),
      tooltip: EventStrings.openInMaps,
      onPressed: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}
