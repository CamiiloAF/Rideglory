import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/core/data/colombia_motos_brands_data.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/presentation/form/widgets/event_form_section_card.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

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
          title: context.l10n.event_multiBrandLabel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.event_multiBrandAllowAny)),
                  Switch(
                    value: isMultiBrand,
                    onChanged: (v) => isField.didChange(v),
                  ),
                ],
              ),

              if (!isMultiBrand) ...[
                AppSpacing.gapLg,

                Text(
                  context.l10n.event_selectBrands.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: context.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                AppSpacing.gapMd,
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
                  color: context.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.colorScheme.outlineVariant),
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
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: context.colorScheme.outlineVariant),
                  itemBuilder: (_, i) => InkWell(
                    onTap: () => _add(_filtered[i]),
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
                            color: context.colorScheme.primary,
                          ),
                          AppSpacing.hGapSm,
                          Expanded(
                            child: Text(
                              _filtered[i],
                              style: TextStyle(
                                color: context.colorScheme.onSurface,
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
              hintText: context.l10n.event_searchBrandsPlaceholder,
              suffixIcon: Icon(Icons.search, color: context.appColors.inputIcon),
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
                  color: context.colorScheme.primary.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.value,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    AppSpacing.hGapXs,
                    GestureDetector(
                      onTap: () => _remove(entry.key),
                      child: Icon(
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
