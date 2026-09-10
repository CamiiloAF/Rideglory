import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../destination_suggestion.dart';
import '../events_repository.dart';

@injectable
class SearchDestinationsUseCase {
  const SearchDestinationsUseCase(this._repository);

  final EventsRepository _repository;

  Future<Either<DomainException, List<DestinationSuggestion>>> call(
    String query,
  ) => _repository.searchDestinations(query);
}
