import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/data/colombia_motos_brands_data.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/presentation/form/widgets/event_form_section_card.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';

class EventFormMultiBrandSection extends StatelessWidget {
  const EventFormMultiBrandSection({super.key});

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<bool>(
      name: EventFormFields.isMultiBrand,
      builder: (isField) {
        final isMultiBrand = isField.value ?? true;
        return EventFormSectionCard(
          icon: Icons.two_wheeler,
          title: EventStrings.multiBrandLabel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(EventStrings.multiBrandAllowAny)),
                  Switch(
                    value: isMultiBrand,
                    onChanged: (v) => isField.didChange(v),
                  ),
                ],
              ),

              if (!isMultiBrand) ...[
                const SizedBox(height: 16),

                Text(
                  EventStrings.selectBrands.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: context.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                FormBuilderField<List<String>>(
                  name: EventFormFields.allowedBrands,
                  builder: (listField) => _BrandChipsInline(
                    field: listField,
                    suggestions: ColombiaMotosBrandsData.search,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BrandChipsInline extends StatefulWidget {
  const _BrandChipsInline({required this.field, required this.suggestions});

  final FormFieldState<List<String>> field;
  final List<String> Function(String query) suggestions;

  @override
  State<_BrandChipsInline> createState() => _BrandChipsInlineState();
}

class _BrandChipsInlineState extends State<_BrandChipsInline> {
  final TextEditingController _controller = TextEditingController();
  List<String> _filtered = [];
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlay;

  @override
  void dispose() {
    _overlay?.remove();
    _controller.dispose();
    super.dispose();
  }

  void _add(String brand) {
    final current = List<String>.from(widget.field.value ?? []);
    if (!current.contains(brand)) widget.field.didChange([...current, brand]);
    _controller.clear();
    setState(() => _filtered = []);
    _overlay?.remove();
    _overlay = null;
  }

  void _remove(int index) {
    final list = List<String>.from(widget.field.value ?? [])..removeAt(index);
    widget.field.didChange(list.isEmpty ? null : list);
  }

  void _onChanged(String value) {
    setState(() => _filtered = widget.suggestions(value));
    if (_filtered.isNotEmpty && value.isNotEmpty) {
      _overlay?.remove();
      _overlay = OverlayEntry(
        builder: (_) => Positioned(
          width: 300,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 56),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 220),
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
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: AppColors.darkBorder),
                  itemBuilder: (_, i) => InkWell(
                    onTap: () => _add(_filtered[i]),
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
                              _filtered[i],
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
      Overlay.of(context).insert(_overlay!);
    } else {
      _overlay?.remove();
      _overlay = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chips = widget.field.value ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: TextFormField(
            controller: _controller,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: EventStrings.searchBrandsPlaceholder,
              suffixIcon: Icon(Icons.search, color: AppColors.darkInputIcon),
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
                  color: AppColors.primaryDark.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _remove(entry.key),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
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
  }
}
