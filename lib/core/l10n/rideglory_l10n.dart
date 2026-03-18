import 'package:flutter/widgets.dart';
import 'package:rideglory/l10n/app_localizations.dart';

/// Global l10n access for non-UI code (cubits/services).
///
/// Prefer `context.l10n` in widgets. Use this only when you don't have
/// a `BuildContext`.
class RidegloryL10n {
  RidegloryL10n._();

  // The app currently supports only `es`, but keeping this configurable makes
  // it easy to extend later without changing call sites.
  static Locale _locale = const Locale('es');
  static AppLocalizations _l10n = lookupAppLocalizations(_locale);

  static AppLocalizations get current => _l10n;

  static void setLocale(Locale locale) {
    _locale = locale;
    _l10n = lookupAppLocalizations(_locale);
  }
}

