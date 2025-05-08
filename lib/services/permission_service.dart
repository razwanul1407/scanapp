import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    return false;
  }

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
      return false;
    } else {
      final status = await Permission.photos.request();
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
      return false;
    }
  }
}
