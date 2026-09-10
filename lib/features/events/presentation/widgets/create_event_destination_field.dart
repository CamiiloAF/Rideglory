import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/domain/result_state.dart';
import '../../../../design_system/components/app_text_field.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_radii.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/destination_suggestion.dart';
import '../cubit/create_event_cubit.dart';

/// Buscador de destino sin mapa interactivo (D10): Nominatim/OpenStreetMap.
class CreateEventDestinationField extends StatefulWidget {
  const CreateEventDestinationField({
    required this.query,
    required this.results,
    required this.cubit,
    super.key,
  });

  final String query;
  final ResultState<List<DestinationSuggestion>> results;
  final CreateEventCubit cubit;

  @override
  State<CreateEventDestinationField> createState() =>
      _CreateEventDestinationFieldState();
}

class _CreateEventDestinationFieldState
    extends State<CreateEventDestinationField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.query,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final suggestions =
        widget.results.whenOrNull(data: (data) => data) ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: context.l10n.events_create_destination_label,
          controller: _controller,
          icon: LucideIcons.search,
          helperText: context.l10n.events_create_destination_hint,
          onChanged: widget.cubit.updateDestinationQuery,
        ),
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: colors.borderStrong),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final suggestion in suggestions)
                  ListTile(
                    dense: true,
                    title: Text(
                      suggestion.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.text, fontSize: 13),
                    ),
                    onTap: () {
                      widget.cubit.selectDestination(suggestion);
                      _controller.text = suggestion.displayName;
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
