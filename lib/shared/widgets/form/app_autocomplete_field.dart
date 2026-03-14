import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/shared/widgets/form/text_field_label.dart';

class AppAutocompleteField extends StatefulWidget {
  const AppAutocompleteField({
    super.key,
    required this.name,
    required this.labelText,
    required this.suggestions,
    required this.suggestionsPrefixIcon,
    this.isRequired = false,
    this.validator,
    this.hintText,
    this.onSelected,
    this.suffixIcon,
  });

  final String name;
  final String labelText;
  final List<String> Function(String query) suggestions;
  final IconData suggestionsPrefixIcon;
  final bool isRequired;
  final String? Function(String?)? validator;
  final String? hintText;
  final void Function(String)? onSelected;
  final Widget? suffixIcon;

  @override
  State<AppAutocompleteField> createState() => _AppAutocompleteFieldState();
}

class _AppAutocompleteFieldState extends State<AppAutocompleteField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _filteredSuggestions = [];
  bool _showDropdown = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      Future<void>.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _removeOverlay();
      });
    }
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
    _removeOverlay();
    _controller.text = value;
    field.didChange(value);
    widget.onSelected?.call(value);
    if (mounted) setState(() => _showDropdown = false);
  }

  void _showOverlay(FormFieldState<String> field) {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (_) => _SuggestionsOverlay(
        link: _layerLink,
        suggestions: _filteredSuggestions,
        onSelect: (val) => _select(val, field),
        prefixIcon: widget.suggestionsPrefixIcon,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText.isNotEmpty)
          TextFieldLabel(
            labelText: widget.labelText,
            isRequired: widget.isRequired,
          ),
        FormBuilderField<String>(
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
                focusNode: _focusNode,
                onChanged: (v) => _onChanged(v, field),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  errorText: field.errorText,
                  prefixIcon: widget.suggestionsPrefixIcon != null
                      ? Icon(
                          widget.suggestionsPrefixIcon,
                          color: AppColors.darkInputIcon,
                        )
                      : null,
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          color: AppColors.darkInputIcon,
                          onPressed: () {
                            _controller.clear();
                            field.didChange(null);
                            _removeOverlay();
                            setState(() => _showDropdown = false);
                          },
                        )
                      : widget.suffixIcon,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SuggestionsOverlay extends StatelessWidget {
  const _SuggestionsOverlay({
    required this.link,
    required this.suggestions,
    required this.onSelect,
    required this.prefixIcon,
  });

  final LayerLink link;
  final List<String> suggestions;
  final void Function(String) onSelect;
  final IconData prefixIcon;
  static const double _maxHeight = 280;
  static const double _width = 300;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      width: _width,
      child: CompositedTransformFollower(
        link: link,
        showWhenUnlinked: false,
        offset: const Offset(0, 56),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: _maxHeight),
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
              physics: const BouncingScrollPhysics(),
              itemCount: suggestions.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.darkBorder),
              itemBuilder: (_, i) {
                final value = suggestions[i];
                return InkWell(
                  onTap: () => onSelect(value),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(prefixIcon, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            value,
                            style: const TextStyle(
                              color: AppColors.darkTextPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
