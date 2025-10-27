import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sahhof/src/database/database_helper.dart';

class BackgroundDownloadService {
  static final BackgroundDownloadService _instance = BackgroundDownloadService._internal();
  factory BackgroundDownloadService() => _instance;
  BackgroundDownloadService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  ReceivePort _port = ReceivePort();

  // Download progress tracking
  final Map<String, double> _downloadProgress = {};
  final Map<int, String> _taskIds = {}; // bookId -> taskId

  // Initialize
  Future<void> initialize() async {
    // Initialize flutter_downloader
    await FlutterDownloader.initialize(
      debug: true,
      ignoreSsl: true,
    );

    // Initialize notifications for flutter_local_notifications: ^19.5.0
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );

    // Request notification permission for Android 13+
    await _requestNotificationPermission();

    // Register callback for flutter_downloader: ^1.12.0
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');

    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = DownloadTaskStatus.fromInt(data[1]);
      int progress = data[2];

      _downloadProgress[id] = progress / 100.0;

      // Update notification
      if (status == DownloadTaskStatus.running) {
        _updateNotification(id, progress);
      } else if (status == DownloadTaskStatus.complete) {
        _showCompletionNotification(id);
      } else if (status == DownloadTaskStatus.failed) {
        _showErrorNotification(id);
      }
    });

    // Register callback for flutter_downloader
    FlutterDownloader.registerCallback(downloadCallback, step: 1);
  }

  // Request notification permission (Android 13+)
  Future<void> _requestNotificationPermission() async {
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

  // Download book with background support
  Future<bool> downloadBookInBackground({
    required int bookId,
    required String title,
    required String format,
    required String description,
    required String coverImage,
    required int audioDuration,
    required String authorName,
    required List<Map<String, dynamic>> parts,
    Function(double)? onProgress,
  }) async {
    try {
      // Insert book to database first
      final dbBookId = await _dbHelper.insertBook(
        bookId: bookId,
        title: title,
        format: format,
        description: description,
        coverImage: coverImage,
        audioDuration: audioDuration,
        authorName: authorName,
        totalSize: parts.fold(0, (sum, p) => sum + ((p['size'] as int?) ?? 0)),
      );

      // Get download directory
      final directory = await _getDownloadDirectory();

      // Enqueue all parts
      List<String> taskIds = [];
      for (int i = 0; i < parts.length; i++) {
        final part = parts[i];

        final partDbId = await _dbHelper.insertAudioPart(
          bookId: dbBookId,
          partId: part['id'] ?? 0,
          name: part['name'] ?? 'Unknown',
          path: '',
          url: part['url'] ?? '',
          size: part['size'] ?? 0,
        );

        // Create safe filename
        final sanitizedName = _sanitizeFileName(part['name'] ?? 'audio_$i');
        final fileName = '${bookId}_part_${part['id']}_$sanitizedName.${part['format'] ?? 'mp3'}';

        // Enqueue download task
        final taskId = await FlutterDownloader.enqueue(
          url: part['url'] ?? '',
          savedDir: directory,
          fileName: fileName,
          showNotification: true,
          openFileFromNotification: false,
        );

        if (taskId != null) {
          taskIds.add(taskId);
        }
      }

      // Show initial notification
      await _showDownloadStartNotification(title, parts.length);

      return true;
    } catch (e) {
      print('Background download error: $e');
      return false;
    }
  }

  // Get download directory
  Future<String> _getDownloadDirectory() async {
    // Implementation depends on your setup
    return '/storage/emulated/0/Download/AudioBooks';
  }

  // Sanitize filename
  String _sanitizeFileName(String fileName) {
    String sanitized = fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');

    if (sanitized.length > 50) {
      sanitized = sanitized.substring(0, 50);
    }

    return sanitized;
  }

  // Show notifications for flutter_local_notifications: ^19.5.0
  Future<void> _showDownloadStartNotification(String title, int parts) async {
    const androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Downloads',
      channelDescription: 'Audio downloads',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: 0,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      'Yuklab olinmoqda',
      '$title ($parts ta fayl)',
      notificationDetails,
      payload: 'download_started',
    );
  }

  Future<void> _updateNotification(String taskId, int progress) async {
    final androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Downloads',
      channelDescription: 'Audio downloads',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: progress, // Set progress directly
      icon: '@mipmap/ic_launcher',
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      'Yuklab olinmoqda',
      '$progress%',
      notificationDetails,
      payload: 'download_progress',
    );
  }

  Future<void> _showCompletionNotification(String taskId) async {
    const androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Downloads',
      channelDescription: 'Audio downloads',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: DefaultStyleInformation(true, true),
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      'Yuklab olish tugadi!',
      'Audio muvaffaqiyatli yuklandi',
      notificationDetails,
      payload: 'download_completed',
    );
  }

  Future<void> _showErrorNotification(String taskId) async {
    const androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Downloads',
      channelDescription: 'Audio downloads',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: DefaultStyleInformation(true, true),
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      'Xatolik!',
      'Yuklab olishda muammo yuz berdi',
      notificationDetails,
      payload: 'download_failed',
    );
  }

  // Get download progress
  double getProgress(String taskId) {
    return _downloadProgress[taskId] ?? 0.0;
  }

  // Cancel download
  Future<void> cancelDownload(String taskId) async {
    await FlutterDownloader.cancel(taskId: taskId);
  }

  // Pause download
  Future<void> pauseDownload(String taskId) async {
    await FlutterDownloader.pause(taskId: taskId);
  }

  // Resume download
  Future<void> resumeDownload(String taskId) async {
    final newTaskId = await FlutterDownloader.resume(taskId: taskId);
    print('Resumed with new task ID: $newTaskId');
  }

  // Retry download
  Future<String?> retryDownload(String taskId) async {
    return await FlutterDownloader.retry(taskId: taskId);
  }

  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }
}