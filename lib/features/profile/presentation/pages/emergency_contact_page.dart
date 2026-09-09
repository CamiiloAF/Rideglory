import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/domain/result_state.dart';
import '../../../../design_system/components/app_page_header.dart';
import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/components/app_text_field.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/save_emergency_contact_cubit.dart';
import '../widgets/emergency_info_banner.dart';

/// Contacto de emergencia: nombre, teléfono y parentesco.
///
/// Pencil: FNOK0
class EmergencyContactPage extends StatefulWidget {
  const EmergencyContactPage({super.key});

  @override
  State<EmergencyContactPage> createState() => _EmergencyContactPageState();
}

class _EmergencyContactPageState extends State<EmergencyContactPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SaveEmergencyContactCubit>(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppPageHeader(
              title: context.l10n.profile_emergency_page_title,
            ),
            body: BlocConsumer<SaveEmergencyContactCubit, ResultState<Unit>>(
              listener: (context, state) {
                state.whenOrNull(
                  data: (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.l10n.profile_emergency_save_success,
                        ),
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  error: (error) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.profile_emergency_save_error),
                    ),
                  ),
                );
              },
              builder: (context, state) {
                final isLoading = state is Loading;
                final colors = Theme.of(context).extension<AppColors>()!;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EmergencyInfoBanner(),
                      const SizedBox(height: 15),
                      AppTextField(
                        label: context.l10n.profile_emergency_field_name,
                        controller: _nameController,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: context.l10n.profile_emergency_field_phone,
                        controller: _phoneController,
                        icon: LucideIcons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label:
                            context.l10n.profile_emergency_field_relationship,
                        controller: _relationshipController,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LucideIcons.lock,
                            size: 14,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.l10n.profile_emergency_consent_note,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      AppPrimaryButton(
                        label: context.l10n.profile_emergency_save_button,
                        onPressed: isLoading
                            ? null
                            : () => context
                                  .read<SaveEmergencyContactCubit>()
                                  .save(
                                    name: _nameController.text.trim(),
                                    phone: _phoneController.text.trim(),
                                    relationship: _relationshipController.text
                                        .trim(),
                                  ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
