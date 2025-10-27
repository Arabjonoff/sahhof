import 'package:sahhof/src/model/book/book_detail.dart';

class AudioPlayerState {
  final BookDetailModel? currentBook;
  final bool isPlaying;
  final bool isLoading;
  final Duration duration;
  final Duration position;
  final double playbackSpeed;

  AudioPlayerState({
    this.currentBook,
    required this.isPlaying,
    required this.isLoading,
    required this.duration,
    required this.position,
    required this.playbackSpeed,
  });

  bool get hasAudio => currentBook != null;

  double get progress => duration.inSeconds > 0
      ? position.inSeconds / duration.inSeconds
      : 0.0;

  // Qolgan vaqtni hisoblash
  Duration get remainingTime => duration - position;

  // Foiz bo'yicha progress
  double get progressPercentage => progress * 100;

  // Audio tugasi bormi?
  bool get isCompleted => position >= duration && duration > Duration.zero;

  // Formatted vaqt stringi
  String get formattedPosition => _formatDuration(position);

  String get formattedDuration => _formatDuration(duration);

  String get formattedRemainingTime => _formatDuration(remainingTime);

  // Vaqtni string formatda ko'rsatish (MM:SS)
  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // State'ni copy qilish
  AudioPlayerState copyWith({
    BookDetailModel? currentBook,
    bool? isPlaying,
    bool? isLoading,
    Duration? duration,
    Duration? position,
    double? playbackSpeed,
  }) {
    return AudioPlayerState(
      currentBook: currentBook ?? this.currentBook,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    );
  }

  @override
  String toString() => '''
    AudioPlayerState(
      book: ${currentBook?.title ?? 'None'},
      isPlaying: $isPlaying,
      isLoading: $isLoading,
      position: $formattedPosition / $formattedDuration,
      speed: ${playbackSpeed}x,
      progress: ${progressPercentage.toStringAsFixed(1)}%
    )
  ''';
}