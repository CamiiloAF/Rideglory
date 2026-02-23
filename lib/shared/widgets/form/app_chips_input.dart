import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class AppChipsInput extends StatefulWidget {
  final String name;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final IconData? prefixIcon;
  final bool isRequired;
  final String? Function(List<String>?)? validator;
  final List<String>? initialValue;

  const AppChipsInput({
    super.key,
    required this.name,
    this.labelText,
    this.hintText,
    this.helperText,
    this.prefixIcon,
    this.isRequired = false,
    this.validator,
    this.initialValue,
  });

  @override
  State<AppChipsInput> createState() => _AppChipsInputState();
}

class _AppChipsInputState extends State<AppChipsInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addChip(List<String> currentChips, Function(List<String>?) onChanged) {
    final text = _textController.text.trim();
    if (text.isNotEmpty && !currentChips.contains(text)) {
      final updatedChips = [...currentChips, text];
      onChanged(updatedChips);
      _textController.clear();
    }
  }

  void _removeChip(
    int index,
    List<String> currentChips,
    Function(List<String>?) onChanged,
  ) {
    final updatedChips = List<String>.from(currentChips);
    updatedChips.removeAt(index);
    onChanged(updatedChips.isEmpty ? null : updatedChips);
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<List<String>>(
      name: widget.name,
      initialValue: widget.initialValue ?? [],
      validator: widget.validator,
      builder: (FormFieldState<List<String>> field) {
        final chips = field.value ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _textController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                labelText: widget.isRequired
                    ? '${widget.labelText} *'
                    : widget.labelText,
                hintText: widget.hintText,
                helperText: widget.helperText,
                errorText: field.errorText,
                prefixIcon: widget.prefixIcon != null
                    ? Icon(widget.prefixIcon)
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Detectar coma y agregar chip
                if (value.endsWith(',')) {
                  _textController.text = value.substring(0, value.length - 1);
                  _addChip(chips, field.didChange);
                }
              },
              onSubmitted: (_) {
                _addChip(chips, field.didChange);
              },
            ),
            if (chips.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chips.asMap().entries.map((entry) {
                  final index = entry.key;
                  final chip = entry.value;
                  return Chip(
                    label: Text(chip),
                    onDeleted: () => _removeChip(index, chips, field.didChange),
                    deleteIcon: const Icon(Icons.close, size: 18),
                  );
                }).toList(),
              ),
            ],
          ],
        );
      },
    );
  }
}
