import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

class FilterSectionTitle extends StatelessWidget {
  final String title;

  const FilterSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: context.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
