import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_secondary_button.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/delete_account_summary.dart';
import '../cubit/delete_account_cubit.dart';
import '../cubit/delete_account_state.dart';
import 'delete_account_destructive_button.dart';

/// Paso 2 — hoja de confirmación: casilla "entiendo que no se puede
/// recuperar" y el botón final de borrado. Cierra sola al iniciarse el
/// borrado (la página escucha `DeleteAccountCubit` y navega).
///
/// Pencil: H69H3
class DeleteConfirmSheet extends StatefulWidget {
  const DeleteConfirmSheet({required this.summary, super.key});

  final DeleteAccountSummary summary;

  @override
  State<DeleteConfirmSheet> createState() => _DeleteConfirmSheetState();
}

class _DeleteConfirmSheetState extends State<DeleteConfirmSheet> {
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return BlocListener<DeleteAccountCubit, DeleteAccountState>(
      listener: (context, state) {
        if (state is! DeleteAccountInitial) {
          Navigator.of(context).maybePop();
        }
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          26 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Text(
              context.l10n.profile_delete_confirm_title,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.profile_delete_confirm_body(
                widget.summary.vehicleCount,
                widget.summary.maintenanceCount,
                widget.summary.documentCount,
              ),
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => setState(() => _understood = !_understood),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.errorSolid, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _understood
                            ? colors.errorSolid
                            : Colors.transparent,
                        border: Border.all(color: colors.errorSolid),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      alignment: Alignment.center,
                      child: _understood
                          ? Icon(
                              LucideIcons.check,
                              size: 16,
                              color: colors.onBlock,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.profile_delete_confirm_checkbox,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: colors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            DeleteAccountDestructiveButton(
              label: context.l10n.profile_delete_confirm_button,
              onPressed: _understood
                  ? () => context.read<DeleteAccountCubit>().confirm()
                  : null,
            ),
            const SizedBox(height: 10),
            AppSecondaryButton(
              label: context.l10n.profile_delete_confirm_cancel,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}
