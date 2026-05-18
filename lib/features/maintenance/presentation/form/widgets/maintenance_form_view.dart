import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/maintenance_form_content.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/maintenance_form_nav_header.dart';

class MaintenanceFormView extends StatelessWidget {
  final MaintenanceType selectedType;
  final VoidCallback onChangeType;

  const MaintenanceFormView({
    super.key,
    required this.selectedType,
    required this.onChangeType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: MaintenanceFormNavHeader(onBack: onChangeType),
      body: MaintenanceFormContent(
        selectedType: selectedType,
        onChangeType: onChangeType,
      ),
    );
  }
}
