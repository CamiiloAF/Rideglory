import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

/// Inicializa el contenedor de DI. Los cubits se resuelven en el árbol vía
/// `BlocProvider(create: (_) => getIt<XCubit>())`, nunca leídos con `getIt`
/// directamente desde un widget (única excepción: `AuthCubit`, por el
/// router).
@InjectableInit()
Future<void> configureDependencies() async => getIt.init();
