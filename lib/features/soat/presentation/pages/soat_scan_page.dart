import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/soat/domain/models/soat_extraction.dart';
import 'package:rideglory/features/soat/presentation/cubit/soat_scan_cubit.dart';
import 'package:rideglory/features/soat/presentation/pages/soat_scan_params.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_scan_loader.dart';

/// Intermediate screen that runs OCR + parsing on the picked document and
/// returns a [SoatExtraction] to the caller.
///
/// On success it pops with the extraction; on failure it pops with `null`
/// (the caller falls back silently to the manual flow with a toast).
class SoatScanPage extends StatelessWidget {
  const SoatScanPage({super.key, required this.params});

  final SoatScanParams params;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<SoatScanCubit>()
            ..scan(file: File(params.filePath), source: params.source),
      child: const _SoatScanView(),
    );
  }
}

class _SoatScanView extends StatelessWidget {
  const _SoatScanView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      body: SafeArea(
        child: BlocConsumer<SoatScanCubit, ResultState<SoatExtraction>>(
          listener: (context, state) {
            state.whenOrNull(
              data: (extraction) => context.pop<SoatExtraction>(extraction),
              error: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.warning,
                    content: Text(
                      error.message,
                      style: const TextStyle(
                        color: AppColors.darkBgPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
                context.pop<SoatExtraction>();
              },
            );
          },
          builder: (context, state) => const SoatScanLoader(),
        ),
      ),
    );
  }
}
