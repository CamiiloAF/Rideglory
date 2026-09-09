import 'package:flutter/material.dart';

import '../../domain/models/vehicle.dart';
import 'vehicle_archive_button.dart';
import 'vehicle_brand_field.dart';
import 'vehicle_delete_button.dart';
import 'vehicle_documents_section.dart';
import 'vehicle_form_submit_button.dart';
import 'vehicle_mileage_field.dart';
import 'vehicle_model_field.dart';
import 'vehicle_photo_picker_row.dart';
import 'vehicle_principal_switch_row.dart';
import 'vehicle_year_engine_row.dart';

/// Cuerpo de la ficha de edición: foto, identidad, ficha técnica,
/// kilometraje, documentos, principal y eliminar/archivar.
///
/// Pencil: tbZKM
class VehicleEditBody extends StatelessWidget {
  const VehicleEditBody({required this.vehicle, super.key});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const VehiclePhotoPickerRow(),
          const SizedBox(height: 18),
          const VehicleBrandField(),
          const SizedBox(height: 14),
          const VehicleModelField(),
          const SizedBox(height: 14),
          const VehicleYearEngineRow(),
          const SizedBox(height: 14),
          const VehicleMileageField(isEditing: true),
          const SizedBox(height: 18),
          VehicleDocumentsSection(vehicleId: vehicle.id),
          const SizedBox(height: 18),
          const VehiclePrincipalSwitchRow(),
          const SizedBox(height: 24),
          const VehicleFormSubmitButton(),
          const SizedBox(height: 12),
          VehicleArchiveButton(vehicle: vehicle),
          const SizedBox(height: 10),
          const VehicleDeleteButton(),
        ],
      ),
    );
  }
}
