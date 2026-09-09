import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Registra la instancia de `SharedPreferences`. `@preResolve` porque
/// `getInstance()` es async y `configureDependencies()` ya se espera en
/// `main.dart` antes de `runApp`.
@module
abstract class SharedPreferencesModule {
  @preResolve
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();
}
