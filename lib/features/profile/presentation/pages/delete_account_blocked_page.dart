import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../design_system/components/app_page_header.dart';
import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/components/app_secondary_button.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../widgets/delete_account_blocked_content.dart';

/// Paso 4 — bloqueado: el rider organiza una rodada que no ha terminado.
/// "Ver la rodada" no tiene detalle de evento en F4 todavía, así que lleva
/// a la pestaña Eventos (decisión de F4, documentada en el informe).
///
/// Pencil: XryZO
class DeleteAccountBlockedPage extends StatelessWidget {
  const DeleteAccountBlockedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppPageHeader(title: context.l10n.profile_delete_step1_title),
      body: Column(
        children: [
          const Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: DeleteAccountBlockedContent(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              children: [
                AppPrimaryButton(
                  label: context.l10n.profile_delete_blocked_view_event,
                  onPressed: () => context.pushNamed(AppRoutes.events),
                ),
                const SizedBox(height: 10),
                AppSecondaryButton(
                  label: context.l10n.profile_delete_blocked_back_to_profile,
                  onPressed: () => context.pushNamed(AppRoutes.profile),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
