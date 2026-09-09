import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/domain/result_state.dart';
import '../../../../design_system/components/app_page_header.dart';
import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/components/app_text_field.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/blood_type.dart';
import '../../domain/profile.dart';
import '../cubit/save_profile_cubit.dart';
import '../widgets/blood_type_field.dart';

/// Edición del perfil. Sin frame propio en el `.pen` (P2 solo diseñó el
/// chevron de entrada): reutiliza `AppTextField`/`AppPrimaryButton` con el
/// mismo lenguaje visual del resto de la app (decisión de F4).
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({required this.initialProfile, super.key});

  final Profile initialProfile;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final _nameController = TextEditingController(
    text: widget.initialProfile.fullName,
  );
  late final _phoneController = TextEditingController(
    text: widget.initialProfile.phone,
  );
  late final _cityController = TextEditingController(
    text: widget.initialProfile.residenceCity,
  );
  late final _epsController = TextEditingController(
    text: widget.initialProfile.eps,
  );
  late final _insuranceController = TextEditingController(
    text: widget.initialProfile.medicalInsurance,
  );
  late BloodType? _bloodType = widget.initialProfile.bloodType;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _epsController.dispose();
    _insuranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SaveProfileCubit>(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppPageHeader(title: context.l10n.profile_edit_title),
            body: BlocConsumer<SaveProfileCubit, ResultState<Unit>>(
              listener: (context, state) {
                state.whenOrNull(
                  data: (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.profile_update_success),
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  error: (error) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.profile_update_error)),
                  ),
                );
              },
              builder: (context, state) {
                final isLoading = state is Loading;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        label: context.l10n.profile_field_name,
                        controller: _nameController,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: context.l10n.profile_field_phone,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: context.l10n.profile_field_city,
                        controller: _cityController,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: context.l10n.profile_field_eps,
                        controller: _epsController,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: context.l10n.profile_field_insurance,
                        controller: _insuranceController,
                      ),
                      const SizedBox(height: 14),
                      BloodTypeField(
                        value: _bloodType,
                        onChanged: (value) =>
                            setState(() => _bloodType = value),
                      ),
                      const SizedBox(height: 32),
                      AppPrimaryButton(
                        label: context.l10n.profile_save_button,
                        onPressed: isLoading
                            ? null
                            : () => context.read<SaveProfileCubit>().save(
                                fullName: _nameController.text.trim(),
                                phone: _phoneController.text.trim(),
                                residenceCity: _cityController.text.trim(),
                                eps: _epsController.text.trim(),
                                medicalInsurance: _insuranceController.text
                                    .trim(),
                                bloodType: _bloodType,
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
