import 'package:dartz/dartz.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';

abstract class EventCoverRepository {
  Future<Either<DomainException, String>> generateCover({
    required String title,
    required String eventType,
    required String city,
  });
}
