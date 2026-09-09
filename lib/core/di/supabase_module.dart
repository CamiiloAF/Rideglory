import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Registra el `SupabaseClient` ya inicializado (ver `main.dart`, donde se
/// llama `Supabase.initialize` antes de `configureDependencies`).
@module
abstract class SupabaseModule {
  @lazySingleton
  SupabaseClient get supabaseClient => Supabase.instance.client;
}
