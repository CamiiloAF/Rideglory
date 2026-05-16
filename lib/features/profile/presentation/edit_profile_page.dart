import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.user});

  final UserModel user;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormBuilderState>();

  void _save() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppAppBar(title: context.l10n.profile_editTitle),
      body: SafeArea(
        child: FormBuilder(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            children: [
              _ProfileEditAvatar(user: widget.user),
              AppSpacing.gapXxl,
              _SectionHeader(label: context.l10n.profile_sectionPersonal),
              AppSpacing.gapMd,
              AppTextField(
                name: 'fullName',
                labelText: context.l10n.profile_fieldFullName,
                initialValue: widget.user.fullName,
                isRequired: true,
                textInputAction: TextInputAction.next,
              ),
              AppSpacing.gapMd,
              AppTextField(
                name: 'phone',
                labelText: context.l10n.profile_fieldPhone,
                initialValue: widget.user.phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              AppSpacing.gapMd,
              AppTextField(
                name: 'residenceCity',
                labelText: context.l10n.profile_fieldCity,
                initialValue: widget.user.residenceCity,
                textInputAction: TextInputAction.next,
              ),
              AppSpacing.gapMd,
              AppTextField(
                name: 'bloodType',
                labelText: context.l10n.profile_fieldBloodType,
                initialValue: widget.user.bloodType?.name,
                textInputAction: TextInputAction.next,
              ),
              AppSpacing.gapXxl,
              _SectionHeader(label: context.l10n.profile_sectionEmergency),
              AppSpacing.gapMd,
              AppTextField(
                name: 'emergencyContactName',
                labelText: context.l10n.profile_fieldEmergencyContact,
                initialValue: widget.user.emergencyContactName,
                textInputAction: TextInputAction.next,
              ),
              AppSpacing.gapMd,
              AppTextField(
                name: 'emergencyContactPhone',
                labelText: context.l10n.profile_fieldEmergencyPhone,
                initialValue: widget.user.emergencyContactPhone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
              ),
              AppSpacing.gapXxl,
              AppButton(
                label: context.l10n.profile_editSave,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileEditAvatar extends StatelessWidget {
  const _ProfileEditAvatar({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final initials = user.fullName != null && user.fullName!.isNotEmpty
        ? user.fullName!
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join()
        : '?';

    return Center(
      child: Stack(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  Color(0x66F98C1F),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.darkCard,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnDarkPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 16,
                color: AppColors.darkBgPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnDarkSecondary,
        letterSpacing: 1.5,
      ),
    );
  }
}
