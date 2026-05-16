import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';
import 'package:rideglory/core/data/colombia_motos_brands_data.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_form_fields.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/vehicle_document_upload_slot.dart';

class VehicleForm extends StatelessWidget {
  const VehicleForm({
    super.key,
    this.formKey,
    this.isEditing = false,
    this.initialValue,
    this.onSave,
  });

  final GlobalKey<FormBuilderState>? formKey;
  final bool isEditing;
  final Map<String, dynamic>? initialValue;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleFormCubit, VehicleFormState>(
      builder: (context, state) {
        return FormBuilder(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUnfocus,
          initialValue: initialValue ?? const <String, dynamic>{},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _CoverPhotoSection(),
              const SizedBox(height: 16),
              const _ScanBanner(),
              const SizedBox(height: 20),
              _SectionLabel(context.l10n.vehicle_form_info_section),
              const SizedBox(height: 14),
              AppTextField(
                name: VehicleFormFields.name,
                labelText: context.l10n.vehicle_vehicleName,
                isRequired: true,
                hintText: context.l10n.vehicle_vehicleNameHint,
                textInputAction: TextInputAction.next,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: context.l10n.vehicle_nameRequired,
                  ),
                  FormBuilderValidators.minLength(
                    3,
                    errorText: context.l10n.vehicle_minCharacters,
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              AppAutocompleteField(
                name: VehicleFormFields.brand,
                labelText: context.l10n.vehicle_form_brand_label,
                isRequired: true,
                hintText: context.l10n.vehicle_vehicleBrandHint,
                suggestionsPrefixIcon: Icons.category_outlined,
                suggestions: ColombiaMotosBrandsData.search,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: context.l10n.vehicle_brandRequired,
                  ),
                  (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    const allowed = ColombiaMotosBrandsData.brands;
                    return allowed.any((b) => b == value.trim())
                        ? null
                        : context.l10n.vehicle_brandMustBeFromList;
                  },
                ]),
              ),
              const SizedBox(height: 14),
              AppTextField(
                name: VehicleFormFields.model,
                labelText: context.l10n.vehicle_form_model_label,
                hintText: context.l10n.vehicle_vehicleModelHint,
                isRequired: true,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: context.l10n.vehicle_modelRequired,
                  ),
                ]),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      name: VehicleFormFields.year,
                      labelText: context.l10n.vehicle_form_year_label,
                      isRequired: true,
                      hintText: context.l10n.vehicle_vehicleYearHint,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                          errorText: context.l10n.vehicle_yearRequired,
                        ),
                        FormBuilderValidators.numeric(
                          errorText: context.l10n.mustBeNumber,
                          checkNullOrEmpty: false,
                        ),
                        FormBuilderValidators.min(
                          1900,
                          errorText: context.l10n.vehicle_invalidYear,
                          checkNullOrEmpty: false,
                        ),
                        FormBuilderValidators.max(
                          DateTime.now().year + 2,
                          errorText: context.l10n.vehicle_invalidYear,
                          checkNullOrEmpty: false,
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      name: VehicleFormFields.color,
                      labelText: context.l10n.vehicle_form_color_label,
                      hintText: context.l10n.vehicle_form_color_hint,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppMileageField(
                name: VehicleFormFields.currentMileage,
                labelText: context.l10n.vehicle_form_km_label,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: AppColors.darkBorderPrimary),
              const SizedBox(height: 24),
              _SectionLabel(context.l10n.vehicle_form_id_section),
              const SizedBox(height: 14),
              AppTextField(
                name: VehicleFormFields.licensePlate,
                labelText: context.l10n.vehicle_form_plate_label,
                hintText: context.l10n.vehicle_vehiclePlateHint,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                name: VehicleFormFields.vin,
                labelText: context.l10n.vehicle_vehicleVin,
                hintText: context.l10n.vehicle_vehicleVinHint,
                maxLength: 17,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppDatePicker(
                fieldName: VehicleFormFields.purchaseDate,
                labelText: context.l10n.vehicle_purchaseDate,
                lastDate: DateTime.now(),
                hintText: context.l10n.vehicle_purchaseDateHint,
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: AppColors.darkBorderPrimary),
              const SizedBox(height: 24),
              const _DocumentsSection(),
              if (onSave != null) ...[
                const SizedBox(height: 24),
                BlocBuilder<VehicleFormCubit, VehicleFormState>(
                  builder: (context, state) {
                    return AppButton(
                      onPressed: onSave,
                      isLoading: state.isLoading,
                      label: isEditing
                          ? context.l10n.vehicle_form_save
                          : context.l10n.vehicle_form_save,
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnDarkTertiary,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ScanBanner extends StatelessWidget {
  const _ScanBanner();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: implement scan property card
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primarySubtle,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.document_scanner_outlined, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.vehicle_form_scan_title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnDarkPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.l10n.vehicle_form_scan_subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textOnDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _CoverPhotoSection extends StatelessWidget {
  const _CoverPhotoSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FormImageCubit, ResultState<FormImageData>>(
      builder: (context, imageState) {
        final imageData = imageState.whenOrNull(data: (data) => data);
        final hasImage = imageData?.displayImageUrl != null;
        final isLocal = imageData?.hasLocalImage == true;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: hasImage
                  ? null
                  : () => context.read<FormImageCubit>().pickImageFromGallery(),
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasImage
                        ? AppColors.darkBorderLight
                        : AppColors.darkBorderPrimary,
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: hasImage
                    ? _ImagePreview(
                        imageData: imageData!,
                        isLocal: isLocal,
                        onClear: () =>
                            context.read<FormImageCubit>().clearLocalImage(),
                      )
                    : const _EmptyCoverState(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _OutlineButton(
                    icon: Icons.upload_outlined,
                    label: context.l10n.vehicle_form_upload_btn,
                    onTap: () =>
                        context.read<FormImageCubit>().pickImageFromGallery(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OutlineButton(
                    icon: Icons.camera_alt_outlined,
                    label: context.l10n.vehicle_form_take_photo_btn,
                    onTap: () =>
                        context.read<FormImageCubit>().pickImageFromCamera(),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _EmptyCoverState extends StatelessWidget {
  const _EmptyCoverState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.camera_alt_outlined, size: 32, color: AppColors.textOnDarkTertiary),
        const SizedBox(height: 8),
        Text(
          context.l10n.vehicle_form_cover_title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textOnDarkSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.vehicle_form_cover_subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textOnDarkTertiary,
          ),
        ),
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.imageData,
    required this.isLocal,
    required this.onClear,
  });

  final FormImageData imageData;
  final bool isLocal;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        isLocal
            ? Image.file(
                File(imageData.localImagePath!),
                fit: BoxFit.cover,
              )
            : Image.network(
                imageData.remoteImageUrl!,
                fit: BoxFit.cover,
              ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.darkTertiary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.darkBorderPrimary),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.textOnDarkSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnDarkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentsSection extends StatelessWidget {
  const _DocumentsSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleFormCubit, VehicleFormState>(
      builder: (context, state) {
        final docCount =
            (state.soatLocalPath != null ? 1 : 0) +
            (state.techReviewLocalPath != null ? 1 : 0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _SectionLabel(context.l10n.vehicle_form_docs_section),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkTertiary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Opcional',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textOnDarkTertiary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '$docCount / 3',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOnDarkSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            VehicleDocumentUploadSlot(
              title: context.l10n.vehicle_doc_soat_label,
              subtitle: context.l10n.vehicle_form_soat_subtitle,
              localPath: state.soatLocalPath,
              onUploadTap: () =>
                  context.read<VehicleFormCubit>().pickSoatDocument(),
              onClear: state.soatLocalPath != null
                  ? () => context.read<VehicleFormCubit>().clearSoatDocument()
                  : null,
            ),
            const SizedBox(height: 12),
            VehicleDocumentUploadSlot(
              title: context.l10n.vehicle_doc_techreview_label,
              subtitle: context.l10n.vehicle_form_techreview_subtitle,
              localPath: state.techReviewLocalPath,
              onUploadTap: () =>
                  context.read<VehicleFormCubit>().pickTechReviewDocument(),
              onClear: state.techReviewLocalPath != null
                  ? () =>
                        context.read<VehicleFormCubit>().clearTechReviewDocument()
                  : null,
            ),
            const SizedBox(height: 12),
            const _AddMoreDocSlot(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 13,
                  color: AppColors.textOnDarkTertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.vehicle_form_docs_max_hint,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textOnDarkTertiary,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AddMoreDocSlot extends StatelessWidget {
  const _AddMoreDocSlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.darkBorderPrimary),
            ),
            child: const Icon(
              Icons.add,
              size: 20,
              color: AppColors.textOnDarkSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.vehicle_form_add_doc_title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textOnDarkSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.vehicle_form_add_doc_subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textOnDarkTertiary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.textOnDarkTertiary,
          ),
        ],
      ),
    );
  }
}
