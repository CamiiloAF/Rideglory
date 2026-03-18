import 'package:flutter/material.dart';

class ExpandableContainer extends StatefulWidget {
  const ExpandableContainer({
    super.key,
    this.leading,
    required this.title,
    required this.child,
    this.initiallyExpanded = true,
    this.contentPadding = const EdgeInsets.only(top: 16),
    this.trailingColor,
  });

  final Widget? leading;
  final Widget title;
  final Widget child;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry contentPadding;
  final Color? trailingColor;

  @override
  State<ExpandableContainer> createState() => _ExpandableContainerState();
}

class _ExpandableContainerState extends State<ExpandableContainer> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                SizedBox(width: 10),
              ],
              Expanded(child: widget.title),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 24,
                  color: widget.trailingColor,
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: widget.contentPadding,
                  child: widget.child,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
