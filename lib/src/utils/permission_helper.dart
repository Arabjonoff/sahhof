import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class PermissionHelper {
  static Future<bool> requestStoragePermission(BuildContext context) async {
    // Faqat Android uchun
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      // Android versiyasini tekshirish
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      debugPrint('📱 Android SDK: $sdkInt');

      if (sdkInt >= 33) {
        // Android 13+ (API 33+)
        // Audio fayllar uchun READ_MEDIA_AUDIO kerak
        var status = await Permission.audio.status;

        debugPrint('🔐 Audio permission status: $status');

        if (!status.isGranted) {
          debugPrint('🔐 Requesting audio permission...');
          status = await Permission.audio.request();
          debugPrint('🔐 Audio permission result: $status');
        }

        if (status.isPermanentlyDenied) {
          if (context.mounted) {
            _showSettingsDialog(context);
          }
          return false;
        }

        return status.isGranted;

      } else if (sdkInt >= 30) {
        // Android 11-12 (API 30-32)
        var status = await Permission.storage.status;

        debugPrint('🔐 Storage permission status: $status');

        if (!status.isGranted) {
          debugPrint('🔐 Requesting storage permission...');
          status = await Permission.storage.request();
          debugPrint('🔐 Storage permission result: $status');
        }

        if (status.isPermanentlyDenied) {
          if (context.mounted) {
            _showSettingsDialog(context);
          }
          return false;
        }

        return status.isGranted;

      } else {
        // Android 10 va pastroq (API 29 va past)
        var status = await Permission.storage.status;

        debugPrint('🔐 Storage permission status: $status');

        if (!status.isGranted) {
          debugPrint('🔐 Requesting storage permission...');
          status = await Permission.storage.request();
          debugPrint('🔐 Storage permission result: $status');
        }

        if (status.isPermanentlyDenied) {
          if (context.mounted) {
            _showSettingsDialog(context);
          }
          return false;
        }

        return status.isGranted;
      }
    } catch (e) {
      debugPrint('❌ Permission check error: $e');
      return false;
    }
  }

  static void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text('Ruxsat kerak'),
          ],
        ),
        content: Text(
          'Audio fayllarni yuklab olish uchun storage ruxsati kerak.\n\nSozlamalar → Ilovalar → Sahhof → Ruxsatlar → Storage/Media',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Sozlamalarga o\'tish'),
          ),
        ],
      ),
    );
  }

  static Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt >= 33) {
        var status = await Permission.notification.status;

        if (!status.isGranted) {
          status = await Permission.notification.request();
        }

        return status.isGranted;
      }

      return true; // Android 13 dan past versiyalarda avtomatik granted
    } catch (e) {
      debugPrint('❌ Notification permission error: $e');
      return false;
    }
  }

  // Barcha kerakli ruxsatlarni bir vaqtda tekshirish
  static Future<bool> requestAllPermissions(BuildContext context) async {
    if (!Platform.isAndroid) {
      return true;
    }

    final storageGranted = await requestStoragePermission(context);
    final notificationGranted = await requestNotificationPermission();

    debugPrint('✅ Storage: $storageGranted, Notification: $notificationGranted');

    return storageGranted; // Storage asosiy
  }
}