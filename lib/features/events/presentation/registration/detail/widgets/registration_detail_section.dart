import 'package:flutter/material.dart';
import 'package:rideglory/features/events/presentation/registration/detail/widgets/registration_detail_section_header.dart';

class RegistrationDetailSection extends StatelessWidget {
  const RegistrationDetailSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegistrationDetailSectionHeader(icon: icon, title: title),
        ...children,
      ],
    );
  }
}
