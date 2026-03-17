import 'package:flutter/material.dart';
import 'package:rideglory/features/event_registration/constants/registration_strings.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_extra.dart';
import 'package:rideglory/shared/widgets/app_app_bar.dart';

class RegistrationDetailPage extends StatelessWidget {
  const RegistrationDetailPage({super.key, required this.params});

  final RegistrationDetailExtra params;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppAppBar(title: RegistrationStrings.registrationDetailTitle),
      body: Placeholder(),
    );
  }
}
