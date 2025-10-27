import 'dart:async';
import 'dart:isolate';

import 'package:sahhof/src/ui/main/detail/audio/auido_dowload.dart';

/// Simple background download manager
/// Bu service orqali user boshqa screenga o'tganda ham download davom etadi
class SimpleBackgroundDownloader {
  static final SimpleBackgroundDownloader _instance = SimpleBackgroundDownloader._internal();
  factory SimpleBackgroundDownloader() => _instance;
  SimpleBackgroundDownloader._internal();

  final AudioDownloadManager _downloadManager = AudioDownloadManager();

  // Active downloads tracking
  final Map<int, DownloadTask> _activeTasks = {};
  final StreamController<DownloadProgress> _progressController = StreamController.broadcast();

  // Get progress stream
  Stream<DownloadProgress> get progressStream => _progressController.stream;

  // Start download in background
  Future<bool> startDownload({
    required int bookId,
    required String title,
    required String format,
    required String description,
    required String coverImage,
    required int audioDuration,
    required String authorName,
    required List<Map<String, dynamic>> parts,
  }) async {
    // Check if already downloading
    if (_activeTasks.containsKey(bookId)) {
      print('Already downloading book $bookId');
      return false;
    }

    // Create task
    final task = DownloadTask(
      bookId: bookId,
      title: title,
      totalParts: parts.length,
    );
    _activeTasks[bookId] = task;

    // Start download
    final success = await _downloadManager.downloadBook(
      bookId: bookId,
      title: title,
      format: format,
      description: description,
      coverImage: coverImage,
      audioDuration: audioDuration,
      authorName: authorName,
      parts: parts,
      onTotalProgress: (progress) {
        task.progress = progress;

        // Emit progress
        _progressController.add(DownloadProgress(
          bookId: bookId,
          progress: progress,
          status: progress >= 1.0 ? DownloadStatus.completed : DownloadStatus.downloading,
        ));
      },
    );

    // Update task status
    if (success) {
      task.status = DownloadStatus.completed;
      _progressController.add(DownloadProgress(
        bookId: bookId,
        progress: 1.0,
        status: DownloadStatus.completed,
      ));
    } else {
      task.status = DownloadStatus.failed;
      _progressController.add(DownloadProgress(
        bookId: bookId,
        progress: task.progress,
        status: DownloadStatus.failed,
      ));
    }

    // Remove from active tasks after completion
    Future.delayed(Duration(seconds: 2), () {
      _activeTasks.remove(bookId);
    });

    return success;
  }

  // Check if downloading
  bool isDownloading(int bookId) {
    return _activeTasks.containsKey(bookId);
  }

  // Get download progress
  double? getProgress(int bookId) {
    return _activeTasks[bookId]?.progress;
  }

  // Get active downloads count
  int get activeDownloadsCount => _activeTasks.length;

  // Get all active downloads
  List<DownloadTask> get activeTasks => _activeTasks.values.toList();

  void dispose() {
    _progressController.close();
  }
}

/// Download task model
class DownloadTask {
  final int bookId;
  final String title;
  final int totalParts;
  double progress;
  DownloadStatus status;

  DownloadTask({
    required this.bookId,
    required this.title,
    required this.totalParts,
    this.progress = 0.0,
    this.status = DownloadStatus.downloading,
  });
}

/// Download progress event
class DownloadProgress {
  final int bookId;
  final double progress;
  final DownloadStatus status;

  DownloadProgress({
    required this.bookId,
    required this.progress,
    required this.status,
  });
}

/// Download status enum
enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}