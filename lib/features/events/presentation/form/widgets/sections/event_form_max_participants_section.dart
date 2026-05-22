import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

/// Section for the optional "Máximo de Participantes" field.
///
/// Matches Pencil frame zbCa0 — "MÁXIMO DE PARTICIPANTES" section:
/// - Section header with "Opcional" badge
/// - Card with label (left) + stepper (right): minus / count / plus
/// - Hint row with users icon
///
/// Field value is `null` when not set (no limit).
/// First "+" tap activates the field at min value (5).
/// Tapping "–" when at min returns to null.
class EventFormMaxParticipantsSection extends StatelessWidget {
  const EventFormMaxParticipantsSection({super.key});

  static const int _min = 5;
  static const int _max = 500;
  static const int _step = 5;

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<int?>(
      name: EventFormFields.maxParticipants,
      builder: (field) {
        final count = field.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MaxParticipantsHeader(context: context),
            const SizedBox(height: 10),
            _MaxParticipantsCard(
              count: count,
              onDecrement: () {
                if (count == null || count <= _min) {
                  field.didChange(null);
                } else {
                  field.didChange(count - _step);
                }
              },
              onIncrement: () {
                if (count == null) {
                  field.didChange(_min);
                } else if (count < _max) {
                  field.didChange(count + _step);
                }
              },
              onManualChange: field.didChange,
            ),
            const SizedBox(height: 6),
            _MaxParticipantsHint(context: context),
          ],
        );
      },
    );
  }
}

class _MaxParticipantsHeader extends StatelessWidget {
  const _MaxParticipantsHeader({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.l10n.event_form_max_participants_section_title,
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.textOnDarkTertiary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.darkTertiary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            context.l10n.event_form_optional_badge,
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textOnDarkTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

class _MaxParticipantsCard extends StatelessWidget {
  const _MaxParticipantsCard({
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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _MaxParticipantsCardLabels(context: context),
          const SizedBox(width: 12),
          Expanded(
            child: _MaxParticipantsStepper(
              count: count,
              onDecrement: onDecrement,
              onIncrement: onIncrement,
              onManualChange: onManualChange,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaxParticipantsCardLabels extends StatelessWidget {
  const _MaxParticipantsCardLabels({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.event_form_max_participants_label,
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textOnDarkPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          context.l10n.event_form_max_participants_subtitle,
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 11,
            fontWeight: FontWeight.normal,
            color: AppColors.textOnDarkTertiary,
          ),
        ),
      ],
    );
  }
}

class _MaxParticipantsStepper extends StatefulWidget {
  const _MaxParticipantsStepper({
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
  State<_MaxParticipantsStepper> createState() =>
      _MaxParticipantsStepperState();
}

class _MaxParticipantsStepperState extends State<_MaxParticipantsStepper> {
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
  void didUpdateWidget(_MaxParticipantsStepper oldWidget) {
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
          _StepperButton(
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
          _StepperButton(
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

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(width: 40, height: 40, child: Center(child: child)),
    );
  }
}

class _MaxParticipantsHint extends StatelessWidget {
  const _MaxParticipantsHint({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.group_outlined,
          size: 13,
          color: AppColors.textOnDarkTertiary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            context.l10n.event_form_max_participants_hint,
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 11,
              fontWeight: FontWeight.normal,
              color: AppColors.textOnDarkTertiary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
