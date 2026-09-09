import 'package:flutter/material.dart';

import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Bienvenida mínima de F3, sin diseño aprobado todavía (D3 lo define en
/// F1/F4 como L2, con Google, Apple y correo en la misma pantalla).
///
/// Aquí solo hay un botón deshabilitado como ancla de la ruta `/welcome`.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.l10n.welcome_title,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.welcome_subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colors.textSecondary),
              ),
              const SizedBox(height: 32),
              AppPrimaryButton(
                label: context.l10n.welcome_continue_email,
                onPressed: null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
