import 'package:flutter/material.dart';

/// Visual emphasis of an [AppModalAction] button.
///
/// - [primary]: filled accent button (the affirmative action).
/// - [danger]: filled error button (destructive affirmative action).
/// - [neutral]: filled neutral surface button (typically the cancel/dismiss
///   action). Matches the Pencil modal "Cancelar" button.
enum AppModalActionEmphasis { primary, danger, neutral }

/// Declarative description of a button rendered inside an [AppModal].
class AppModalAction {
  final String label;
  final VoidCallback onPressed;
  final AppModalActionEmphasis emphasis;
  final bool isLoading;

  const AppModalAction({
    required this.label,
    required this.onPressed,
    this.emphasis = AppModalActionEmphasis.primary,
    this.isLoading = false,
  });

  /// Convenience neutral/cancel action.
  const AppModalAction.neutral({required this.label, required this.onPressed})
    : emphasis = AppModalActionEmphasis.neutral,
      isLoading = false;
}
