import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class BrandChipsInline extends StatefulWidget {
  const BrandChipsInline({
    super.key,
    required this.brandsField,
    required this.suggestions,
  });

  final FormFieldState<List<String>> brandsField;
  final List<String> Function(String query) suggestions;

  @override
  State<BrandChipsInline> createState() => _BrandChipsInlineState();
}

class _BrandChipsInlineState extends State<BrandChipsInline> {
  static const _popular = [
    'Honda', 'Yamaha', 'Suzuki', 'Kawasaki',
    'AKT', 'Bajaj', 'KTM', 'Royal Enfield',
    'BMW Motorrad', 'Ducati', 'TVS', 'Hero',
  ];

  final _controller = TextEditingController();
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;

  @override
  void dispose() {
    _overlay?.remove();
    _controller.dispose();
    super.dispose();
  }

  List<String> get _selected => widget.brandsField.value ?? [];
  bool get _isMultiBrand => _selected.isEmpty;

  void _selectAll() {
    widget.brandsField.didChange([]);
    setState(() {});
  }

  void _toggle(String brand) {
    final current = List<String>.from(_selected);
    if (current.contains(brand)) {
      current.remove(brand);
      widget.brandsField.didChange(current);
    } else {
      current.add(brand);
      widget.brandsField.didChange(current);
    }
    setState(() {});
  }

  void _addFromSearch(String brand) {
    final current = List<String>.from(_selected);
    if (!current.contains(brand)) {
      current.add(brand);
      widget.brandsField.didChange(current);
    }
    _controller.clear();
    setState(() {});
    _overlay?.remove();
    _overlay = null;
  }

  void _onSearchChanged(String value) {
    final results = value.isEmpty
        ? <String>[]
        : widget.suggestions(value).where((b) => !_selected.contains(b)).toList();

    _overlay?.remove();
    _overlay = null;
    if (results.isEmpty) return;

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
                itemCount: results.length,
                separatorBuilder: (_, _) =>
                    Container(height: 1, color: AppColors.darkBorderPrimary),
                itemBuilder: (_, i) => InkWell(
                  onTap: () => _addFromSearch(results[i]),
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
                            results[i],
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
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final isMultiBrand = _isMultiBrand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de búsqueda
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
              onChanged: _onSearchChanged,
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
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkBorderPrimary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila "Todas las marcas"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: GestureDetector(
                  onTap: isMultiBrand ? null : _selectAll,
                  child: _BrandChip(
                    label: context.l10n.event_allBrands,
                    selected: isMultiBrand,
                    showCheckAlways: true,
                  ),
                ),
              ),
              Container(height: 1, color: AppColors.darkBorderPrimary),
              // Hint
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Text(
                  context.l10n.event_brandsActiveHint,
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 12,
                    color: AppColors.textOnDarkTertiary,
                  ),
                ),
              ),
              // Chips: populares + marcas extra seleccionadas por búsqueda
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._popular,
                    ...selected.where((b) => !_popular.contains(b)),
                  ]
                      .map(
                        (brand) => GestureDetector(
                          onTap: () => _toggle(brand),
                          child: _BrandChip(
                            label: brand,
                            selected: selected.contains(brand),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrandChip extends StatelessWidget {
  const _BrandChip({
    required this.label,
    required this.selected,
    this.showCheckAlways = false,
  });

  final String label;
  final bool selected;
  final bool showCheckAlways;

  @override
  Widget build(BuildContext context) {
    final showCheck = selected || showCheckAlways;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.primarySubtle : AppColors.darkBgSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCheck) ...[
            Icon(
              Icons.check_rounded,
              size: 13,
              color: selected ? AppColors.primary : AppColors.textOnDarkTertiary,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? AppColors.primary : AppColors.textOnDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
