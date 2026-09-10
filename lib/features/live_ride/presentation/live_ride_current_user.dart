import 'package:supabase_flutter/supabase_flutter.dart';

/// El id del rider autenticado, para filtrar "mi" fila fuera de la lista
/// de SOS de otros (LV5) o de riders (LV1/LV6). Lectura local de la
/// sesión ya cacheada por el SDK — no es una llamada de red, así que no
/// rompe la regla de `presentation` sin I/O (mismo patrón que
/// `EventPushNavigator` accede a Firebase directamente). `null` también
/// cuando Supabase no está inicializado (tests de widgets sin backend).
String? liveRideCurrentUserId() {
  try {
    return Supabase.instance.client.auth.currentUser?.id;
  } catch (_) {
    return null;
  }
}
