import 'package:flutter/material.dart';

class ContainerPullToRefresh extends StatelessWidget {
  const ContainerPullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  final Widget child;
  final RefreshCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height -
                kToolbarHeight -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom -
                100,
          ),
          child: child,
        ),
      ),
    );
  }
}
