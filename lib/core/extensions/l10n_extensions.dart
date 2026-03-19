import 'package:flutter/widgets.dart';
import 'package:rideglory/l10n/app_localizations.dart';

extension RidegloryL10nExtension on BuildContext {
  AppLocalizations get l10n {
    final l10n = AppLocalizations.of(this);
    assert(
      l10n != null,
      '`context.l10n` was used before `MaterialApp`/`CupertinoApp` inserted '
      '`Localizations` into the widget tree.',
    );
    return l10n!;
  }

  AppLocalizations? get l10nOrNull => AppLocalizations.of(this);
}

