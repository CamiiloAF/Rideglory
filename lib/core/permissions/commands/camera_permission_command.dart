import 'package:permission_handler/permission_handler.dart';

import '../../../generated/l10n.dart';
import '../../exceptions/failure.dart';
import 'permission_command.dart';

class CameraPermissionCommand implements PermissionCommand {
  @override
  Future<bool> request() async {
    final cameraPermissions = await Permission.camera.status;

    if (!cameraPermissions.isGranted) {
      final status = await Permission.camera.request();

      if (status.isDenied) {
        throw Failure(
          AppStrings.current.noCameraPermissionGranted,
        );
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }
    }
    return true;
  }
}
