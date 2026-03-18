import 'package:flutter/widgets.dart';
import 'package:rideglory/l10n/app_localizations.dart';

extension RidegloryL10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

