import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:rideglory/features/events/data/dto/ai_description_request_dto.dart';
import 'package:rideglory/features/events/data/dto/ai_description_response_dto.dart';
import 'package:rideglory/features/events/data/dto/ai_quota_response_dto.dart';

part 'ai_description_service.g.dart';

@singleton
@RestApi()
abstract class AiDescriptionService {
  @factoryMethod
  factory AiDescriptionService(Dio dio) = _AiDescriptionService;

  @GET('/ai/quota')
  Future<AiQuotaResponseDto> getQuota();

  @POST('/ai/description')
  Future<AiDescriptionResponseDto> generateDescription(
    @Body() AiDescriptionRequestDto dto,
  );
}
