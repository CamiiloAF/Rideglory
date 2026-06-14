import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rideglory/design_system/design_system.dart';

class MaxParticipantsStepper extends StatefulWidget {
  const MaxParticipantsStepper({
    super.key,
    required this.count,
    required this.onDecrement,
    required this.onIncrement,
    required this.onManualChange,
  });

  final int? count;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final void Function(int?) onManualChange;

  @override
  State<MaxParticipantsStepper> createState() => _MaxParticipantsStepperState();
}

class _MaxParticipantsStepperState extends State<MaxParticipantsStepper> {
  static const int _min = 5;
  static const int _max = 500;

  late final TextEditingController _textController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.count != null ? '${widget.count}' : '',
    );
  }

  @override
  void didUpdateWidget(MaxParticipantsStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.count != widget.count) {
      _textController.text = widget.count != null ? '${widget.count}' : '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onFocusLost() {
    _isEditing = false;
    final text = _textController.text;
    if (text.isEmpty) {
      widget.onManualChange(null);
      setState(() {});
      return;
    }
    final parsed = int.tryParse(text);
    if (parsed == null) {
      _textController.text = widget.count != null ? '${widget.count}' : '';
    } else {
      final clamped = parsed.clamp(_min, _max);
      _textController.text = '$clamped';
      widget.onManualChange(clamped);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleButton(
          onTap: () {
            setState(() => _isEditing = false);
            widget.onDecrement();
          },
          fill: const Color(0xFF242429),
          child: const Icon(Icons.remove, size: 16, color: AppColors.textOnDarkPrimary),
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: 56,
          child: _isEditing
              ? Focus(
                  onFocusChange: (hasFocus) {
                    if (!hasFocus) _onFocusLost();
                  },
                  child: TextField(
                    controller: _textController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnDarkPrimary,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() => _isEditing = true),
                    onSubmitted: (_) => _onFocusLost(),
                  ),
                )
              : GestureDetector(
                  onTap: () => setState(() => _isEditing = true),
                  child: Text(
                    widget.count != null ? '${widget.count}' : '—',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: widget.count != null
                          ? AppColors.textOnDarkPrimary
                          : AppColors.textOnDarkTertiary,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 14),
        _CircleButton(
          onTap: () {
            setState(() => _isEditing = false);
            widget.onIncrement();
          },
          fill: AppColors.primary,
          child: const Icon(Icons.add, size: 16, color: AppColors.darkBgPrimary),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.onTap,
    required this.fill,
    required this.child,
  });

  final VoidCallback onTap;
  final Color fill;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
        child: Center(child: child),
      ),
    );
  }
}
