import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/services/place_service.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/shared/widgets/form/app_place_suggestions_dropdown.dart';

enum PlaceAutocompleteType {
  cities('cities'),
  establishment('establishment');

  const PlaceAutocompleteType(this.value);
  final String value;
}

class AppPlaceAutocompleteField extends StatefulWidget {
  const AppPlaceAutocompleteField({
    super.key,
    required this.name,
    required this.labelText,
    required this.hintText,
    required this.placeType,
    this.isRequired = false,
    this.validator,
    this.onSelected,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final String name;
  final String labelText;
  final String hintText;
  final PlaceAutocompleteType placeType;
  final bool isRequired;
  final String? Function(String?)? validator;
  final void Function(String)? onSelected;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String? value)? onFieldSubmitted;

  @override
  State<AppPlaceAutocompleteField> createState() =>
      _AppPlaceAutocompleteFieldState();
}

class _AppPlaceAutocompleteFieldState
    extends State<AppPlaceAutocompleteField> {
  final TextEditingController _controller = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _overlayController = OverlayPortalController();

  Timer? _debounce;
  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    if (value.length < 3) {
      _closeSuggestions();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchSuggestions(value);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final results = await getIt<PlaceService>().autocomplete(
        query,
        widget.placeType.value,
      );
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _isLoading = false;
      });
      _overlayController.show();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _suggestions = [];
      });
      _overlayController.show();
    }
  }

  void _selectSuggestion(String suggestion, FormFieldState<String> field) {
    _controller.text = suggestion;
    field.didChange(suggestion);
    widget.onSelected?.call(suggestion);
    _closeSuggestions();
  }

  void _closeSuggestions() {
    if (_overlayController.isShowing) {
      _overlayController.hide();
    }
    setState(() {
      _suggestions = [];
      _isLoading = false;
      _hasError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<String>(
      name: widget.name,
      validator: widget.validator,
      builder: (field) {
        // Sync initial value
        if (field.value != null &&
            field.value!.isNotEmpty &&
            _controller.text.isEmpty) {
          _controller.text = field.value!;
        }

        return CompositedTransformTarget(
          link: _layerLink,
          child: OverlayPortal(
            controller: _overlayController,
            overlayChildBuilder: (overlayContext) {
              return CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                child: AppPlaceSuggestionsDropdown(
                  suggestions: _suggestions,
                  isLoading: _isLoading,
                  hasError: _hasError,
                  onSelect: (suggestion) => _selectSuggestion(suggestion, field),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                if (widget.labelText.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        widget.labelText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOnDarkTertiary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      if (widget.isRequired) ...[
                        const SizedBox(width: 4),
                        const Text(
                          '*',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                // Text field
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.darkBgSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: field.hasError
                          ? AppColors.error
                          : AppColors.darkBorderPrimary,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: widget.focusNode,
                          textInputAction: widget.textInputAction,
                          style: const TextStyle(
                            color: AppColors.textOnDarkPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: widget.hintText,
                            hintStyle: const TextStyle(
                              color: AppColors.textOnDarkTertiary,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                          ),
                          onChanged: _onTextChanged,
                          onSubmitted: (value) {
                            widget.onFieldSubmitted
                                ?.call(value.isEmpty ? null : value);
                          },
                        ),
                      ),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(right: 14),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(right: 14),
                          child: Icon(
                            Icons.place_outlined,
                            color: AppColors.textOnDarkTertiary,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
                // Validation error
                if (field.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      field.errorText ?? '',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
