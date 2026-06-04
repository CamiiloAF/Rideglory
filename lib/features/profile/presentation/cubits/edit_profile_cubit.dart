import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';

/// Cubit de ciclo de vida para la edición de perfil.
///
/// No gestiona estado complejo (la edición real es un formulario local que
/// devuelve data al pop). Su responsabilidad es instrumentar los hitos
/// [profile_edit_started] y [profile_edit_succeeded] sin PII.
@injectable
class EditProfileCubit extends Cubit<void> {
  EditProfileCubit(this._analytics) : super(null);

  final AnalyticsService _analytics;

  /// Llamar al abrir la pantalla de edición (initState / didChangeDependencies).
  void notifyEditStarted() {
    _analytics.logEvent(AnalyticsEvents.profileEditStarted).ignore();
  }

  /// Llamar tras confirmar el guardado exitoso del perfil.
  void notifyEditSucceeded() {
    _analytics.logEvent(AnalyticsEvents.profileEditSucceeded).ignore();
  }
}
