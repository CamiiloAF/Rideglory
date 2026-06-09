import 'package:rideglory/core/exceptions/domain_exception.dart';

/// The daily quota for this user has been exhausted.
class AiQuotaExceededUserException extends DomainException {
  const AiQuotaExceededUserException({required super.message});
}

/// The project-level (API key) quota has been exhausted.
class AiQuotaExceededProjectException extends DomainException {
  const AiQuotaExceededProjectException({required super.message});
}

/// The Gemini API blocked the request due to safety filters.
class AiSafetyBlockedException extends DomainException {
  const AiSafetyBlockedException({required super.message});
}

/// A network or unexpected error occurred while calling the AI endpoint.
class AiNetworkErrorException extends DomainException {
  const AiNetworkErrorException({required super.message});
}
