import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/http/api_routes.dart';
import 'package:rideglory/features/event_registration/data/dto/event_registration_dto.dart';

@singleton
class RegistrationService {
  RegistrationService(this._dio);

  final Dio _dio;

  Future<EventRegistrationDto> create({
    required String eventId,
    required Map<String, dynamic> body,
    bool saveToProfile = false,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiRoutes.eventRegistrations(eventId),
      data: {...body, 'saveToProfile': saveToProfile},
    );
    return EventRegistrationDto.fromJson(response.data!);
  }

  Future<EventRegistrationDto> update({
    required String registrationId,
    required Map<String, dynamic> body,
    bool saveToProfile = false,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiRoutes.registration(registrationId),
      data: {...body, 'saveToProfile': saveToProfile},
    );
    return EventRegistrationDto.fromJson(response.data!);
  }

  Future<void> cancel(String registrationId) async {
    await _dio.post<void>(ApiRoutes.cancelRegistration(registrationId));
  }

  Future<EventRegistrationDto> approve(String registrationId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiRoutes.approveRegistration(registrationId),
    );
    return EventRegistrationDto.fromJson(response.data!);
  }

  Future<EventRegistrationDto> reject(String registrationId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiRoutes.rejectRegistration(registrationId),
    );
    return EventRegistrationDto.fromJson(response.data!);
  }

  Future<EventRegistrationDto> setReadyForEdit(String registrationId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiRoutes.setRegistrationReadyForEdit(registrationId),
    );
    return EventRegistrationDto.fromJson(response.data!);
  }

  Future<List<EventRegistrationDto>> findByEvent(String eventId) async {
    final response = await _dio.get<List<dynamic>>(
      ApiRoutes.eventRegistrations(eventId),
    );
    return _parseList(response.data);
  }

  Future<EventRegistrationDto?> findMyRegistrationForEvent(
    String eventId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>?>(
      ApiRoutes.myRegistrationForEvent(eventId),
    );
    final data = response.data;
    if (data == null || data.isEmpty) return null;
    return EventRegistrationDto.fromJson(data);
  }

  Future<List<EventRegistrationDto>> findMyRegistrations() async {
    final response = await _dio.get<List<dynamic>>(ApiRoutes.myRegistrations);
    return _parseList(response.data);
  }

  List<EventRegistrationDto> _parseList(List<dynamic>? rows) {
    final source = rows ?? const <dynamic>[];
    return source
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .map(EventRegistrationDto.fromJson)
        .toList();
  }
}
