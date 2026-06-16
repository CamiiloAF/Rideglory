import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/design_system/design_system.dart';

class AppAutocompleteField extends StatefulWidget {
  const AppAutocompleteField({
    super.key,
    required this.name,
    required this.labelText,
    required this.suggestions,
    this.remoteSuggestions,
    required this.suggestionsPrefixIcon,
    this.isRequired = false,
    this.validator,
    this.hintText,
    this.selectionRequiredError,
    this.onSelected,
    this.suffixIcon,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final String name;
  final String labelText;
  final List<String> Function(String query) suggestions;
  final Future<List<String>> Function(String query)? remoteSuggestions;
  final IconData suggestionsPrefixIcon;
  final bool isRequired;
  final String? Function(String?)? validator;
  final String? hintText;
  final String? selectionRequiredError;
  final void Function(String)? onSelected;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String? value)? onFieldSubmitted;

  @override
  State<AppAutocompleteField> createState() => _AppAutocompleteFieldState();
}

class _AppAutocompleteFieldState extends State<AppAutocompleteField> {
  final TextEditingController _controller = TextEditingController();
  FocusNode? _ownedFocusNode;
  List<String> _filteredSuggestions = [];
  bool _showDropdown = false;
  int _queryVersion = 0;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    _ownedFocusNode?.dispose();
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_effectiveFocusNode.hasFocus) {
      Future<void>.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _removeOverlay();
      });
    }
  }

  String? _validate(String? value) {
    if (value == null && _controller.text.isNotEmpty) {
      return widget.selectionRequiredError ?? 'Selecciona una opción válida de la lista';
    }
    return widget.validator?.call(value);
  }

  void _onChanged(String value, FormFieldState<String> field) {
    field.didChange(null);
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
    if (widget.remoteSuggestions != null) {
      _fetchRemoteSuggestions(value, field);
    }
  }

  Future<void> _fetchRemoteSuggestions(
    String query,
    FormFieldState<String> field,
  ) async {
    final currentVersion = ++_queryVersion;
    List<String> remoteResults;
    try {
      remoteResults = await widget.remoteSuggestions!(query);
    } catch (_) {
      remoteResults = const <String>[];
    }
    if (!mounted || currentVersion != _queryVersion) {
      return;
    }
    setState(() {
      _filteredSuggestions = remoteResults;
      _showDropdown = remoteResults.isNotEmpty;
    });
    if (_showDropdown) {
      _showOverlay(field);
      return;
    }
    _removeOverlay();
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
          validator: _validate,
          builder: (field) {
            // Sync controller ← field only when field has a confirmed value
            // (selection made or form pre-populated), or when the controller is
            // already empty. Never wipe typed-but-unconfirmed text (field.value
            // is null until the user picks from the dropdown).
            final fieldText = field.value ?? '';
            final shouldSync = field.value != null || _controller.text.isEmpty;
            if (shouldSync && fieldText != _controller.text) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                final stillShould = field.value != null || _controller.text.isEmpty;
                if (stillShould && (field.value ?? '') != _controller.text) {
                  _controller.text = field.value ?? '';
                }
              });
            }
            return CompositedTransformTarget(
              link: _layerLink,
              child: TextFormField(
                controller: _controller,
                focusNode: _effectiveFocusNode,
                textInputAction: widget.textInputAction,
                onFieldSubmitted: widget.onFieldSubmitted,
                onChanged: (v) => _onChanged(v, field),
                style: const TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 14,
                  ),
                  errorText: field.errorText,
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          color: context.appColors.inputIcon,
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
    final cs = context.colorScheme;

    return Positioned(
      width: _width,
      child: CompositedTransformFollower(
        link: link,
        showWhenUnlinked: false,
        offset: const Offset(0, 56),
        child: Material(
          color: cs.surface.withValues(alpha: 0),
          child: Container(
            constraints: const BoxConstraints(maxHeight: _maxHeight),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: cs.onSurface.withValues(alpha: 0.3),
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
                  Divider(height: 1, color: cs.outlineVariant),
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
                        Icon(prefixIcon, color: cs.primary),
                        AppSpacing.hGapSm,
                        Expanded(
                          child: Text(
                            value,
                            style: TextStyle(color: cs.onSurface, fontSize: 14),
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
