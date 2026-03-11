import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/core/theme/app_colors.dart';

class AppAutocompleteField extends StatefulWidget {
  const AppAutocompleteField({
    super.key,
    required this.name,
    required this.labelText,
    required this.suggestions,
    this.prefixIcon,
    this.isRequired = false,
    this.validator,
    this.hintText,
    this.onSelected,
  });

  final String name;
  final String labelText;
  final List<String> Function(String query) suggestions;
  final IconData? prefixIcon;
  final bool isRequired;
  final String? Function(String?)? validator;
  final String? hintText;
  final void Function(String)? onSelected;

  @override
  State<AppAutocompleteField> createState() => _AppAutocompleteFieldState();
}

class _AppAutocompleteFieldState extends State<AppAutocompleteField> {
  final TextEditingController _controller = TextEditingController();
  List<String> _filteredSuggestions = [];
  bool _showDropdown = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value, FormFieldState<String> field) {
    field.didChange(value);
    final results = widget.suggestions(value);
    setState(() {
      _filteredSuggestions = results;
      _showDropdown = results.isNotEmpty;
    });
    if (_showDropdown) {
      _showOverlay(field);
    } else {
      _removeOverlay();
    }
  }

  void _select(String value, FormFieldState<String> field) {
    _controller.text = value;
    field.didChange(value);
    widget.onSelected?.call(value);
    setState(() => _showDropdown = false);
    _removeOverlay();
  }

  void _showOverlay(FormFieldState<String> field) {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (_) => _SuggestionsOverlay(
        link: _layerLink,
        suggestions: _filteredSuggestions,
        onSelect: (val) => _select(val, field),
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
    return FormBuilderField<String>(
      name: widget.name,
      validator: widget.validator,
      builder: (field) {
        if (_controller.text.isEmpty && field.value != null) {
          _controller.text = field.value!;
        }
        return CompositedTransformTarget(
          link: _layerLink,
          child: TextFormField(
            controller: _controller,
            onChanged: (v) => _onChanged(v, field),
            onTapOutside: (_) => _removeOverlay(),
            decoration: InputDecoration(
              labelText: widget.isRequired
                  ? '${widget.labelText} *'
                  : widget.labelText,
              hintText: widget.hintText,
              errorText: field.errorText,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: AppColors.darkTextSecondary)
                  : null,
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      color: AppColors.darkTextSecondary,
                      onPressed: () {
                        _controller.clear();
                        field.didChange(null);
                        _removeOverlay();
                        setState(() => _showDropdown = false);
                      },
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }
}

class _SuggestionsOverlay extends StatelessWidget {
  const _SuggestionsOverlay({
    required this.link,
    required this.suggestions,
    required this.onSelect,
  });

  final LayerLink link;
  final List<String> suggestions;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      width: 300,
      child: CompositedTransformFollower(
        link: link,
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
              itemCount: suggestions.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: AppColors.darkBorder),
              itemBuilder: (_, i) => InkWell(
                onTap: () => onSelect(suggestions[i]),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestions[i],
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
    );
  }
}
