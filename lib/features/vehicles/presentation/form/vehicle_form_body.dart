import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/features/vehicles/presentation/form/widgets/vehicle_form_basic_section.dart';
import 'package:rideglory/features/vehicles/presentation/form/widgets/vehicle_form_cover_section.dart';
import 'package:rideglory/features/vehicles/presentation/form/widgets/vehicle_form_cta.dart';
import 'package:rideglory/features/vehicles/presentation/form/widgets/vehicle_form_docs_section.dart';
import 'package:rideglory/features/vehicles/presentation/form/widgets/vehicle_form_id_section.dart';
import 'package:rideglory/features/vehicles/presentation/form/widgets/vehicle_form_specs_section.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleFormBody extends StatelessWidget {
  const VehicleFormBody({
    super.key,
    required this.formKey,
    required this.initialValue,
    required this.onSave,
    required this.onDelete,
  });

  final GlobalKey<FormBuilderState> formKey;
  final Map<String, dynamic> initialValue;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUnfocus,
      initialValue: initialValue,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const VehicleFormCoverSection(),
            // const SizedBox(height: 16),
            // const VehicleScanBanner(),
            const SizedBox(height: 24),
            const VehicleFormBasicSection(),
            const SizedBox(height: 24),
            const Divider(height: 1, color: AppColors.darkBorderPrimary),
            const SizedBox(height: 24),
            const VehicleFormIdSection(),
            const SizedBox(height: 24),
            const Divider(height: 1, color: AppColors.darkBorderPrimary),
            const SizedBox(height: 24),
            const VehicleFormSpecsSection(),
            const SizedBox(height: 24),
            const Divider(height: 1, color: AppColors.darkBorderPrimary),
            const SizedBox(height: 24),
            const VehicleFormDocsSection(),
            const SizedBox(height: 24),
            VehicleFormCta(onSave: onSave, onDelete: onDelete),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
