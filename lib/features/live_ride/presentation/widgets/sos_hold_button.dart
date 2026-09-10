import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import 'internal/sos_hold_progress_painter.dart';

/// LV3: botón de "mantener pulsado 1,5 s" para enviar el SOS — nunca un
/// tap simple, para que no se dispare por accidente con guantes. Llama
/// [onConfirmed] solo si el pulsado dura al menos [holdDuration]; si se
/// suelta antes, el progreso se reinicia sin efecto.
///
/// Pencil: IZNg5 (dentro de k4dms)
class SosHoldButton extends StatefulWidget {
  const SosHoldButton({
    required this.onConfirmed,
    super.key,
    this.holdDuration = const Duration(milliseconds: 1500),
  });

  final VoidCallback onConfirmed;
  final Duration holdDuration;

  @override
  State<SosHoldButton> createState() => _SosHoldButtonState();
}

class _SosHoldButtonState extends State<SosHoldButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    )..addStatusListener(_onStatusChanged);
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_fired) {
      _fired = true;
      HapticFeedback.heavyImpact();
      widget.onConfirmed();
    }
  }

  void _onHoldStart(LongPressStartDetails details) {
    _fired = false;
    _controller.forward(from: 0);
  }

  void _onHoldEnd(LongPressEndDetails details) {
    if (!_fired) _controller.reverse();
  }

  void _onHoldCancel() {
    if (!_fired) _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onLongPressStart: _onHoldStart,
      onLongPressEnd: _onHoldEnd,
      onLongPressCancel: _onHoldCancel,
      child: SizedBox(
        width: 168,
        height: 168,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => CustomPaint(
                size: const Size(168, 168),
                painter: SosHoldProgressPainter(
                  progress: _controller.value,
                  trackColor: colors.errorSoft,
                  progressColor: colors.errorSolid,
                ),
              ),
            ),
            Container(
              width: 136,
              height: 136,
              decoration: BoxDecoration(
                color: colors.errorSolid,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.siren, size: 30, color: colors.onBlock),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 96,
                    child: Text(
                      context.l10n.sos_confirm_hold_label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: colors.onBlock,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
