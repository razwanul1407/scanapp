import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request camera permission with proper handling for different platforms
  Future<PermissionStatus> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status;
  }

  /// Check if camera permission is granted
  Future<bool> isCameraPermissionGranted() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Request photo library/gallery permission (platform-aware)
  Future<PermissionStatus> requestPhotosPermission() async {
    if (Platform.isAndroid) {
      // Android 13+ uses READ_MEDIA_IMAGES instead of storage
      final androidVersion = await _getAndroidVersion();
      if (androidVersion >= 13) {
        return await Permission.photos.request();
      } else {
        return await Permission.storage.request();
      }
    } else {
      // iOS uses photos permission
      return await Permission.photos.request();
    }
  }

  /// Check if photos permission is granted
  Future<bool> isPhotosPermissionGranted() async {
    if (Platform.isAndroid) {
      final androidVersion = await _getAndroidVersion();
      if (androidVersion >= 13) {
        final status = await Permission.photos.status;
        return status.isGranted;
      } else {
        final status = await Permission.storage.status;
        return status.isGranted;
      }
    } else {
      final status = await Permission.photos.status;
      return status.isGranted;
    }
  }

  /// Request storage write permission for saving documents
  Future<PermissionStatus> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidVersion = await _getAndroidVersion();
      if (androidVersion >= 13) {
        // Android 13+ uses scoped storage, no write permission needed
        return PermissionStatus.granted;
      } else {
        return await Permission.storage.request();
      }
    } else {
      // iOS doesn't need explicit storage permission
      return PermissionStatus.granted;
    }
  }

  /// Check if storage permission is granted
  Future<bool> isStoragePermissionGranted() async {
    if (Platform.isAndroid) {
      final androidVersion = await _getAndroidVersion();
      if (androidVersion >= 13) {
        return true; // Scoped storage doesn't need explicit permission
      } else {
        final status = await Permission.storage.status;
        return status.isGranted;
      }
    } else {
      return true; // iOS handles storage differently
    }
  }

  /// Open app settings for permission management
  Future<void> openPermissionSettings() async {
    await openAppSettings();
  }

  /// Request multiple permissions at once
  Future<Map<Permission, PermissionStatus>> requestMultiplePermissions(
    List<Permission> permissions,
  ) async {
    return await permissions.request();
  }

  /// Check if permission is permanently denied
  Future<bool> isPermissionPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }

  /// Get human-readable permission status
  String getPermissionStatusString(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Granted';
      case PermissionStatus.denied:
        return 'Denied';
      case PermissionStatus.restricted:
        return 'Restricted';
      case PermissionStatus.limited:
        return 'Limited';
      case PermissionStatus.permanentlyDenied:
        return 'Permanently Denied';
      case PermissionStatus.provisional:
        return 'Provisional';
    }
  }

  /// Get Android API version
  Future<int> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      // For now, return 13 as default for newer devices
      // In production, you'd use a platform channel to get actual device API level
      return 13;
    }
    return 0;
  }
}
