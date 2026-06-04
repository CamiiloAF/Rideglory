import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/profile/presentation/cubits/edit_profile_cubit.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_edit_avatar.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_form_section_header.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.user});

  final UserModel user;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormBuilderState>();
  late final EditProfileCubit _editCubit;

  @override
  void initState() {
    super.initState();
    _editCubit = GetIt.instance<EditProfileCubit>();
    _editCubit.notifyEditStarted();
  }

  void _save() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      _editCubit.notifyEditSucceeded();
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
              ProfileEditAvatar(user: widget.user),
              AppSpacing.gapXxl,
              ProfileFormSectionHeader(label: context.l10n.profile_sectionPersonal),
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
              ProfileFormSectionHeader(label: context.l10n.profile_sectionEmergency),
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
