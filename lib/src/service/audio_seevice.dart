import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sahhof/src/model/book/book_detail.dart';
import 'package:sahhof/src/service/audio_player_state.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  late AudioPlayer _audioPlayer;

  // RxDart Subjects
  final BehaviorSubject<BookDetailModel?> _currentBookSubject = BehaviorSubject<BookDetailModel?>.seeded(null);
  final BehaviorSubject<bool> _isPlayingSubject = BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<bool> _isLoadingSubject = BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<Duration> _durationSubject = BehaviorSubject<Duration>.seeded(Duration.zero);
  final BehaviorSubject<Duration> _positionSubject = BehaviorSubject<Duration>.seeded(Duration.zero);
  final BehaviorSubject<double> _playbackSpeedSubject = BehaviorSubject<double>.seeded(1.0);

  // Streams (getters)
  Stream<BookDetailModel?> get currentBookStream => _currentBookSubject.stream;
  Stream<bool> get isPlayingStream => _isPlayingSubject.stream;
  Stream<bool> get isLoadingStream => _isLoadingSubject.stream;
  Stream<Duration> get durationStream => _durationSubject.stream;
  Stream<Duration> get positionStream => _positionSubject.stream;
  Stream<double> get playbackSpeedStream => _playbackSpeedSubject.stream;

  // Combined streams
  Stream<bool> get hasAudioStream => _currentBookSubject.stream.map((book) => book != null);

  Stream<AudioPlayerState> get playerStateStream => Rx.combineLatest6(
    _currentBookSubject.stream,
    _isPlayingSubject.stream,
    _isLoadingSubject.stream,
    _durationSubject.stream,
    _positionSubject.stream,
    _playbackSpeedSubject.stream,
        (book, isPlaying, isLoading, duration, position, speed) => AudioPlayerState(
      currentBook: book,
      isPlaying: isPlaying,
      isLoading: isLoading,
      duration: duration,
      position: position,
      playbackSpeed: speed,
    ),
  );

  // Current values (getters)
  BookDetailModel? get currentBook => _currentBookSubject.value;
  bool get isPlaying => _isPlayingSubject.value;
  bool get isLoading => _isLoadingSubject.value;
  Duration get duration => _durationSubject.value;
  Duration get position => _positionSubject.value;
  double get playbackSpeed => _playbackSpeedSubject.value;
  bool get hasAudio => _currentBookSubject.value != null;

  void initialize() {
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    // Audio duration stream
    _audioPlayer.durationStream.listen((duration) {
      _durationSubject.add(duration ?? Duration.zero);
    });

    // Audio position stream
    _audioPlayer.positionStream.listen((position) {
      _positionSubject.add(position);
    });

    // Audio player state stream
    _audioPlayer.playerStateStream.listen((state) {
      _isPlayingSubject.add(state.playing);
      _isLoadingSubject.add(state.processingState == ProcessingState.loading);
    });
  }

  Future<void> setAudio(BookDetailModel book) async {
    try {
      _isLoadingSubject.add(true);
      _currentBookSubject.add(book);

      await _audioPlayer.setUrl(book.contents[0].files[0].file);

      _isLoadingSubject.add(false);
    } catch (e) {
      _isLoadingSubject.add(false);
      throw e;
    }
  }

  Future<void> togglePlayPause() async {
    try {
      if (_isPlayingSubject.value) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> seekToPosition(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> setSpeed(double speed) async {
    _playbackSpeedSubject.add(speed);
    await _audioPlayer.setSpeed(speed);
  }

  Future<void> skipForward() async {
    final newPosition = _positionSubject.value + Duration(seconds: 10);
    if (newPosition < _durationSubject.value) {
      await _audioPlayer.seek(newPosition);
    } else {
      await _audioPlayer.seek(_durationSubject.value);
    }
  }

  Future<void> skipBackward() async {
    final newPosition = _positionSubject.value - Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      await _audioPlayer.seek(newPosition);
    } else {
      await _audioPlayer.seek(Duration.zero);
    }
  }

  void dispose() {
    _currentBookSubject.close();
    _isPlayingSubject.close();
    _isLoadingSubject.close();
    _durationSubject.close();
    _positionSubject.close();
    _playbackSpeedSubject.close();
    _audioPlayer.dispose();
  }
}