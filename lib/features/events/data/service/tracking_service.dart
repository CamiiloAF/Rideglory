import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/http/api_routes.dart';
import 'package:rideglory/features/events/data/dto/rider_tracking_dto.dart';

@singleton
class TrackingService {
  TrackingService(this._dio);

  final Dio _dio;

  Future<void> startSession({
    required String eventId,
    required RiderTrackingDto rider,
  }) async {
    await _dio.post<void>(
      ApiRoutes.eventTrackingStartSession(eventId),
      data: {'rider': rider.toJson()},
    );
  }

  Future<void> stopSession({
    required String eventId,
    required String userId,
  }) async {
    await _dio.post<void>(
      ApiRoutes.eventTrackingStopSession(eventId),
      data: {'userId': userId},
    );
  }

  Future<List<RiderTrackingDto>> snapshot(String eventId) async {
    final response = await _dio.get<List<dynamic>>(
      ApiRoutes.eventTrackingSnapshot(eventId),
    );
    final rows = response.data ?? <dynamic>[];
    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .map((row) => RiderTrackingDto.fromJson(row))
        .toList();
  }
}
