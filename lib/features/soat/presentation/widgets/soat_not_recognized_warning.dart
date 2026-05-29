import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Aviso informativo (no bloqueante) que se muestra debajo del documento cuando
/// el escaneo OCR no reconoce un SOAT. El usuario puede seguir guardando.
class SoatNotRecognizedWarning extends StatelessWidget {
  const SoatNotRecognizedWarning({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.l10n.soat_document_not_recognized,
            style: const TextStyle(
              color: AppColors.warning,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
