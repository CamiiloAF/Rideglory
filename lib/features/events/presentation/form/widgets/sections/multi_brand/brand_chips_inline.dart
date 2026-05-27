import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class BrandChipsInline extends StatefulWidget {
  const BrandChipsInline({
    super.key,
    required this.field,
    required this.suggestions,
  });

  final FormFieldState<List<String>> field;
  final List<String> Function(String query) suggestions;

  @override
  State<BrandChipsInline> createState() => _BrandChipsInlineState();
}

class _BrandChipsInlineState extends State<BrandChipsInline> {
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
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.darkBorderPrimary),
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
                      Container(height: 1, color: AppColors.darkBorderPrimary),
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
                          AppSpacing.hGapSm,
                          Expanded(
                            child: Text(
                              _filtered[i],
                              style: const TextStyle(
                                color: AppColors.textOnDarkPrimary,
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
        Text(
          context.l10n.event_selectBrands.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkBgSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.darkBorderPrimary),
            ),
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                color: AppColors.textOnDarkPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: context.l10n.event_searchBrandsPlaceholder,
                hintStyle: const TextStyle(
                  fontFamily: 'Space Grotesk',
                  color: AppColors.textOnDarkTertiary,
                  fontSize: 14,
                ),
                suffixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textOnDarkTertiary,
                  size: 18,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 10),
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
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.value,
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
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
