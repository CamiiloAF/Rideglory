import '../../../core/exceptions/domain_exception.dart';
import '../domain/profile_error_code.dart';

DomainException mapProfileError(Object error) {
  final text = error.toString().toLowerCase();
  if (text.contains('socketexception') || text.contains('failed host lookup')) {
    return const DomainException(message: ProfileErrorCode.offline);
  }
  return const DomainException(message: ProfileErrorCode.unknown);
}
