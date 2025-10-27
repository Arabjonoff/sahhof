// Downloaded Book Model
class DownloadedBookModel {
  final int id;
  final int bookId;
  final String title;
  final String format;
  final String description;
  final String coverImage;
  final int audioDuration;
  final String authorName;
  final int totalSize;
  final String downloadedAt;
  final int lastPlayedPosition;
  final String? lastPlayedAt;

  DownloadedBookModel({
    required this.id,
    required this.bookId,
    required this.title,
    required this.format,
    required this.description,
    required this.coverImage,
    required this.audioDuration,
    required this.authorName,
    required this.totalSize,
    required this.downloadedAt,
    this.lastPlayedPosition = 0,
    this.lastPlayedAt,
  });

  // From database
  factory DownloadedBookModel.fromMap(Map<String, dynamic> map) {
    return DownloadedBookModel(
      id: map['id'] ?? 0,
      bookId: map['book_id'] ?? 0,
      title: map['title'] ?? '',
      format: map['format'] ?? 'mp3',
      description: map['description'] ?? '',
      coverImage: map['cover_image'] ?? '',
      audioDuration: map['audio_duration'] ?? 0,
      authorName: map['author_name'] ?? '',
      totalSize: map['total_size'] ?? 0,
      downloadedAt: map['downloaded_at'] ?? '',
      lastPlayedPosition: map['last_played_position'] ?? 0,
      lastPlayedAt: map['last_played_at'],
    );
  }

  // To database
  Map<String, dynamic> toMap() {
    return {
      'book_id': bookId,
      'title': title,
      'format': format,
      'description': description,
      'cover_image': coverImage,
      'audio_duration': audioDuration,
      'author_name': authorName,
      'total_size': totalSize,
      'downloaded_at': downloadedAt,
      'last_played_position': lastPlayedPosition,
      'last_played_at': lastPlayedAt,
    };
  }

  // Copy with
  DownloadedBookModel copyWith({
    int? id,
    int? bookId,
    String? title,
    String? format,
    String? description,
    String? coverImage,
    int? audioDuration,
    String? authorName,
    int? totalSize,
    String? downloadedAt,
    int? lastPlayedPosition,
    String? lastPlayedAt,
  }) {
    return DownloadedBookModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      format: format ?? this.format,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      audioDuration: audioDuration ?? this.audioDuration,
      authorName: authorName ?? this.authorName,
      totalSize: totalSize ?? this.totalSize,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      lastPlayedPosition: lastPlayedPosition ?? this.lastPlayedPosition,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  // Format size
  String get formattedSize {
    if (totalSize < 1024) {
      return '$totalSize B';
    } else if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(2)} KB';
    } else if (totalSize < 1024 * 1024 * 1024) {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  // Format duration
  String get formattedDuration {
    if (audioDuration == 0) return '00:00';

    final hours = audioDuration ~/ 3600;
    final minutes = (audioDuration % 3600) ~/ 60;
    final seconds = audioDuration % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}

// Audio Part Model
class AudioPartModel {
  final int id;
  final int bookId;
  final int partId;
  final String name;
  final String path;
  final String url;
  final int size;
  final String downloadedAt;
  final int duration;

  AudioPartModel({
    required this.id,
    required this.bookId,
    required this.partId,
    required this.name,
    required this.path,
    required this.url,
    required this.size,
    required this.downloadedAt,
    this.duration = 0,
  });

  // From database
  factory AudioPartModel.fromMap(Map<String, dynamic> map) {
    return AudioPartModel(
      id: map['id'] ?? 0,
      bookId: map['book_id'] ?? 0,
      partId: map['part_id'] ?? 0,
      name: map['name'] ?? '',
      path: map['path'] ?? '',
      url: map['url'] ?? '',
      size: map['size'] ?? 0,
      downloadedAt: map['downloaded_at'] ?? '',
      duration: map['duration'] ?? 0,
    );
  }

  // To database
  Map<String, dynamic> toMap() {
    return {
      'book_id': bookId,
      'part_id': partId,
      'name': name,
      'path': path,
      'url': url,
      'size': size,
      'downloaded_at': downloadedAt,
      'duration': duration,
    };
  }

  // Format size
  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }
}