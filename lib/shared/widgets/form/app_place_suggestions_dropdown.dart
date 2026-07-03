import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/core/services/dto/place_suggestion_dto.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/search_skeleton_list.dart';

class AppPlaceSuggestionsDropdown extends StatelessWidget {
  const AppPlaceSuggestionsDropdown({
    super.key,
    required this.suggestions,
    required this.isLoading,
    required this.hasError,
    required this.onSelect,
  });

  final List<PlaceSuggestionDto> suggestions;
  final bool isLoading;
  final bool hasError;
  final void Function(PlaceSuggestionDto) onSelect;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildContainer(child: const SearchSkeletonList());
    }

    if (hasError) {
      return _buildContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            context.l10n.route_placeSearchError,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          ),
        ),
      );
    }

    if (suggestions.isEmpty) {
      return _buildContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            context.l10n.route_noPlacesFound,
            style: const TextStyle(
              color: AppColors.textOnDarkTertiary,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return _buildContainer(
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: suggestions.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: AppColors.darkBorderPrimary),
        itemBuilder: (_, i) {
          final suggestion = suggestions[i];
          return GestureDetector(
            onTap: () => onSelect(suggestion),
            child: Container(
              decoration: i == 0
                  ? const BoxDecoration(
                      color: AppColors.darkActiveSuggestion,
                      border: Border(
                        left: BorderSide(color: AppColors.primary, width: 4),
                      ),
                    )
                  : const BoxDecoration(color: AppColors.darkCard),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: i == 0
                        ? AppColors.primary
                        : AppColors.textOnDarkTertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion.name,
                      style: TextStyle(
                        color: i == 0
                            ? AppColors.textOnDarkPrimary
                            : AppColors.textOnDarkSecondary,
                        fontSize: 13,
                        fontWeight: i == 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          border: Border.all(color: AppColors.darkBorderPrimary),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
