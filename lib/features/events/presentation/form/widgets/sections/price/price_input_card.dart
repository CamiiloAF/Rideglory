import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';

/// Card de precio con stepper circular — diseño Pencil XbcHD.
///
/// Muestra "Costo de inscripción / En pesos colombianos" a la izquierda
/// y un stepper [–  $45.000  +] a la derecha.
/// Tocar el valor abre edición inline con formato en tiempo real; el stepper
/// incrementa/decrementa de a 5.000 COP.
class PriceInputCard extends StatefulWidget {
  const PriceInputCard({super.key});

  @override
  State<PriceInputCard> createState() => _PriceInputCardState();
}

class _PriceInputCardState extends State<PriceInputCard> {
  static const int _step = 5000;
  static const int _min = 0;
  static const int _max = 10000000;

  final _textController = TextEditingController();
  bool _isEditing = false;

  static final _fmt = NumberFormat('#,##0', 'es_CO');

  // Formato para mostrar (con $ y puntos de miles).
  String _formatDisplay(int value) => '\$${_fmt.format(value).replaceAll(',', '.')}';

  // Formato para edición inline (solo puntos de miles, sin $).
  String _formatEdit(int value) =>
      value == 0 ? '' : _fmt.format(value).replaceAll(',', '.');

  int _parse(String? raw) {
    if (raw == null || raw.isEmpty) return 0;
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(digits) ?? 0;
  }

  void _startEdit(int currentValue) {
    _textController.text = _formatEdit(currentValue);
    _textController.selection =
        TextSelection.collapsed(offset: _textController.text.length);
    setState(() => _isEditing = true);
  }

  void _commitEdit(FormFieldState<String?> field) {
    _isEditing = false;
    final value = _parse(_textController.text).clamp(_min, _max);
    field.didChange('$value');
    _textController.text = _formatDisplay(value);
    setState(() {});
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<String?>(
      name: EventFormFields.price,
      initialValue: '0',
      builder: (field) {
        final current = _parse(field.value);
        if (!_isEditing) {
          _textController.text = _formatDisplay(current);
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkBorderPrimary),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(child: _PriceLabels()),
              _PriceStepper(
                isEditing: _isEditing,
                controller: _textController,
                onDecrement: () {
                  final next = (current - _step).clamp(_min, _max);
                  field.didChange('$next');
                  setState(() => _isEditing = false);
                },
                onIncrement: () {
                  final next = (current + _step).clamp(_min, _max);
                  field.didChange('$next');
                  setState(() => _isEditing = false);
                },
                onTapValue: () => _startEdit(current),
                onCommit: () => _commitEdit(field),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PriceLabels extends StatelessWidget {
  const _PriceLabels();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Costo de inscripción',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 15,
            fontWeight: FontWeight.normal,
            color: AppColors.textOnDarkPrimary,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'En pesos colombianos',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: AppColors.textOnDarkTertiary,
          ),
        ),
      ],
    );
  }
}

class _PriceStepper extends StatelessWidget {
  const _PriceStepper({
    required this.isEditing,
    required this.controller,
    required this.onDecrement,
    required this.onIncrement,
    required this.onTapValue,
    required this.onCommit,
  });

  final bool isEditing;
  final TextEditingController controller;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onTapValue;
  final VoidCallback onCommit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleBtn(
          onTap: onDecrement,
          fill: const Color(0xFF242429),
          child: const Icon(Icons.remove, size: 16, color: AppColors.textOnDarkPrimary),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 90,
          child: isEditing
              ? Focus(
                  onFocusChange: (hasFocus) {
                    if (!hasFocus) onCommit();
                  },
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_ThousandDotsFormatter()],
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
                    onSubmitted: (_) => onCommit(),
                  ),
                )
              : GestureDetector(
                  onTap: onTapValue,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      controller.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnDarkPrimary,
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 12),
        _CircleBtn(
          onTap: onIncrement,
          fill: AppColors.primary,
          child: const Icon(Icons.add, size: 16, color: AppColors.darkBgPrimary),
        ),
      ],
    );
  }
}

/// Formatea dígitos con puntos de miles colombianos en tiempo real.
/// Entrada: cualquier texto. Salida: solo dígitos con puntos cada 3 (e.g. "45.000").
class _ThousandDotsFormatter extends TextInputFormatter {
  static final _fmt = NumberFormat('#,##0', 'es_CO');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final number = int.tryParse(digits) ?? 0;
    final formatted = _fmt.format(number).replaceAll(',', '.');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.onTap, required this.fill, required this.child});

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
