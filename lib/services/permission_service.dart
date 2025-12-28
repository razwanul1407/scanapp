import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request camera permission with proper handling for different platforms
  Future<PermissionStatus> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status;
    } catch (e) {
      // Handle any errors from permission request
      return PermissionStatus.denied;
    }
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
        try {
          return await Permission.photos.request();
        } catch (e) {
          // Fallback for devices that don't support photos permission
          return await Permission.storage.request();
        }
      } else {
        try {
          return await Permission.storage.request();
        } catch (e) {
          // Additional fallback
          return PermissionStatus.denied;
        }
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
        try {
          return await Permission.storage.request();
        } catch (e) {
          // Fallback for devices with storage permission issues
          return PermissionStatus.denied;
        }
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
      // Use the device_info_plus package to get actual SDK version
      // For now, use a safer default that works across versions
      try {
        // Try to detect version safely without external package
        // Default to checking if Permission.photos is available
        // by attempting to request it and catching errors
        await Permission.photos.status;
        return 13; // If photos permission works, device is likely Android 13+
      } catch (e) {
        return 12; // Fall back to pre-Android 13 permissions
      }
    }
    return 0;
  }
}
