import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sahhof/src/database/database_helper.dart';

class AudioDownloadManager {
  static final AudioDownloadManager _instance = AudioDownloadManager._internal();
  factory AudioDownloadManager() => _instance;
  AudioDownloadManager._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Download progress callbacks
  final Map<int, Function(double)> _progressCallbacks = {};
  final Map<int, bool> _cancelFlags = {};

  // Request storage permission
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) {
        return true;
      }

      // Android 13+ dan boshlab MANAGE_EXTERNAL_STORAGE kerak bo'lishi mumkin
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }

      return false;
    }
    return true; // iOS uchun ruxsat kerak emas
  }

  // Get download directory
  Future<Directory> getDownloadDirectory() async {
    Directory? directory;

    if (Platform.isAndroid) {
      // Android uchun app-specific storage
      directory = await getExternalStorageDirectory();
    } else {
      // iOS uchun
      directory = await getApplicationDocumentsDirectory();
    }

    final audioDir = Directory('${directory!.path}/AudioBooks');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    return audioDir;
  }

  // Download single audio file
  Future<String?> downloadAudioFile({
    required String url,
    required String fileName,
    required int partId,
    Function(double)? onProgress,
  }) async {
    try {
      // Validate URL
      if (url.isEmpty) {
        throw Exception('Invalid URL');
      }

      // Validate filename
      if (fileName.isEmpty) {
        throw Exception('Invalid filename');
      }

      final directory = await getDownloadDirectory();
      final filePath = '${directory.path}/$fileName';

      print('Downloading from: $url');
      print('Saving to: $filePath');

      // Initialize cancel flag
      _cancelFlags[partId] = false;

      // Create HTTP client
      final client = http.Client();

      try {
        // Send GET request
        final request = http.Request('GET', Uri.parse(url));
        final response = await client.send(request);

        print('Response status: ${response.statusCode}');

        if (response.statusCode != 200) {
          throw Exception('Failed to download: ${response.statusCode}');
        }

        // Get total file size
        final contentLength = response.contentLength ?? 0;
        print('Content length: $contentLength bytes');

        if (contentLength == 0) {
          print('Warning: Content length is 0');
        }

        // Create file
        final file = File(filePath);
        final sink = file.openWrite();

        int downloaded = 0;

        // Download with progress
        await for (var chunk in response.stream) {
          // Check if cancelled
          if (_cancelFlags[partId] == true) {
            print('Download cancelled for part $partId');
            await sink.close();
            client.close();

            // Delete partial file
            if (await file.exists()) {
              await file.delete();
            }

            return null;
          }

          // Write chunk to file
          sink.add(chunk);
          downloaded += chunk.length;

          // Calculate and report progress
          if (contentLength > 0) {
            final progress = downloaded / contentLength;
            onProgress?.call(progress);
            _progressCallbacks[partId]?.call(progress);
          } else {
            // If content length is unknown, just report activity
            onProgress?.call(0.5);
          }
        }

        await sink.close();
        client.close();

        print('Download completed: $filePath');
        print('Downloaded size: $downloaded bytes');

        // Verify file exists
        if (!await file.exists()) {
          throw Exception('Downloaded file does not exist');
        }

        // Remove cancel flag after download
        _cancelFlags.remove(partId);

        return filePath;
      } catch (e) {
        print('HTTP error: $e');
        client.close();
        throw e;
      }
    } catch (e) {
      print('Download error: $e');
      _cancelFlags.remove(partId);
      return null;
    }
  }

  // Download entire book
  Future<bool> downloadBook({
    required int bookId,
    required String title,
    required String format,
    required String description,
    required String coverImage,
    required int audioDuration,
    required String authorName,
    required List<Map<String, dynamic>> parts, // {id, name, url, size, format}
    Function(double)? onTotalProgress,
  }) async {
    try {
      // Check permission
      if (!await requestStoragePermission()) {
        throw Exception('Storage permission denied');
      }

      // Validate parts
      if (parts.isEmpty) {
        throw Exception('No parts to download');
      }

      // Calculate total size
      int totalSize = 0;
      for (var part in parts) {
        totalSize += (part['size'] as int?) ?? 0;
      }

      // Check if already downloaded
      if (await _dbHelper.isBookDownloaded(bookId)) {
        print('Book already downloaded');
        return false;
      }

      // Insert book to database
      final dbBookId = await _dbHelper.insertBook(
        bookId: bookId,
        title: title,
        format: format,
        description: description,
        coverImage: coverImage,
        audioDuration: audioDuration,
        authorName: authorName,
        totalSize: totalSize,
      );

      print('Book inserted with DB ID: $dbBookId');

      // Download each part
      int downloadedParts = 0;
      for (int i = 0; i < parts.length; i++) {
        final part = parts[i];

        try {
          // Generate safe filename
          final partName = part['name']?.toString() ?? 'audio_$i';
          final sanitizedName = _sanitizeFileName(partName);
          final partFormat = part['format']?.toString() ?? 'mp3';
          final partId = part['id']?.toString() ?? i.toString();
          final fileName = '${bookId}_part_${partId}_$sanitizedName.$partFormat';

          print('Downloading part ${i + 1}/${parts.length}: $fileName');

          final localPath = await downloadAudioFile(
            url: part['url'] ?? '',
            fileName: fileName,
            partId: part['id'] ?? i,
            onProgress: (progress) async {
              try {
                // Calculate total book progress
                final totalProgress = (downloadedParts + progress) / parts.length;
                onTotalProgress?.call(totalProgress);
              } catch (e) {
                print('Progress update error: $e');
              }
            },
          );

          if (localPath != null && localPath.isNotEmpty) {
            // Insert audio part with downloaded path
            await _dbHelper.insertAudioPart(
              bookId: dbBookId,
              partId: part['id'] ?? i,
              name: part['name'] ?? 'Unknown',
              path: localPath,
              url: part['url'] ?? '',
              size: part['size'] ?? 0,
            );

            downloadedParts++;
            print('✅ Downloaded part $downloadedParts/${parts.length}');
          } else {
            throw Exception('Failed to download part: $partName');
          }
        } catch (e) {
          print('❌ Part download error: $e');
          throw Exception('Failed to download part ${i + 1}: $e');
        }
      }

      print('🎉 All parts downloaded successfully');
      return true;
    } catch (e) {
      print('❌ Book download error: $e');
      // Clean up on error
      try {
        await _dbHelper.deleteBook(bookId);
      } catch (cleanupError) {
        print('Cleanup error: $cleanupError');
      }
      return false;
    }
  }

  // Cancel download
  void cancelDownload(int partId) {
    _cancelFlags[partId] = true;
  }

  // Register progress callback
  void registerProgressCallback(int partId, Function(double) callback) {
    _progressCallbacks[partId] = callback;
  }

  // Unregister progress callback
  void unregisterProgressCallback(int partId) {
    _progressCallbacks.remove(partId);
  }

  // Delete downloaded book
  Future<bool> deleteDownloadedBook(int bookId) async {
    try {
      // Get all parts from database
      final parts = await _dbHelper.getAudioParts(bookId);

      print('Deleting book $bookId with ${parts.length} parts');

      // Delete files
      for (var part in parts) {
        if (part.path.isNotEmpty) {
          final file = File(part.path);
          if (await file.exists()) {
            await file.delete();
            print('✅ Deleted file: ${part.path}');
          } else {
            print('⚠️ File not found: ${part.path}');
          }
        }
      }

      // Delete from database
      final deleted = await _dbHelper.deleteBook(bookId);

      if (deleted) {
        print('✅ Book deleted from database');
      }

      return deleted;
    } catch (e) {
      print('❌ Delete error: $e');
      return false;
    }
  }

  // Check if book is downloaded
  Future<bool> isBookDownloaded(int bookId) async {
    return await _dbHelper.isBookDownloaded(bookId);
  }

  // Get download progress
  Future<double> getBookDownloadProgress(int bookId) async {
    return await _dbHelper.getDownloadProgress(bookId);
  }

  // Get local file paths
  Future<List<String>> getBookLocalPaths(int bookId) async {
    final parts = await _dbHelper.getAudioParts(bookId);
    return parts
        .where((part) => part.path.isNotEmpty)
        .map((part) => part.path)
        .toList();
  }

  // Get downloaded books
  Future<List<Map<String, dynamic>>> getDownloadedBooks() async {
    final books = await _dbHelper.getAllDownloadedBooks();
    return books
        .map((book) => {
      'id': book.id,
      'book_id': book.bookId,
      'title': book.title,
      'author_name': book.authorName,
      'cover_image': book.coverImage,
      'total_size': book.totalSize,
      'audio_duration': book.audioDuration,
      'downloaded_at': book.downloadedAt,
      'formatted_size': book.formattedSize,
      'formatted_duration': book.formattedDuration,
      'last_played_position': book.lastPlayedPosition,
      'last_played_at': book.lastPlayedAt,
    })
        .toList();
  }

  // Get total downloaded size
  Future<String> getTotalDownloadedSize() async {
    final bytes = await _dbHelper.getTotalDownloadedSize();
    return _formatBytes(bytes);
  }

  // Get book details
  Future<Map<String, dynamic>?> getBookDetails(int bookId) async {
    final book = await _dbHelper.getDownloadedBook(bookId);
    if (book == null) return null;

    return {
      'id': book.id,
      'book_id': book.bookId,
      'title': book.title,
      'author_name': book.authorName,
      'cover_image': book.coverImage,
      'total_size': book.totalSize,
      'audio_duration': book.audioDuration,
      'downloaded_at': book.downloadedAt,
      'formatted_size': book.formattedSize,
      'formatted_duration': book.formattedDuration,
      'last_played_position': book.lastPlayedPosition,
      'last_played_at': book.lastPlayedAt,
    };
  }

  // Update playback position
  Future<void> updatePlaybackPosition(int bookId, int position) async {
    await _dbHelper.updateLastPlayedPosition(bookId, position);
  }

  // Search downloaded books
  Future<List<Map<String, dynamic>>> searchBooks(String query) async {
    final books = await _dbHelper.searchDownloadedBooks(query);
    return books
        .map((book) => {
      'id': book.id,
      'book_id': book.bookId,
      'title': book.title,
      'author_name': book.authorName,
      'cover_image': book.coverImage,
      'formatted_size': book.formattedSize,
      'formatted_duration': book.formattedDuration,
    })
        .toList();
  }

  // Get recently played books
  Future<List<Map<String, dynamic>>> getRecentlyPlayed({int limit = 10}) async {
    final books = await _dbHelper.getRecentlyPlayedBooks(limit: limit);
    return books
        .map((book) => {
      'id': book.id,
      'book_id': book.bookId,
      'title': book.title,
      'author_name': book.authorName,
      'cover_image': book.coverImage,
      'last_played_position': book.lastPlayedPosition,
      'last_played_at': book.lastPlayedAt,
    })
        .toList();
  }

  // Sanitize filename
  String _sanitizeFileName(String fileName) {
    // Remove invalid characters and replace spaces
    String sanitized = fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');

    // Limit length to 50 characters
    if (sanitized.length > 50) {
      sanitized = sanitized.substring(0, 50);
    }

    return sanitized;
  }

  // Format bytes to human readable
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Format file size
  String formatFileSize(int bytes) {
    return _formatBytes(bytes);
  }

  // Clear all downloads
  Future<void> clearAllDownloads() async {
    try {
      // Get all books
      final books = await _dbHelper.getAllDownloadedBooks();

      // Delete all files
      for (var book in books) {
        final parts = await _dbHelper.getAudioParts(book.bookId);
        for (var part in parts) {
          if (part.path.isNotEmpty) {
            final file = File(part.path);
            if (await file.exists()) {
              await file.delete();
            }
          }
        }
      }

      // Clear database
      await _dbHelper.clearAllDownloads();

      print('✅ All downloads cleared');
    } catch (e) {
      print('❌ Clear all error: $e');
    }
  }

  // Get storage info
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final directory = await getDownloadDirectory();
      final totalBytes = await _dbHelper.getTotalDownloadedSize();
      final booksCount = await _dbHelper.getDownloadedBooksCount();

      return {
        'total_size': totalBytes,
        'formatted_size': _formatBytes(totalBytes),
        'books_count': booksCount,
        'storage_path': directory.path,
      };
    } catch (e) {
      print('Storage info error: $e');
      return {
        'total_size': 0,
        'formatted_size': '0 B',
        'books_count': 0,
        'storage_path': '',
      };
    }
  }
}