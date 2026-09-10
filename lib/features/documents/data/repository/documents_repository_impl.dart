import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../../domain/models/vehicle_document.dart';
import '../../domain/models/vehicle_documents_summary.dart';
import '../../domain/repository/documents_repository.dart';
import '../datasources/documents_remote_datasource.dart';
import '../services/document_local_cache_service.dart';
import '../services/document_reminder_scheduler.dart';

@Injectable(as: DocumentsRepository)
class DocumentsRepositoryImpl implements DocumentsRepository {
  DocumentsRepositoryImpl(
    this._datasource,
    this._localCache,
    this._connectivity,
    this._reminderScheduler,
  );

  final DocumentsRemoteDatasource _datasource;
  final DocumentLocalCacheService _localCache;
  final Connectivity _connectivity;
  final DocumentReminderScheduler _reminderScheduler;

  /// Mensaje interno (no se muestra crudo en la UI) que la vista del
  /// documento usa para distinguir "sin conexión y sin copia local" de un
  /// error genérico.
  static const String offlineNoCacheMessage = 'offline_no_cache';
  static const String notFoundMessage = 'not_found';

  @override
  Future<Either<DomainException, VehicleDocumentsSummary>> getDocuments(
    String vehicleId,
  ) async {
    try {
      final dtos = await _datasource.fetchDocuments(vehicleId);
      VehicleDocument? soat;
      VehicleDocument? rtm;
      for (final dto in dtos) {
        final document = dto.toDomain();
        if (document.kind == DocumentKind.soat) {
          soat = document;
        } else {
          rtm = document;
        }
      }
      return Right(VehicleDocumentsSummary(soat: soat, rtm: rtm));
    } catch (error) {
      return Left(_mapError(error));
    }
  }

  @override
  Future<Either<DomainException, VehicleDocument>> uploadDocument(
    String vehicleId,
    DocumentUploadInput input,
  ) async {
    try {
      final kindName = input.kind.name;
      final filePath = await _datasource.uploadFile(
        vehicleId: vehicleId,
        kind: kindName,
        bytes: input.fileBytes,
        extension: input.fileExtension,
      );
      final dto = await _datasource.upsertDocument(vehicleId, kindName, {
        'number': input.number,
        'issuer': input.issuer,
        'start_date': input.startDate?.toIso8601String(),
        'expiry_date': input.expiryDate.toIso8601String(),
        'file_path': filePath,
        'reminder_enabled': true,
      });
      await _localCache.save(
        vehicleId,
        input.kind,
        input.fileExtension,
        input.fileBytes,
      );
      return Right(dto.toDomain());
    } catch (error) {
      return Left(_mapError(error));
    }
  }

  @override
  Future<Either<DomainException, Unit>> deleteDocument(
    String vehicleId,
    DocumentKind kind,
  ) async {
    try {
      await _datasource.deleteDocument(vehicleId, kind.name);
      await _localCache.delete(vehicleId, kind);
      await _reminderScheduler.cancelForDocument(vehicleId, kind);
      return const Right(unit);
    } catch (error) {
      return Left(_mapError(error));
    }
  }

  @override
  Future<Either<DomainException, Unit>> deleteAllForVehicle(
    String vehicleId,
  ) async {
    try {
      await _datasource.deleteAllFilesForVehicle(vehicleId);
      await _localCache.deleteAllForVehicle(vehicleId);
      await _reminderScheduler.cancelAllForVehicle(vehicleId);
      return const Right(unit);
    } catch (error) {
      return Left(_mapError(error));
    }
  }

  @override
  Future<Either<DomainException, Unit>> cancelRemindersForVehicle(
    String vehicleId,
  ) async {
    try {
      await _reminderScheduler.cancelAllForVehicle(vehicleId);
      return const Right(unit);
    } catch (error) {
      return Left(_mapError(error));
    }
  }

  @override
  Future<Either<DomainException, Unit>> setReminderEnabled(
    String vehicleId,
    DocumentKind kind,
    bool enabled,
  ) async {
    try {
      await _datasource.setReminderEnabled(vehicleId, kind.name, enabled);
      return const Right(unit);
    } catch (error) {
      return Left(_mapError(error));
    }
  }

  @override
  Future<Either<DomainException, Uint8List>> getDocumentBytes(
    String vehicleId,
    DocumentKind kind,
  ) async {
    try {
      final cached = await _localCache.find(vehicleId, kind);
      if (cached != null) return Right(await cached.readAsBytes());

      final connectivityResults = await _connectivity.checkConnectivity();
      final isOffline =
          connectivityResults.isEmpty ||
          connectivityResults.every(
            (result) => result == ConnectivityResult.none,
          );
      if (isOffline) {
        return const Left(DomainException(message: offlineNoCacheMessage));
      }

      final dtos = await _datasource.fetchDocuments(vehicleId);
      final match = dtos.where((dto) => dto.kind == kind.name).toList();
      if (match.isEmpty || match.first.filePath == null) {
        return const Left(DomainException(message: notFoundMessage));
      }
      final filePath = match.first.filePath!;
      final bytes = await _datasource.downloadFile(filePath);
      final extension = filePath.split('.').last;
      await _localCache.save(vehicleId, kind, extension, bytes);
      return Right(bytes);
    } catch (error) {
      return Left(_mapError(error));
    }
  }

  DomainException _mapError(Object error) =>
      DomainException(message: error.toString());
}
