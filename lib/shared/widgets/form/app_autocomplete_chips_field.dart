import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/core/theme/app_colors.dart';

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
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.darkBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
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
                    Divider(height: 1, color: AppColors.darkBorder),
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
                        const Icon(
                          Icons.two_wheeler,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _filteredSuggestions[i],
                            style: const TextStyle(
                              color: AppColors.darkTextPrimary,
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
                      ? Icon(widget.prefixIcon, color: AppColors.darkInputIcon)
                      : null,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primary,
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
              const SizedBox(height: 12),
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
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.value,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _removeChip(entry.key, field),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: AppColors.primary,
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
