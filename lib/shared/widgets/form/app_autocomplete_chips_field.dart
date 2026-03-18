import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/design_system/foundation/extensions/theme_extensions.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class AppAutocompleteChipsField extends StatefulWidget {
  const AppAutocompleteChipsField({
    super.key,
    required this.name,
    required this.labelText,
    required this.suggestions,
    this.prefixIcon,
    this.hintText,
    this.helperText,
    this.initialValue,
    this.validator,
  });

  final String name;
  final String labelText;
  final List<String> Function(String query) suggestions;
  final IconData? prefixIcon;
  final String? hintText;
  final String? helperText;
  final List<String>? initialValue;
  final String? Function(List<String>?)? validator;

  @override
  State<AppAutocompleteChipsField> createState() =>
      _AppAutocompleteChipsFieldState();
}

class _AppAutocompleteChipsFieldState extends State<AppAutocompleteChipsField> {
  final TextEditingController _controller = TextEditingController();
  List<String> _filteredSuggestions = [];
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value, FormFieldState<List<String>> field) {
    final results = widget.suggestions(value);
    setState(() => _filteredSuggestions = results);
    if (results.isNotEmpty && value.isNotEmpty) {
      _showOverlay(field);
    } else {
      _removeOverlay();
    }
  }

  void _addChip(String brand, FormFieldState<List<String>> field) {
    final current = List<String>.from(field.value ?? []);
    if (!current.contains(brand)) {
      final updated = [...current, brand];
      field.didChange(updated);
    }
    _controller.clear();
    setState(() => _filteredSuggestions = []);
    _removeOverlay();
  }

  void _removeChip(int index, FormFieldState<List<String>> field) {
    final updated = List<String>.from(field.value ?? [])..removeAt(index);
    field.didChange(updated.isEmpty ? null : updated);
  }

  void _showOverlay(FormFieldState<List<String>> field) {
    final cs = context.colorScheme;

    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            color: cs.surface.withOpacity(0),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: cs.onSurface.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredSuggestions.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: cs.outlineVariant),
                itemBuilder: (_, i) => InkWell(
                  onTap: () => _addChip(_filteredSuggestions[i], field),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.two_wheeler,
                          size: 16,
                          color: cs.primary,
                        ),
                        AppSpacing.hGapSm,
                        Expanded(
                          child: Text(
                            _filteredSuggestions[i],
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final inputIconColor = context.appColors.inputIcon;

    return FormBuilderField<List<String>>(
      name: widget.name,
      initialValue: widget.initialValue ?? [],
      validator: widget.validator,
      builder: (field) {
        final chips = field.value ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CompositedTransformTarget(
              link: _layerLink,
              child: TextFormField(
                controller: _controller,
                onChanged: (v) => _onTextChanged(v, field),
                onTapOutside: (_) => _removeOverlay(),
                onFieldSubmitted: (v) {
                  if (v.trim().isNotEmpty) _addChip(v.trim(), field);
                },
                decoration: InputDecoration(
                  labelText: widget.labelText,
                  hintText: widget.hintText,
                  errorText: field.errorText,
                  helperText: widget.helperText,
                  helperMaxLines: 2,
                  prefixIcon: widget.prefixIcon != null
                      ? Icon(widget.prefixIcon, color: inputIconColor)
                      : null,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: cs.primary,
                    tooltip: 'Agregar marca',
                    onPressed: () {
                      final text = _controller.text.trim();
                      if (text.isNotEmpty) _addChip(text, field);
                    },
                  ),
                ),
              ),
            ),
            if (chips.isNotEmpty) ...[
              AppSpacing.gapMd,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chips.asMap().entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.value,
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        AppSpacing.hGapXs,
                        GestureDetector(
                          onTap: () => _removeChip(entry.key, field),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
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
