import 'package:flutter/material.dart';
import 'package:rideglory/generated/l10n.dart';

extension StatelessWidgetExtension on StatelessWidget {
  AppStrings get appStrings => AppStrings.current;
}

extension StateWidgetExtension on State {
  AppStrings get appStrings => AppStrings.current;
}