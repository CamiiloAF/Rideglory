import 'package:flutter/material.dart';

import '../../../core/domain/result_state.dart';
import 'empty_state_view.dart';
import 'error_state_view.dart';
import 'skeleton_list.dart';

/// Mapea un [ResultState] a los widgets de estado obligatorios: skeleton en
/// `loading`, vacío en `empty`, error accionable en `error`, y el contenido
/// real en `data`. `initial` se trata como `loading` por defecto.
class ResultStateBuilder<T> extends StatelessWidget {
  const ResultStateBuilder({
    required this.state,
    required this.onData,
    required this.onRetry,
    this.loadingBuilder,
    this.emptyBuilder,
    super.key,
  });

  final ResultState<T> state;
  final Widget Function(BuildContext context, T data) onData;
  final VoidCallback onRetry;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;

  @override
  Widget build(BuildContext context) {
    return state.when(
      initial: () =>
          (loadingBuilder ?? (context) => const SkeletonList())(context),
      loading: () =>
          (loadingBuilder ?? (context) => const SkeletonList())(context),
      data: (data) => onData(context, data),
      empty: () =>
          (emptyBuilder ?? (context) => const EmptyStateView())(context),
      error: (error) =>
          ErrorStateView(message: error.message, onRetry: onRetry),
    );
  }
}
