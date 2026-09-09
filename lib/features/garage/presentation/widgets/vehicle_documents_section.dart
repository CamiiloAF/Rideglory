import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/domain/result_state.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../../shared/widgets/states/skeleton_box.dart';
import '../../../documents/domain/models/vehicle_document.dart';
import '../../../documents/domain/models/vehicle_documents_summary.dart';
import '../../../documents/presentation/cubit/vehicle_documents_cubit.dart';
import '../../../documents/presentation/widgets/document_row.dart';

/// Fila ancha de documentos (SOAT y RTM) dentro de la ficha de la moto.
///
/// Deviación documentada: no está en el frame aprobado `tbZKM` del `.pen`
/// (ver informe de cierre); se construye con el mismo `DocumentRow` que usa
/// el visor, para que estado y estilo coincidan en toda la app.
class VehicleDocumentsSection extends StatelessWidget {
  const VehicleDocumentsSection({required this.vehicleId, super.key});

  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return BlocProvider(
      create: (_) => getIt<VehicleDocumentsCubit>()..load(vehicleId),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.garage_documents_section_title,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          BlocBuilder<VehicleDocumentsCubit, ResultState<VehicleDocumentsSummary>>(
            builder: (context, state) {
              return state.when(
                initial: () => const SkeletonBox(height: 64, borderRadius: 16),
                loading: () => const SkeletonBox(height: 64, borderRadius: 16),
                empty: () => Column(
                  children: [
                    DocumentRow(vehicleId: vehicleId, kind: DocumentKind.soat),
                    const SizedBox(height: 10),
                    DocumentRow(vehicleId: vehicleId, kind: DocumentKind.rtm),
                  ],
                ),
                error: (_) => const SizedBox.shrink(),
                data: (summary) => Column(
                  children: [
                    DocumentRow(vehicleId: vehicleId, kind: DocumentKind.soat, document: summary.soat),
                    const SizedBox(height: 10),
                    DocumentRow(vehicleId: vehicleId, kind: DocumentKind.rtm, document: summary.rtm),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
