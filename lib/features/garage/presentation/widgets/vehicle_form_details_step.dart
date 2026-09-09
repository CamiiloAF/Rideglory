import 'package:flutter/material.dart';

import 'vehicle_brand_field.dart';
import 'vehicle_form_plate_chip.dart';
import 'vehicle_form_submit_button.dart';
import 'vehicle_mileage_field.dart';
import 'vehicle_model_field.dart';
import 'vehicle_photo_picker_row.dart';
import 'vehicle_year_engine_row.dart';

/// Paso 2 del alta: ficha de la moto (marca, línea, año, cilindraje,
/// kilometraje y foto opcional).
///
/// Pencil: e0fmR, M2i66X, sH7QQ
class VehicleFormDetailsStep extends StatelessWidget {
  const VehicleFormDetailsStep({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 6, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VehicleFormPlateChip(),
          SizedBox(height: 18),
          VehicleBrandField(),
          SizedBox(height: 14),
          VehicleModelField(),
          SizedBox(height: 14),
          VehicleYearEngineRow(),
          SizedBox(height: 14),
          VehicleMileageField(),
          SizedBox(height: 14),
          VehiclePhotoPickerRow(),
          SizedBox(height: 24),
          VehicleFormSubmitButton(),
        ],
      ),
    );
  }
}
