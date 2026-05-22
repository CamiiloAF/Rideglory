import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/services/dto/place_suggestion_dto.dart';
import 'package:rideglory/core/services/place_service.dart';
export 'package:rideglory/core/services/dto/place_suggestion_dto.dart' show PlaceSuggestionDto;
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/shared/models/address_location.dart';
import 'package:rideglory/shared/widgets/form/app_place_suggestions_dropdown.dart';
import 'package:rideglory/shared/widgets/form/map_location_picker_modal.dart';

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
    this.showMapPicker = false,
    this.compact = false,
    this.clearOnSelect = false,
    this.resolveCoords = false,
    this.validator,
    this.onSelected,
    this.onLocationSelected,
    this.onPlaceSelected,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final String name;
  final String labelText;
  final String hintText;
  final PlaceAutocompleteType placeType;
  final bool isRequired;
  final bool showMapPicker;

  /// When true, renders without the outer label and container — for embedding
  /// inside a Route Card row. The parent must provide its own padding and
  /// visual container.
  final bool compact;

  /// When true, clears the text field after a suggestion is selected. Useful
  /// for multi-entry fields like waypoint search where each selection should
  /// reset the input for the next entry.
  final bool clearOnSelect;

  /// When true, resolves geographic coordinates via the Places Details API
  /// using the suggestion's [placeId] before firing [onPlaceSelected].
  /// Shows a spinner while resolving. Removes the need for manual geocoding
  /// at the call site.
  final bool resolveCoords;

  final String? Function(String?)? validator;
  final void Function(String)? onSelected;

  /// Called when a suggestion with known coordinates is selected.
  /// Provides the resolved [AddressLocation] directly, avoiding geocoding.
  final void Function(AddressLocation)? onLocationSelected;

  /// Combined callback that fires with both the place name and its optional
  /// location in a single call. Fires before [onSelected] and [onLocationSelected].
  final void Function(String name, AddressLocation? location)? onPlaceSelected;

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

  // Groups the text field and the overlay dropdown into one tap region so that
  // tapping a suggestion does not trigger onTapOutside before the tap registers.
  final Object _tapRegionGroupId = Object();

  Timer? _debounce;
  List<PlaceSuggestionDto> _suggestions = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _resolving = false;

  FormFieldState<String>? _field;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    // Keep field.value in sync so the initial-value sync guard doesn't
    // restore old text after the user clears or edits the field.
    _field?.didChange(value.isEmpty ? null : value);
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

  void _selectSuggestion(
    PlaceSuggestionDto suggestion,
    FormFieldState<String> field,
  ) {
    if (widget.clearOnSelect) {
      _controller.clear();
      field.didChange(null);
    } else {
      _controller.text = suggestion.name;
      field.didChange(suggestion.name);
    }
    _closeSuggestions();

    final placeId = suggestion.placeId;
    if (widget.resolveCoords && placeId != null && suggestion.location == null) {
      unawaited(_resolveAndFire(suggestion.name, placeId));
    } else {
      final location = suggestion.location;
      widget.onPlaceSelected?.call(suggestion.name, location);
      widget.onSelected?.call(suggestion.name);
      if (location != null) widget.onLocationSelected?.call(location);
    }
  }

  Future<void> _resolveAndFire(String name, String placeId) async {
    if (!mounted) return;
    setState(() => _resolving = true);
    AddressLocation? resolved;
    try {
      final result = await getIt<PlaceService>().details(placeId);
      resolved = AddressLocation(
        latitude: result.latitude,
        longitude: result.longitude,
        label: result.formattedAddress ?? name,
      );
    } catch (_) {}
    if (!mounted) return;
    setState(() => _resolving = false);
    widget.onPlaceSelected?.call(name, resolved);
    widget.onSelected?.call(name);
    if (resolved != null) widget.onLocationSelected?.call(resolved);
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

  void _clearField(FormFieldState<String> field) {
    _controller.clear();
    field.didChange(null);
    _closeSuggestions();
    widget.onPlaceSelected?.call('', null);
    widget.onSelected?.call('');
  }

  Future<void> _openMapPicker(FormFieldState<String> field) async {
    _closeSuggestions();
    final result = await MapLocationPickerModal.show(context);
    if (result != null && mounted) {
      _controller.text = result;
      field.didChange(result);
      widget.onSelected?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<String>(
      name: widget.name,
      validator: widget.validator,
      builder: (field) {
        _field = field;
        // Sync initial value only when the controller is still empty and the
        // field has a non-empty value (first render with a pre-filled form).
        // After the user starts editing, _onTextChanged keeps field.value in
        // sync so this guard never fires unexpectedly.
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
                child: TapRegion(
                  groupId: _tapRegionGroupId,
                  child: AppPlaceSuggestionsDropdown(
                    suggestions: _suggestions,
                    isLoading: _isLoading,
                    hasError: _hasError,
                    onSelect: (suggestion) =>
                        _selectSuggestion(suggestion, field),
                  ),
                ),
              );
            },
            child: TapRegion(
              groupId: _tapRegionGroupId,
              onTapOutside: (_) => _closeSuggestions(),
              child: widget.compact
                  ? _CompactFieldRow(
                      controller: _controller,
                      focusNode: widget.focusNode,
                      textInputAction: widget.textInputAction,
                      hintText: widget.hintText,
                      isLoading: _isLoading || _resolving,
                      showMapPicker: widget.showMapPicker,
                      hasContent: field.value?.isNotEmpty ?? false,
                      onTextChanged: _onTextChanged,
                      onSubmitted: (value) {
                        widget.onFieldSubmitted?.call(
                          value.isEmpty ? null : value,
                        );
                      },
                      onMapPicker: () => _openMapPicker(field),
                      onClear: () => _clearField(field),
                    )
                  : _FullFieldLayout(
                      controller: _controller,
                      focusNode: widget.focusNode,
                      textInputAction: widget.textInputAction,
                      labelText: widget.labelText,
                      hintText: widget.hintText,
                      isRequired: widget.isRequired,
                      isLoading: _isLoading,
                      showMapPicker: widget.showMapPicker,
                      hasContent: field.value?.isNotEmpty ?? false,
                      hasError: field.hasError,
                      errorText: field.errorText,
                      onTextChanged: _onTextChanged,
                      onSubmitted: (value) {
                        widget.onFieldSubmitted?.call(
                          value.isEmpty ? null : value,
                        );
                      },
                      onMapPicker: () => _openMapPicker(field),
                      onClear: () => _clearField(field),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _CompactFieldRow extends StatelessWidget {
  const _CompactFieldRow({
    required this.controller,
    required this.hintText,
    required this.isLoading,
    required this.showMapPicker,
    required this.hasContent,
    required this.onTextChanged,
    required this.onSubmitted,
    required this.onMapPicker,
    required this.onClear,
    this.focusNode,
    this.textInputAction,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final String hintText;
  final bool isLoading;
  final bool showMapPicker;
  final bool hasContent;
  final void Function(String) onTextChanged;
  final void Function(String) onSubmitted;
  final VoidCallback onMapPicker;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: textInputAction,
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
              color: AppColors.textOnDarkPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                fontFamily: 'Space Grotesk',
                color: AppColors.textOnDarkTertiary,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              isDense: true,
            ),
            onChanged: onTextChanged,
            onSubmitted: onSubmitted,
          ),
        ),
        const SizedBox(width: 8),
        if (isLoading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          )
        else if (hasContent)
          GestureDetector(
            onTap: onClear,
            child: const Icon(
              Icons.close,
              color: AppColors.textOnDarkTertiary,
              size: 18,
            ),
          )
        else if (showMapPicker)
          GestureDetector(
            onTap: onMapPicker,
            child: const Icon(
              Icons.map_outlined,
              color: AppColors.textOnDarkTertiary,
              size: 18,
            ),
          ),
      ],
    );
  }
}

class _FullFieldLayout extends StatelessWidget {
  const _FullFieldLayout({
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.isRequired,
    required this.isLoading,
    required this.showMapPicker,
    required this.hasContent,
    required this.hasError,
    required this.onTextChanged,
    required this.onSubmitted,
    required this.onMapPicker,
    required this.onClear,
    this.focusNode,
    this.textInputAction,
    this.errorText,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final String labelText;
  final String hintText;
  final bool isRequired;
  final bool isLoading;
  final bool showMapPicker;
  final bool hasContent;
  final bool hasError;
  final String? errorText;
  final void Function(String) onTextChanged;
  final void Function(String) onSubmitted;
  final VoidCallback onMapPicker;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText.isNotEmpty) ...[
          Row(
            children: [
              Text(
                labelText,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textOnDarkTertiary,
                  letterSpacing: 0.8,
                ),
              ),
              if (isRequired) ...[
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(color: AppColors.error, fontSize: 11),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkBgSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? AppColors.error : AppColors.darkBorderPrimary,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: textInputAction,
                  style: const TextStyle(
                    color: AppColors.textOnDarkPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
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
                  onChanged: onTextChanged,
                  onSubmitted: onSubmitted,
                ),
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                )
              else if (hasContent)
                GestureDetector(
                  onTap: onClear,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 14),
                    child: Icon(
                      Icons.close,
                      color: AppColors.textOnDarkTertiary,
                      size: 18,
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: showMapPicker ? onMapPicker : null,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Icon(
                      showMapPicker
                          ? Icons.map_outlined
                          : Icons.place_outlined,
                      color: showMapPicker
                          ? AppColors.primary
                          : AppColors.textOnDarkTertiary,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              errorText ?? '',
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
