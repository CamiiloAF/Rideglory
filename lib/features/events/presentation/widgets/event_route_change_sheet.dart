import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/components/app_text_field.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Hoja de cambio de ruta (EV6). Devuelve el mensaje al hacer pop cuando
/// el organizador confirma; `null` si cancela.
class EventRouteChangeSheet extends StatefulWidget {
  const EventRouteChangeSheet({required this.approvedCount, super.key});

  final int approvedCount;

  @override
  State<EventRouteChangeSheet> createState() => _EventRouteChangeSheetState();
}

class _EventRouteChangeSheetState extends State<EventRouteChangeSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 10,
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              context.l10n.events_route_change_title,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.events_route_change_body(widget.approvedCount),
              style: TextStyle(
                fontSize: 13.5,
                height: 1.35,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: context.l10n.events_route_change_field_label,
              controller: _controller,
            ),
            const SizedBox(height: 14),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) => AppPrimaryButton(
                label: context.l10n.events_route_change_cta,
                icon: LucideIcons.bellRing,
                onPressed: value.text.trim().isEmpty
                    ? null
                    : () => Navigator.of(context).pop(value.text.trim()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
