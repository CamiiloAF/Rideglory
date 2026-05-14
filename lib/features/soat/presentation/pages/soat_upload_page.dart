import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_source_grid.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class SoatUploadPage extends StatelessWidget {
  const SoatUploadPage({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppBar(
        title: Text(
          context.l10n.soat_page_upload_title,
          style: const TextStyle(
            color: AppColors.textOnDarkPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.darkBgPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textOnDarkPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.soat_upload_subtitle(vehicle.name),
              style: const TextStyle(
                color: AppColors.textOnDarkSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SoatSourceGrid(vehicle: vehicle),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
