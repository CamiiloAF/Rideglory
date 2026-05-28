import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../../../core/exceptions/domain_exception.dart';
import '../../../../core/l10n/rideglory_l10n.dart';
import '../../domain/models/soat_extraction.dart';
import '../../domain/models/soat_scan_result.dart';
import '../../domain/usecases/scan_soat_usecase.dart';

/// Drives the intermediate scan screen: scan → process → deliver.
///
/// A single async result, so it extends `Cubit<ResultState<SoatExtraction>>`
/// directly per the coding standards.
@injectable
class SoatScanCubit extends Cubit<ResultState<SoatExtraction>> {
  SoatScanCubit(this._scanSoat) : super(const ResultState.initial());

  final ScanSoatUseCase _scanSoat;

  Future<void> scan({
    required File file,
    required SoatScanSource source,
  }) async {
    emit(const ResultState.loading());
    try {
      final result = await _scanSoat(file: file, source: source);
      emit(ResultState.data(data: result.extraction));
    } on SoatScanException catch (exception) {
      emit(
        ResultState.error(
          error: DomainException(message: _messageFor(exception.reason)),
        ),
      );
    } catch (_) {
      emit(
        ResultState.error(
          error: DomainException(
            message: _messageFor(SoatScanFailureReason.unknownError),
          ),
        ),
      );
    }
  }

  String _messageFor(SoatScanFailureReason reason) {
    final l10n = RidegloryL10n.current;
    switch (reason) {
      case SoatScanFailureReason.permissionDenied:
        return l10n.soat_scan_error_permission;
      case SoatScanFailureReason.noTextDetected:
      case SoatScanFailureReason.lowConfidence:
      case SoatScanFailureReason.validationFailed:
      case SoatScanFailureReason.unknownError:
        return l10n.soat_scan_error_unreadable;
    }
  }
}
