import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

/// Provee un único `http.Client` para datasources que hablan con APIs
/// externas sin SDK propio (ej. Nominatim). Nunca Dio/Retrofit (CLAUDE.md).
@module
abstract class HttpModule {
  @lazySingleton
  http.Client get client => http.Client();
}
