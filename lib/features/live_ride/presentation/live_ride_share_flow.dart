import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/l10n_extensions.dart';
import 'cubit/live_ride_cubit.dart';
import 'domain_location_permission_check.dart';
import 'widgets/live_ride_consent_always_sheet.dart';
import 'widgets/live_ride_consent_sheet.dart';

/// D21, orden obligatorio: LV2 (consentimiento propio) → diálogo del
/// sistema (`whileInUse`) → `startSharing` → LV2b (consentimiento propio
/// para "todo el tiempo") → diálogo del sistema (`always`). Si el rider
/// niega el permiso en LV2, o el segundo paso en LV2b, sigue compartiendo
/// mientras la app esté abierta (D21) — nunca se llama dos veces al
/// diálogo del sistema sin haber mostrado antes el aviso propio.
Future<void> startLiveRideSharingFlow(
  BuildContext context,
  String eventId,
) async {
  final cubit = context.read<LiveRideCubit>();

  final allowedWhileInUse = await LiveRideConsentSheet.show(context);
  if (!allowedWhileInUse) return;

  final permission = await cubit.requestWhileInUsePermission();
  if (!isLiveRideLocationGranted(permission)) return;

  if (!context.mounted) return;
  await cubit.startSharing(
    notificationTitle: context.l10n.live_notification_title,
    notificationBody: context.l10n.live_notification_body,
    stopButtonLabel: context.l10n.live_notification_stop_button,
  );

  if (!context.mounted) return;
  if (!isLiveRideLocationAlways(permission)) {
    final allowedAlways = await LiveRideConsentAlwaysSheet.show(context);
    if (allowedAlways) {
      await cubit.requestAlwaysPermission();
    }
  }
}
