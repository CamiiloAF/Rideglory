import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/max_participants/stepper_button.dart';

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
      return;
    }
    final parsed = int.tryParse(text);
    if (parsed == null) {
      // Revert to previous valid value
      _textController.text = widget.count != null ? '${widget.count}' : '';
    } else {
      final clamped = parsed.clamp(_min, _max);
      _textController.text = '$clamped';
      widget.onManualChange(clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkTertiary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Row(
        children: [
          StepperButton(
            onTap: () {
              setState(() => _isEditing = false);
              widget.onDecrement();
            },
            child: const Icon(
              Icons.remove,
              size: 16,
              color: AppColors.textOnDarkSecondary,
            ),
          ),
          Container(width: 1, height: 24, color: AppColors.darkBorderPrimary),
          Expanded(
            child: Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) _onFocusLost();
              },
              child: TextField(
                controller: _textController,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: widget.count != null
                      ? AppColors.textOnDarkPrimary
                      : AppColors.textOnDarkTertiary,
                ),
                decoration: const InputDecoration(
                  hintText: '—',
                  hintStyle: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOnDarkTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onChanged: (_) => setState(() => _isEditing = true),
                onSubmitted: (_) => _onFocusLost(),
              ),
            ),
          ),
          Container(width: 1, height: 24, color: AppColors.darkBorderPrimary),
          StepperButton(
            onTap: () {
              setState(() => _isEditing = false);
              widget.onIncrement();
            },
            child: const Icon(Icons.add, size: 16, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
